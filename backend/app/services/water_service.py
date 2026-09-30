"""Service for managing water intake logs and daily hydration analytics."""

import uuid
from datetime import UTC, date, datetime, time

from sqlalchemy import delete, desc, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.goal import Goal
from app.models.water_log import WaterLog
from app.schemas.water import (
    DailyWaterSummary,
    WaterHistoryDay,
    WaterLogCreate,
    WaterLogRead,
)


class WaterService:
    def __init__(self, db: AsyncSession) -> None:
        self.db = db

    async def _get_user_water_target(self, user_id: uuid.UUID) -> float:
        result = await self.db.execute(select(Goal).where(Goal.user_id == user_id))
        goal = result.scalar_one_or_none()
        if goal and goal.water_target_ml > 0:
            return goal.water_target_ml
        return 2500.0

    async def log_water(self, user_id: uuid.UUID, payload: WaterLogCreate) -> DailyWaterSummary:
        logged_at = payload.logged_at or datetime.now(UTC)
        water_log = WaterLog(
            user_id=user_id,
            amount_ml=payload.amount_ml,
            logged_at=logged_at,
        )
        self.db.add(water_log)
        await self.db.commit()
        return await self.get_daily_summary(user_id=user_id, target_date=logged_at.date())

    async def get_daily_summary(
        self, user_id: uuid.UUID, target_date: date | None = None
    ) -> DailyWaterSummary:
        day = target_date or datetime.now(UTC).date()
        start_dt = datetime.combine(day, time.min).replace(tzinfo=UTC)
        end_dt = datetime.combine(day, time.max).replace(tzinfo=UTC)

        target_ml = await self._get_user_water_target(user_id)

        result = await self.db.execute(
            select(WaterLog)
            .where(
                WaterLog.user_id == user_id,
                WaterLog.logged_at >= start_dt,
                WaterLog.logged_at <= end_dt,
            )
            .order_by(desc(WaterLog.logged_at))
        )
        logs = list(result.scalars().all())

        total_ml = sum(log_item.amount_ml for log_item in logs)
        percentage = round((total_ml / target_ml * 100.0), 1) if target_ml > 0 else 0.0

        return DailyWaterSummary(
            date=day.isoformat(),
            total_ml=round(total_ml, 1),
            target_ml=round(target_ml, 1),
            percentage=percentage,
            logs_count=len(logs),
            logs=[WaterLogRead.model_validate(log_item) for log_item in logs],
        )

    async def get_history(self, user_id: uuid.UUID, days: int = 7) -> list[WaterHistoryDay]:
        days = max(1, min(days, 30))
        today = datetime.now(UTC).date()
        target_ml = await self._get_user_water_target(user_id)

        from datetime import timedelta

        start_date = today - timedelta(days=days - 1)
        start_dt = datetime.combine(start_date, time.min).replace(tzinfo=UTC)

        result = await self.db.execute(
            select(WaterLog)
            .where(
                WaterLog.user_id == user_id,
                WaterLog.logged_at >= start_dt,
            )
            .order_by(WaterLog.logged_at.asc())
        )
        logs = list(result.scalars().all())

        # Group by day
        day_totals: dict[str, list[float]] = {}
        for i in range(days):
            d = (start_date + timedelta(days=i)).isoformat()
            day_totals[d] = []

        for log in logs:
            d_str = log.logged_at.date().isoformat()
            if d_str in day_totals:
                day_totals[d_str].append(log.amount_ml)

        history: list[WaterHistoryDay] = []
        for d_str, amounts in sorted(day_totals.items()):
            tot = sum(amounts)
            pct = round((tot / target_ml * 100.0), 1) if target_ml > 0 else 0.0
            history.append(
                WaterHistoryDay(
                    date=d_str,
                    total_ml=round(tot, 1),
                    target_ml=round(target_ml, 1),
                    percentage=pct,
                    logs_count=len(amounts),
                )
            )

        return history

    async def delete_log(self, user_id: uuid.UUID, log_id: uuid.UUID) -> bool:
        result = await self.db.execute(
            delete(WaterLog).where(
                WaterLog.id == log_id,
                WaterLog.user_id == user_id,
            )
        )
        await self.db.commit()
        return result.rowcount > 0

    async def update_water_goal(self, user_id: uuid.UUID, water_target_ml: float) -> Goal:
        result = await self.db.execute(select(Goal).where(Goal.user_id == user_id))
        goal = result.scalar_one_or_none()
        if not goal:
            goal = Goal(user_id=user_id, water_target_ml=water_target_ml)
            self.db.add(goal)
        else:
            goal.water_target_ml = water_target_ml
        await self.db.commit()
        await self.db.refresh(goal)
        return goal
