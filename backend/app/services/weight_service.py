"""Service for logging and querying weight tracking history."""

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

    async def create_log(self, user: User, payload: WeightLogCreate) -> WeightLog:
        logged_at = payload.logged_at or datetime.now(UTC)
        if logged_at.tzinfo is None:
            logged_at = logged_at.replace(tzinfo=UTC)

        log = WeightLog(
            user_id=user.id,
            weight_kg=payload.weight_kg,
            logged_at=logged_at,
            note=payload.note,
        )
        self.db.add(log)

        # Update user profile current weight if profile exists
        prof_res = await self.db.execute(select(UserProfile).where(UserProfile.user_id == user.id))
        profile = prof_res.scalar_one_or_none()
        if profile:
            profile.weight_kg = payload.weight_kg

        await self.db.commit()
        await self.db.refresh(log)
        return log

    async def get_history(
        self, user: User, days: int = 30, tz_offset: int = 0
    ) -> WeightHistoryResponse:
        client_now = datetime.now(UTC) + timedelta(minutes=tz_offset)
        today = client_now.date()
        start_date = today - timedelta(days=days - 1)

        start_dt = datetime.combine(start_date, time.min).replace(tzinfo=UTC) - timedelta(
            minutes=tz_offset
        )
        end_dt = datetime.combine(today, time.max).replace(tzinfo=UTC) - timedelta(minutes=tz_offset)

        # Query weight logs
        logs_res = await self.db.execute(
            select(WeightLog)
            .where(
                WeightLog.user_id == user.id,
                WeightLog.logged_at >= start_dt,
                WeightLog.logged_at <= end_dt,
            )
            .order_by(WeightLog.logged_at.asc())
        )
        logs = list(logs_res.scalars().all())

        # Query daily calorie intake for overlay
        meals_res = await self.db.execute(
            select(Meal).where(
                Meal.user_id == user.id,
                Meal.created_at >= start_dt,
                Meal.created_at <= end_dt,
            )
        )
        meals = list(meals_res.scalars().all())

        calories_by_date: dict[str, float] = {}
        for m in meals:
            m_local = m.created_at + timedelta(minutes=tz_offset)
            d_str = m_local.date().isoformat()
            calories_by_date[d_str] = calories_by_date.get(d_str, 0.0) + m.total_calories

        # Map weight by date (last log of each day)
        weight_by_date: dict[str, float] = {}
        for l in logs:
            l_local = l.logged_at + timedelta(minutes=tz_offset)
            d_str = l_local.date().isoformat()
            weight_by_date[d_str] = l.weight_kg

        points: list[WeightHistoryPoint] = []
        for d_str, w_kg in weight_by_date.items():
            points.append(
                WeightHistoryPoint(
                    date=d_str,
                    weight_kg=round(w_kg, 2),
                    calories_consumed=round(calories_by_date.get(d_str, 0.0), 1)
                    if d_str in calories_by_date
                    else None,
                )
            )
        points.sort(key=lambda p: p.date)

        current_weight = logs[-1].weight_kg if logs else None
        start_weight = logs[0].weight_kg if logs else None
        change_total = round(current_weight - start_weight, 2) if (current_weight is not None and start_weight is not None) else None

        # 7-day change
        seven_days_ago = today - timedelta(days=7)
        logs_7d = [l for l in logs if (l.logged_at + timedelta(minutes=tz_offset)).date() >= seven_days_ago]
        change_7d = round(current_weight - logs_7d[0].weight_kg, 2) if (current_weight is not None and logs_7d) else None

        return WeightHistoryResponse(
            points=points,
            current_weight=current_weight,
            start_weight=start_weight,
            change_total_kg=change_total,
            change_7d_kg=change_7d,
            days=days,
        )

    async def delete_log(self, user: User, log_id: uuid.UUID) -> bool:
        res = await self.db.execute(
            select(WeightLog).where(WeightLog.id == log_id, WeightLog.user_id == user.id)
        )
        log = res.scalar_one_or_none()
        if log is None:
            return False
        await self.db.delete(log)
        await self.db.commit()
        return True
