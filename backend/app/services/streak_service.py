"""Service for calculating daily nutrition score, streaks, and derived badges."""

import uuid
from datetime import UTC, date, datetime, time, timedelta

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.goal import Goal
from app.models.meal import Meal
from app.models.water_log import WaterLog
from app.schemas.streak import (
    BadgeItem,
    DailyScoreBreakdown,
    DailyScoreRead,
    EarnedBadgeId,
    ScoreBreakdownItem,
    StreaksResponse,
)


def calculate_daily_score(
    calories: float,
    protein: float,
    fiber: float,
    water_ml: float,
    calorie_target: float = 2000.0,
    protein_target: float = 120.0,
    fiber_target: float = 30.0,
    water_target_ml: float = 2500.0,
) -> tuple[int, DailyScoreBreakdown]:
    """Calculate daily score (0-100) based on calorie, protein, fiber, and water targets.

    Rules:
    - 40 pts calories (within ±10% of target: 0.90 * target <= calories <= 1.10 * target)
    - 30 pts protein (>= 90% of target: protein >= 0.90 * target)
    - 15 pts fiber (>= 80% of target: fiber >= 0.80 * target)
    - 15 pts water (>= 100% of target: water >= 1.00 * target)
    """
    cal_target = calorie_target if calorie_target > 0 else 2000.0
    prot_target = protein_target if protein_target > 0 else 120.0
    fib_target = fiber_target if fiber_target > 0 else 30.0
    wat_target = water_target_ml if water_target_ml > 0 else 2500.0

    cal_min = round(0.90 * cal_target, 2)
    cal_max = round(1.10 * cal_target, 2)
    cal_achieved = (cal_min <= calories <= cal_max) and calories > 0
    cal_points = 40.0 if cal_achieved else 0.0

    prot_min = round(0.90 * prot_target, 2)
    prot_achieved = (protein >= prot_min) and protein > 0
    prot_points = 30.0 if prot_achieved else 0.0

    fib_min = round(0.80 * fib_target, 2)
    fib_achieved = (fiber >= fib_min) and fiber > 0
    fib_points = 15.0 if fib_achieved else 0.0

    wat_min = round(1.00 * wat_target, 2)
    wat_achieved = (water_ml >= wat_min) and water_ml > 0
    wat_points = 15.0 if wat_achieved else 0.0

    total_score = int(round(cal_points + prot_points + fib_points + wat_points))

    breakdown = DailyScoreBreakdown(
        calories=ScoreBreakdownItem(
            points=cal_points,
            max_points=40.0,
            achieved=cal_achieved,
            value=round(calories, 1),
            target=round(cal_target, 1),
            description=f"Within ±10% of {cal_target:.0f} kcal ({cal_min:.0f}–{cal_max:.0f} kcal)",
        ),
        protein=ScoreBreakdownItem(
            points=prot_points,
            max_points=30.0,
            achieved=prot_achieved,
            value=round(protein, 1),
            target=round(prot_target, 1),
            description=f"At least 90% of {prot_target:.0f}g target ({prot_min:.1f}g)",
        ),
        fiber=ScoreBreakdownItem(
            points=fib_points,
            max_points=15.0,
            achieved=fib_achieved,
            value=round(fiber, 1),
            target=round(fib_target, 1),
            description=f"At least 80% of {fib_target:.0f}g target ({fib_min:.1f}g)",
        ),
        water=ScoreBreakdownItem(
            points=wat_points,
            max_points=15.0,
            achieved=wat_achieved,
            value=round(water_ml, 1),
            target=round(wat_target, 1),
            description=f"At least 100% of {wat_target:.0f}ml target ({wat_min:.0f}ml)",
        ),
    )

    return total_score, breakdown


