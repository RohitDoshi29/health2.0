"""Tests for Weekly Report Service and Endpoint."""

import uuid
from datetime import UTC, datetime, time, timedelta

import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.goal import Goal
from app.models.meal import Meal
from app.models.weight_log import WeightLog
from app.services.weekly_service import WeeklyService


@pytest.mark.asyncio
async def test_weekly_report_averages_and_boundaries(db_session: AsyncSession):
    """Test weekly report averages computation and Monday-start week boundaries."""
    user_id = uuid.uuid4()
    now = datetime.now(UTC)

    # Calculate Monday of current week
    today = now.date()
    monday = today - timedelta(days=today.weekday())

    goal = Goal(
        user_id=user_id,
        calorie_target=2000.0,
        protein_target=100.0,
        carbohydrates_target=250.0,
        fat_target=65.0,
        fiber_target=30.0,
        water_target_ml=2500.0,
    )
    db_session.add(goal)

    # Add meals for 3 days: Monday (2000 cals, 100 prot), Tuesday (1800 cals, 90 prot), Wednesday (1600 cals, 80 prot)
    # Target hits:
    # Monday: calories (within ±10%: 1800-2200), protein (>=90: 100) -> hit both
    # Tuesday: calories (1800 -> hit), protein (90 -> hit)
    # Wednesday: calories (1600 -> not hit), protein (80 -> not hit)
    mon_dt = datetime.combine(monday, time(12, 0)).replace(tzinfo=UTC)
    tue_dt = mon_dt + timedelta(days=1)
    wed_dt = mon_dt + timedelta(days=2)

    db_session.add(
        Meal(
            user_id=user_id,
            meal_type="lunch",
            total_calories=2000.0,
            total_protein=100.0,
            total_carbohydrates=200.0,
            total_fat=50.0,
            total_fiber=25.0,
            created_at=mon_dt,
        )
    )
    db_session.add(
        Meal(
            user_id=user_id,
            meal_type="lunch",
            total_calories=1800.0,
            total_protein=90.0,
            total_carbohydrates=180.0,
            total_fat=45.0,
            total_fiber=20.0,
            created_at=tue_dt,
        )
    )
    db_session.add(
        Meal(
            user_id=user_id,
            meal_type="lunch",
            total_calories=1600.0,
            total_protein=80.0,
            total_carbohydrates=150.0,
            total_fat=40.0,
            total_fiber=15.0,
            created_at=wed_dt,
        )
    )

    await db_session.commit()

    service = WeeklyService(db_session)
    res = await service.get_weekly_report(user_id=user_id, week_offset=0, tz_offset=0)

    # 7-day average: (2000 + 1800 + 1600) / 7 = 5400 / 7 = 771.4
    assert res.daily_averages.calories == 771.4
    # protein: (100 + 90 + 80) / 7 = 270 / 7 = 38.6
    assert res.daily_averages.protein == 38.6

    # Nutrient hits: calories hit Monday and Tuesday -> 2 days; protein hit Monday and Tuesday -> 2 days
    assert res.nutrient_hits.calories == 2
    assert res.nutrient_hits.protein == 2

    # Best day should be Monday or Tuesday (highest score); worst day should be an empty day (score 0)
    assert res.best_day.score > res.worst_day.score
    assert res.worst_day.score == 0

    # Start and end date should match Monday and Sunday
    assert res.start_date == monday.isoformat()
    assert res.end_date == (monday + timedelta(days=6)).isoformat()


@pytest.mark.asyncio
async def test_weekly_report_division_by_zero_prior_week(db_session: AsyncSession):
    """When prior week has zero intake, percentage changes should safely return None."""
    user_id = uuid.uuid4()
    now = datetime.now(UTC)
    today = now.date()
    monday = today - timedelta(days=today.weekday())

    goal = Goal(
        user_id=user_id,
        calorie_target=2000.0,
        protein_target=100.0,
        carbohydrates_target=250.0,
        fat_target=65.0,
        fiber_target=30.0,
        water_target_ml=2500.0,
    )
    db_session.add(goal)

    # Log meal only in current week
    db_session.add(
        Meal(
            user_id=user_id,
            meal_type="dinner",
            total_calories=2100.0,
            total_protein=105.0,
            total_carbohydrates=200.0,
            total_fat=50.0,
            total_fiber=25.0,
            created_at=datetime.combine(monday, time(19, 0)).replace(tzinfo=UTC),
        )
    )
    await db_session.commit()

    service = WeeklyService(db_session)
    res = await service.get_weekly_report(user_id=user_id, week_offset=0, tz_offset=0)

    # Prior week had 0 calories and 0 protein
    assert res.prior_week_comparison.prior_average_calories == 0.0
    assert res.prior_week_comparison.prior_average_protein == 0.0
    # Must be None (no division by zero!)
    assert res.prior_week_comparison.calories_pct_change is None
    assert res.prior_week_comparison.protein_pct_change is None


