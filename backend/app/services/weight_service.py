"""Service for body weight tracking, history analytics, and profile synchronization."""

import uuid
from datetime import UTC, datetime, time, timedelta

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.meal import Meal
from app.models.user import User
from app.models.user_profile import UserProfile
from app.models.weight_log import WeightLog
from app.schemas.weight import (
    WeightHistoryPoint,
    WeightHistoryResponse,
    WeightLogCreate,
)


class WeightService:
    def __init__(self, db: AsyncSession) -> None:
        self.db = db

    async def create_log(self, user: User, data: WeightLogCreate) -> WeightLog:
        """Create a new weight log and synchronize with the user's biometric profile."""
        logged_at = data.logged_at or datetime.now(UTC)

        log = WeightLog(
            user_id=user.id,
            weight_kg=round(data.weight_kg, 2),
            logged_at=logged_at,
            note=data.note,
        )
        self.db.add(log)

        # Update latest weight on UserProfile if profile exists
        prof_res = await self.db.execute(
            select(UserProfile).where(UserProfile.user_id == user.id)
        )
        profile = prof_res.scalar_one_or_none()
        if profile is not None:
            profile.weight_kg = round(data.weight_kg, 2)

        await self.db.commit()
        await self.db.refresh(log)
        return log

    async def get_history(
        self, user: User, days: int = 30, tz_offset: int = 0
    ) -> WeightHistoryResponse:
        """Fetch weight history points and daily calorie correlation over `days` period."""
        client_now = datetime.now(UTC) + timedelta(minutes=tz_offset)
        today = client_now.date()
        cutoff_date = today - timedelta(days=days - 1)

        cutoff_dt = datetime.combine(cutoff_date, time.min).replace(tzinfo=UTC) - timedelta(
            minutes=tz_offset
        )

        # 1. Fetch weight logs within range
        query = (
            select(WeightLog)
            .where(WeightLog.user_id == user.id, WeightLog.logged_at >= cutoff_dt)
            .order_by(WeightLog.logged_at.asc())
        )
        res = await self.db.execute(query)
        logs = list(res.scalars().all())

        # 2. Fetch meals within range for calories overlay
        meal_query = select(Meal).where(
            Meal.user_id == user.id, Meal.created_at >= cutoff_dt
        )
        meal_res = await self.db.execute(meal_query)
        meals = list(meal_res.scalars().all())

        # Aggregate calories by client date
        daily_calories: dict[str, float] = {}
        for m in meals:
            m_client_date = (m.created_at + timedelta(minutes=tz_offset)).date().isoformat()
            daily_calories[m_client_date] = round(
                daily_calories.get(m_client_date, 0.0) + m.total_calories, 1
            )

        # Group weight by client date (last logged weight of the day)
        daily_weights: dict[str, float] = {}
        for w in logs:
            w_client_date = (w.logged_at + timedelta(minutes=tz_offset)).date().isoformat()
            daily_weights[w_client_date] = w.weight_kg

        # Generate continuous data points for the requested days
        points: list[WeightHistoryPoint] = []
        last_known_weight: float | None = None

        # Check if there is an earlier weight before cutoff
        if not daily_weights:
            prev_query = (
                select(WeightLog)
                .where(WeightLog.user_id == user.id)
                .order_by(WeightLog.logged_at.desc())
                .limit(1)
            )
            prev_res = await self.db.execute(prev_query)
            prev_log = prev_res.scalar_one_or_none()
            if prev_log:
                last_known_weight = prev_log.weight_kg

        for i in range(days):
            current_date = cutoff_date + timedelta(days=i)
            date_str = current_date.isoformat()

            if date_str in daily_weights:
                last_known_weight = daily_weights[date_str]

            if last_known_weight is not None:
                points.append(
                    WeightHistoryPoint(
                        date=date_str,
                        weight_kg=last_known_weight,
                        calories_consumed=daily_calories.get(date_str, 0.0),
                    )
                )

        # Calculate statistics
        # All-time earliest weight
        first_query = (
            select(WeightLog)
            .where(WeightLog.user_id == user.id)
            .order_by(WeightLog.logged_at.asc())
            .limit(1)
        )
        first_res = await self.db.execute(first_query)
        first_log = first_res.scalar_one_or_none()
        start_weight = first_log.weight_kg if first_log else None

        # All-time latest weight
        latest_query = (
            select(WeightLog)
            .where(WeightLog.user_id == user.id)
            .order_by(WeightLog.logged_at.desc())
            .limit(1)
        )
        latest_res = await self.db.execute(latest_query)
        latest_log = latest_res.scalar_one_or_none()
        current_weight = latest_log.weight_kg if latest_log else None

        change_total = (
            round(current_weight - start_weight, 2)
            if current_weight is not None and start_weight is not None
            else None
        )

        # Weight ~7 days ago
        change_7d: float | None = None
        if current_weight is not None:
            seven_days_ago_dt = datetime.now(UTC) - timedelta(days=7)
            seven_d_query = (
                select(WeightLog)
                .where(WeightLog.user_id == user.id, WeightLog.logged_at <= seven_days_ago_dt)
                .order_by(WeightLog.logged_at.desc())
                .limit(1)
            )
            seven_d_res = await self.db.execute(seven_d_query)
            seven_d_log = seven_d_res.scalar_one_or_none()
            if seven_d_log:
                change_7d = round(current_weight - seven_d_log.weight_kg, 2)

        return WeightHistoryResponse(
            points=points,
            current_weight=current_weight,
            start_weight=start_weight,
            change_total_kg=change_total,
            change_7d_kg=change_7d,
            days=days,
        )

    async def delete_log(self, user: User, log_id: uuid.UUID) -> bool:
        """Delete a weight log belonging to the user and re-sync profile weight."""
        query = select(WeightLog).where(WeightLog.id == log_id, WeightLog.user_id == user.id)
        res = await self.db.execute(query)
        log = res.scalar_one_or_none()
        if log is None:
            return False

        await self.db.delete(log)

        # Update profile weight with newest remaining weight log
        latest_query = (
            select(WeightLog)
            .where(WeightLog.user_id == user.id)
            .order_by(WeightLog.logged_at.desc())
            .limit(1)
        )
        latest_res = await self.db.execute(latest_query)
        new_latest = latest_res.scalar_one_or_none()

        prof_res = await self.db.execute(
            select(UserProfile).where(UserProfile.user_id == user.id)
        )
        profile = prof_res.scalar_one_or_none()
        if profile is not None:
            if new_latest:
                profile.weight_kg = new_latest.weight_kg

        await self.db.commit()
        return True