class StreakService:
    def __init__(self, db: AsyncSession) -> None:
        self.db = db

    async def get_user_streaks_and_badges(
        self, user_id: uuid.UUID, tz_offset: int = 0
    ) -> StreaksResponse:
        client_now = datetime.now(UTC) + timedelta(minutes=tz_offset)
        today = client_now.date()
        yesterday = today - timedelta(days=1)

        # Get user goals
        goal_result = await self.db.execute(select(Goal).where(Goal.user_id == user_id))
        goal = goal_result.scalar_one_or_none()
        cal_target = goal.calorie_target if goal else 2000.0
        prot_target = goal.protein_target if goal else 120.0
        fib_target = goal.fiber_target if goal else 30.0
        wat_target = goal.water_target_ml if goal else 2500.0

        # End of today in UTC
        end_of_today_utc = datetime.combine(today, time.max).replace(tzinfo=UTC) - timedelta(
            minutes=tz_offset
        )

        # Query all meals up to today
        meal_result = await self.db.execute(
            select(Meal).where(
                Meal.user_id == user_id,
                Meal.created_at <= end_of_today_utc,
            )
        )
        meals = list(meal_result.scalars().all())

        # Query all water logs up to today
        water_result = await self.db.execute(
            select(WaterLog).where(
                WaterLog.user_id == user_id,
                WaterLog.logged_at <= end_of_today_utc,
            )
        )
        water_logs = list(water_result.scalars().all())

        # Group data by local date
        daily_data: dict[date, dict[str, float]] = {}

        for m in meals:
            local_dt = m.created_at + timedelta(minutes=tz_offset)
            m_date = local_dt.date()
            if m_date not in daily_data:
                daily_data[m_date] = {"calories": 0.0, "protein": 0.0, "fiber": 0.0, "water": 0.0}
            daily_data[m_date]["calories"] += m.total_calories
            daily_data[m_date]["protein"] += m.total_protein
            daily_data[m_date]["fiber"] += m.total_fiber

        for w in water_logs:
            local_dt = w.logged_at + timedelta(minutes=tz_offset)
            w_date = local_dt.date()
            if w_date not in daily_data:
                daily_data[w_date] = {"calories": 0.0, "protein": 0.0, "fiber": 0.0, "water": 0.0}
            daily_data[w_date]["water"] += w.amount_ml

        # Ensure today is present
        if today not in daily_data:
            daily_data[today] = {"calories": 0.0, "protein": 0.0, "fiber": 0.0, "water": 0.0}

        # Calculate scores by date
        scores_by_date: dict[date, int] = {}
        breakdowns_by_date: dict[date, DailyScoreBreakdown] = {}

        for d, vals in daily_data.items():
            sc, brk = calculate_daily_score(
                calories=vals["calories"],
                protein=vals["protein"],
                fiber=vals["fiber"],
                water_ml=vals["water"],
                calorie_target=cal_target,
                protein_target=prot_target,
                fiber_target=fib_target,
                water_target_ml=wat_target,
            )
            scores_by_date[d] = sc
            breakdowns_by_date[d] = brk

        today_score_val = scores_by_date[today]
        today_breakdown = breakdowns_by_date[today]
        today_score_read = DailyScoreRead(
            date=today.isoformat(),
            score=today_score_val,
            breakdown=today_breakdown,
        )

        # Determine all calendar dates from earliest recorded to today
        if daily_data:
            earliest_date = min(daily_data.keys())
        else:
            earliest_date = today

        # Walk through calendar dates in order to compute longest_streak and badge earn dates
        longest_streak = 0
        current_run = 0
        streak_3_earned_at: str | None = None
        streak_7_earned_at: str | None = None
        streak_14_earned_at: str | None = None
        streak_30_earned_at: str | None = None

        total_days = (today - earliest_date).days + 1
        for i in range(total_days):
            d = earliest_date + timedelta(days=i)
            sc = scores_by_date.get(d, 0)
            if sc >= 60:
                current_run += 1
                if current_run > longest_streak:
                    longest_streak = current_run
                if current_run == 3 and not streak_3_earned_at:
                    streak_3_earned_at = d.isoformat()
                if current_run == 7 and not streak_7_earned_at:
                    streak_7_earned_at = d.isoformat()
                if current_run == 14 and not streak_14_earned_at:
                    streak_14_earned_at = d.isoformat()
                if current_run == 30 and not streak_30_earned_at:
                    streak_30_earned_at = d.isoformat()
            else:
                current_run = 0

        # Calculate current_streak:
        # "count of consecutive days ending yesterday or today where score >= 60"
        current_streak = 0
        streak_active_today = today_score_val >= 60

        if streak_active_today:
            # Count backwards from today
            check_day = today
            while scores_by_date.get(check_day, 0) >= 60:
                current_streak += 1
                check_day -= timedelta(days=1)
        elif scores_by_date.get(yesterday, 0) >= 60:
            # Today not yet >= 60, but streak continues from yesterday
            check_day = yesterday
            while scores_by_date.get(check_day, 0) >= 60:
                current_streak += 1
                check_day -= timedelta(days=1)
        else:
            current_streak = 0

        # Badges evaluation
        today_protein = daily_data[today]["protein"]
        hit_protein_today = (today_protein >= round(0.90 * prot_target, 2)) and (today_protein > 0)

        badge_catalog = [
            BadgeItem(
                id="streak_3",
                name="3-Day Streak",
                description="Hit a 60+ health score for 3 consecutive days",
                icon="local_fire_department",
                unlocked=longest_streak >= 3,
                earned_at=streak_3_earned_at,
            ),
            BadgeItem(
                id="streak_7",
                name="7-Day Streak",
                description="Maintained balanced nutrition for a full week",
                icon="military_tech",
                unlocked=longest_streak >= 7,
                earned_at=streak_7_earned_at,
            ),
            BadgeItem(
                id="streak_14",
                name="14-Day Streak",
                description="Two weeks of sustained healthy habits",
                icon="workspace_premium",
                unlocked=longest_streak >= 14,
                earned_at=streak_14_earned_at,
            ),
            BadgeItem(
                id="streak_30",
                name="30-Day Streak",
                description="One month champion of mindful nutrition",
                icon="stars",
                unlocked=longest_streak >= 30,
                earned_at=streak_30_earned_at,
            ),
            BadgeItem(
                id="hit_protein_today",
                name="Protein Pro",
                description="Reached 90%+ of your daily protein target today",
                icon="fitness_center",
                unlocked=hit_protein_today,
                earned_at=today.isoformat() if hit_protein_today else None,
            ),
        ]

        earned_badge_ids = [
            EarnedBadgeId(id=b.id, earned_at=b.earned_at or today.isoformat())
            for b in badge_catalog
            if b.unlocked
        ]

        return StreaksResponse(
            current_streak=current_streak,
            longest_streak=longest_streak,
            today_score=today_score_read,
            streak_active_today=streak_active_today,
            earned_badges=earned_badge_ids,
            badges=badge_catalog,
        )
