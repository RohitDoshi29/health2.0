from datetime import UTC, date, datetime, time, timedelta

from fastapi import APIRouter, Depends, Query
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.core.database import get_db
from app.core.security import get_current_user
from app.models.goal import Goal
from app.models.meal import Meal
from app.models.user import User
from app.schemas.goal import (
    DailyAnalyticsRead,
    DailyTrendPoint,
    GoalRead,
    GoalUpdate,
    TrendsAnalyticsRead,
)
from app.schemas.streak import StreaksResponse
from app.schemas.weekly import WeeklyReportResponse
from app.services.streak_service import StreakService
from app.services.weekly_service import WeeklyService

router = APIRouter(tags=["goals & analytics"])


async def _get_or_create_user_goal(user: User, db: AsyncSession) -> Goal:
    result = await db.execute(select(Goal).where(Goal.user_id == user.id))
    goal = result.scalar_one_or_none()
    if goal is None:
        goal = Goal(
            user_id=user.id,
            calorie_target=2000.0,
            protein_target=120.0,
            carbohydrates_target=250.0,
            fat_target=65.0,
            fiber_target=30.0,
        )
        db.add(goal)
        await db.commit()
        await db.refresh(goal)
    return goal


@router.get("/users/me/goals", response_model=GoalRead)
async def get_my_goals(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> GoalRead:
    """Get the current user's daily nutrition targets (or default if unset)."""
    goal = await _get_or_create_user_goal(current_user, db)
    return GoalRead.model_validate(goal)


@router.put("/users/me/goals", response_model=GoalRead)
async def update_my_goals(
    payload: GoalUpdate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> GoalRead:
    """Update the current user's daily nutrition targets."""
    goal = await _get_or_create_user_goal(current_user, db)

    if payload.calorie_target is not None:
        goal.calorie_target = payload.calorie_target
    if payload.protein_target is not None:
        goal.protein_target = payload.protein_target
    if payload.carbohydrates_target is not None:
        goal.carbohydrates_target = payload.carbohydrates_target
    if payload.fat_target is not None:
        goal.fat_target = payload.fat_target
    if payload.fiber_target is not None:
        goal.fiber_target = payload.fiber_target

    await db.commit()
    await db.refresh(goal)
    return GoalRead.model_validate(goal)


@router.get("/analytics/daily", response_model=DailyAnalyticsRead)
async def get_daily_analytics(
    target_date: str | None = Query(
        default=None, alias="date", description="Target date in YYYY-MM-DD format"
    ),
    tz_offset: int = Query(
        default=0, description="Timezone offset in minutes from UTC (e.g. 330 for IST UTC+5:30)"
    ),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> DailyAnalyticsRead:
    """Calculate daily consumed nutrition vs. user goals for a specific date."""
    if target_date:
        parsed_date = date.fromisoformat(target_date)
    else:
        client_now = datetime.now(UTC) + timedelta(minutes=tz_offset)
        parsed_date = client_now.date()

    start_dt = datetime.combine(parsed_date, time.min).replace(tzinfo=UTC) - timedelta(
        minutes=tz_offset
    )
    end_dt = datetime.combine(parsed_date, time.max).replace(tzinfo=UTC) - timedelta(
        minutes=tz_offset
    )

    # Fetch meals for this user on this day
    query = (
        select(Meal)
        .where(
            Meal.user_id == current_user.id,
            Meal.created_at >= start_dt,
            Meal.created_at <= end_dt,
        )
        .options(selectinload(Meal.items))
    )
    result = await db.execute(query)
    meals = list(result.scalars().all())

    # Aggregate totals
    consumed_cals = round(sum(m.total_calories for m in meals), 2)
    consumed_prot = round(sum(m.total_protein for m in meals), 2)
    consumed_carbs = round(sum(m.total_carbohydrates for m in meals), 2)
    consumed_fat = round(sum(m.total_fat for m in meals), 2)
    consumed_fiber = round(sum(m.total_fiber for m in meals), 2)

    # Get user's goal
    goal = await _get_or_create_user_goal(current_user, db)

    cal_prog = round(consumed_cals / goal.calorie_target, 3) if goal.calorie_target > 0 else 0.0
    prot_prog = round(consumed_prot / goal.protein_target, 3) if goal.protein_target > 0 else 0.0
    carbs_prog = (
        round(consumed_carbs / goal.carbohydrates_target, 3)
        if goal.carbohydrates_target > 0
        else 0.0
    )
    fat_prog = round(consumed_fat / goal.fat_target, 3) if goal.fat_target > 0 else 0.0
    fiber_prog = round(consumed_fiber / goal.fiber_target, 3) if goal.fiber_target > 0 else 0.0

    return DailyAnalyticsRead(
        date=parsed_date.isoformat(),
        consumed_calories=consumed_cals,
        consumed_protein=consumed_prot,
        consumed_carbohydrates=consumed_carbs,
        consumed_fat=consumed_fat,
        consumed_fiber=consumed_fiber,
        calorie_progress=cal_prog,
        protein_progress=prot_prog,
        carbohydrates_progress=carbs_prog,
        fat_progress=fat_prog,
        fiber_progress=fiber_prog,
        meals_count=len(meals),
        goal=GoalRead.model_validate(goal),
    )


@router.get("/analytics/trends", response_model=TrendsAnalyticsRead)
async def get_trends_analytics(
    days: int = Query(
        default=7, ge=1, le=90, description="Number of past days to analyze (e.g. 7 or 30)"
    ),
    tz_offset: int = Query(
        default=0, description="Timezone offset in minutes from UTC (e.g. 330 for IST UTC+5:30)"
    ),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> TrendsAnalyticsRead:
    """Calculate time-series nutrition intake and averages over the last N days."""
    client_now = datetime.now(UTC) + timedelta(minutes=tz_offset)
    today = client_now.date()
    start_date = today - timedelta(days=days - 1)

    start_dt = datetime.combine(start_date, time.min).replace(tzinfo=UTC) - timedelta(
        minutes=tz_offset
    )
    end_dt = datetime.combine(today, time.max).replace(tzinfo=UTC) - timedelta(minutes=tz_offset)

    query = (
        select(Meal)
        .where(
            Meal.user_id == current_user.id,
            Meal.created_at >= start_dt,
            Meal.created_at <= end_dt,
        )
        .options(selectinload(Meal.items))
        .order_by(Meal.created_at.asc())
    )
    result = await db.execute(query)
    meals = list(result.scalars().all())

    goal = await _get_or_create_user_goal(current_user, db)
    goal_read = GoalRead.model_validate(goal)

    # Group meals by date (YYYY-MM-DD)
    # Group meals by local date (YYYY-MM-DD)
    meals_by_date: dict[str, list[Meal]] = {}
    for m in meals:
        m_date = m.created_at.date().isoformat()
        m_local_dt = m.created_at + timedelta(minutes=tz_offset)
        m_date = m_local_dt.date().isoformat()
        meals_by_date.setdefault(m_date, []).append(m)

    data_points: list[DailyTrendPoint] = []
    total_cals = 0.0
    total_prot = 0.0
    total_carbs = 0.0
    total_fat = 0.0
    total_fiber = 0.0

    for i in range(days):
        current_day = start_date + timedelta(days=i)
        day_str = current_day.isoformat()
        day_meals = meals_by_date.get(day_str, [])

        day_cals = round(sum(m.total_calories for m in day_meals), 2)
        day_prot = round(sum(m.total_protein for m in day_meals), 2)
        day_carbs = round(sum(m.total_carbohydrates for m in day_meals), 2)
        day_fat = round(sum(m.total_fat for m in day_meals), 2)
        day_fiber = round(sum(m.total_fiber for m in day_meals), 2)

        total_cals += day_cals
        total_prot += day_prot
        total_carbs += day_carbs
        total_fat += day_fat
        total_fiber += day_fiber

        data_points.append(
            DailyTrendPoint(
                date=day_str,
                calories=day_cals,
                protein=day_prot,
                carbohydrates=day_carbs,
                fat=day_fat,
                fiber=day_fiber,
                meals_count=len(day_meals),
                calorie_target=goal.calorie_target,
            )
        )

    avg_cals = round(total_cals / days, 2)
    avg_prot = round(total_prot / days, 2)
    avg_carbs = round(total_carbs / days, 2)
    avg_fat = round(total_fat / days, 2)
    avg_fiber = round(total_fiber / days, 2)

    return TrendsAnalyticsRead(
        period=f"{days}d",
        days_count=days,
        start_date=start_date.isoformat(),
        end_date=today.isoformat(),
        average_calories=avg_cals,
        average_protein=avg_prot,
        average_carbohydrates=avg_carbs,
        average_fat=avg_fat,
        average_fiber=avg_fiber,
        goal=goal_read,
        data_points=data_points,
    )


@router.get("/analytics/streaks", response_model=StreaksResponse)
async def get_streaks_and_badges(
    tz_offset: int = Query(
        default=0, description="Timezone offset in minutes from UTC (e.g. 330 for IST UTC+5:30)"
    ),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> StreaksResponse:
    """Calculate the user's current streak, longest streak, daily score with breakdown, and badges."""
    service = StreakService(db)
    return await service.get_user_streaks_and_badges(current_user.id, tz_offset=tz_offset)


@router.get("/analytics/weekly", response_model=WeeklyReportResponse)
async def get_weekly_report(
    week_offset: int = Query(
        default=0, description="Week offset from current week (0 = this week, -1 = last week)"
    ),
    tz_offset: int = Query(
        default=0, description="Timezone offset in minutes from UTC (e.g. 330 for IST UTC+5:30)"
    ),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> WeeklyReportResponse:
    """Generate weekly nutrition, score, nutrient compliance, and prior-week comparison report."""
    service = WeeklyService(db)
    return await service.get_weekly_report(
        user_id=current_user.id, week_offset=week_offset, tz_offset=tz_offset
    )