@pytest.mark.asyncio
async def test_weekly_report_comparison_percentages(db_session: AsyncSession):
    """When prior week has data, percentage changes are computed accurately."""
    user_id = uuid.uuid4()
    now = datetime.now(UTC)
    today = now.date()
    monday = today - timedelta(days=today.weekday())
    prior_monday = monday - timedelta(days=7)

    goal = Goal(
        user_id=user_id,
        calorie_target=2000.0,
        protein_target=100.0,
        carbohydrates_target=250.0,
        fat_target=65.0,
        fiber_target=30.0,
        water_target_ml=2500.0,
    )
    db_session.add(goal)

    # Prior week: 7000 total calories (1000/day average), 700 total protein (100/day average)
    for i in range(7):
        db_session.add(
            Meal(
                user_id=user_id,
                meal_type="lunch",
                total_calories=1000.0,
                total_protein=100.0,
                total_carbohydrates=100.0,
                total_fat=20.0,
                total_fiber=10.0,
                created_at=datetime.combine(prior_monday + timedelta(days=i), time(12, 0)).replace(
                    tzinfo=UTC
                ),
            )
        )

    # Current week: 14000 total calories (2000/day average: +100%), 350 total protein (50/day average: -50%)
    for i in range(7):
        db_session.add(
            Meal(
                user_id=user_id,
                meal_type="lunch",
                total_calories=2000.0,
                total_protein=50.0,
                total_carbohydrates=200.0,
                total_fat=40.0,
                total_fiber=20.0,
                created_at=datetime.combine(monday + timedelta(days=i), time(12, 0)).replace(
                    tzinfo=UTC
                ),
            )
        )

    await db_session.commit()

    service = WeeklyService(db_session)
    res = await service.get_weekly_report(user_id=user_id, week_offset=0, tz_offset=0)

    assert res.prior_week_comparison.prior_average_calories == 1000.0
    assert res.daily_averages.calories == 2000.0
    assert res.prior_week_comparison.calories_pct_change == 100.0

    assert res.prior_week_comparison.prior_average_protein == 100.0
    assert res.daily_averages.protein == 50.0
    assert res.prior_week_comparison.protein_pct_change == -50.0


@pytest.mark.asyncio
async def test_weekly_report_weight_change(db_session: AsyncSession):
    """Verify weight change from first logged weight to last logged weight in the window."""
    user_id = uuid.uuid4()
    now = datetime.now(UTC)
    today = now.date()
    monday = today - timedelta(days=today.weekday())

    goal = Goal(user_id=user_id)
    db_session.add(goal)

    # Weight on Tuesday: 72.0 kg
    db_session.add(
        WeightLog(
            user_id=user_id,
            weight_kg=72.0,
            logged_at=datetime.combine(monday + timedelta(days=1), time(8, 0)).replace(tzinfo=UTC),
        )
    )
    # Weight on Friday: 71.3 kg
    db_session.add(
        WeightLog(
            user_id=user_id,
            weight_kg=71.3,
            logged_at=datetime.combine(monday + timedelta(days=4), time(8, 0)).replace(tzinfo=UTC),
        )
    )
    await db_session.commit()

    service = WeeklyService(db_session)
    res = await service.get_weekly_report(user_id=user_id, week_offset=0, tz_offset=0)

    assert res.weight_change is not None
    assert res.weight_change.start_weight_kg == 72.0
    assert res.weight_change.end_weight_kg == 71.3
    assert res.weight_change.change_kg == -0.7


@pytest.mark.asyncio
async def test_get_weekly_report_endpoint(client: AsyncClient, auth_headers: dict[str, str]):
    """Test GET /api/v1/analytics/weekly endpoint."""
    response = await client.get(
        "/api/v1/analytics/weekly?week_offset=0&tz_offset=0", headers=auth_headers
    )
    assert response.status_code == 200
    data = response.json()
    assert "start_date" in data
    assert "end_date" in data
    assert "daily_averages" in data
    assert "best_day" in data
    assert "worst_day" in data
    assert "nutrient_hits" in data
    assert "prior_week_comparison" in data
    assert "daily_points" in data
    assert len(data["daily_points"]) == 7
