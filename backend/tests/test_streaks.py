"""Tests for Streaks, Daily Score Calculation, and Derived Badges."""

import uuid
from datetime import UTC, datetime, timedelta

import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.goal import Goal
from app.models.meal import Meal
from app.services.streak_service import StreakService, calculate_daily_score


def test_score_calculation_all_targets_met():
    """All targets met results in 100/100 score."""
    score, breakdown = calculate_daily_score(
        calories=2000.0,
        protein=110.0,  # >= 108g (90% of 120g)
        fiber=25.0,  # >= 24g (80% of 30g)
        water_ml=2500.0,  # >= 2500ml (100% of 2500ml)
        calorie_target=2000.0,
        protein_target=120.0,
        fiber_target=30.0,
        water_target_ml=2500.0,
    )
    assert score == 100
    assert breakdown.calories.achieved is True
    assert breakdown.calories.points == 40.0
    assert breakdown.protein.achieved is True
    assert breakdown.protein.points == 30.0
    assert breakdown.fiber.achieved is True
    assert breakdown.fiber.points == 15.0
    assert breakdown.water.achieved is True
    assert breakdown.water.points == 15.0


def test_score_calculation_zero_intake():
    """Zero intake results in 0/100 score."""
    score, breakdown = calculate_daily_score(
        calories=0.0,
        protein=0.0,
        fiber=0.0,
        water_ml=0.0,
        calorie_target=2000.0,
        protein_target=120.0,
        fiber_target=30.0,
        water_target_ml=2500.0,
    )
    assert score == 0
    assert breakdown.calories.achieved is False
    assert breakdown.calories.points == 0.0
    assert breakdown.protein.achieved is False
    assert breakdown.protein.points == 0.0
    assert breakdown.fiber.achieved is False
    assert breakdown.fiber.points == 0.0
    assert breakdown.water.achieved is False
    assert breakdown.water.points == 0.0


def test_score_calculation_boundary_values():
    """Verify strict boundary values for each category."""
    # Calorie target 2000: ±10% range is [1800.0, 2200.0]
    # Lower boundary met
    s, b = calculate_daily_score(
        calories=1800.0, protein=0, fiber=0, water_ml=0, calorie_target=2000.0
    )
    assert b.calories.achieved is True
    assert s == 40

    # Upper boundary met
    s, b = calculate_daily_score(
        calories=2200.0, protein=0, fiber=0, water_ml=0, calorie_target=2000.0
    )
    assert b.calories.achieved is True
    assert s == 40

    # Just below lower boundary
    s, b = calculate_daily_score(
        calories=1799.0, protein=0, fiber=0, water_ml=0, calorie_target=2000.0
    )
    assert b.calories.achieved is False
    assert s == 0

    # Just above upper boundary
    s, b = calculate_daily_score(
        calories=2201.0, protein=0, fiber=0, water_ml=0, calorie_target=2000.0
    )
    assert b.calories.achieved is False
    assert s == 0

    # Protein target 100: >= 90% is 90.0g
    s, b = calculate_daily_score(
        calories=0, protein=90.0, fiber=0, water_ml=0, protein_target=100.0
    )
    assert b.protein.achieved is True
    assert s == 30

    s, b = calculate_daily_score(
        calories=0, protein=89.9, fiber=0, water_ml=0, protein_target=100.0
    )
    assert b.protein.achieved is False
    assert s == 0

    # Fiber target 30: >= 80% is 24.0g
    s, b = calculate_daily_score(calories=0, protein=0, fiber=24.0, water_ml=0, fiber_target=30.0)
    assert b.fiber.achieved is True
    assert s == 15

    s, b = calculate_daily_score(calories=0, protein=0, fiber=23.9, water_ml=0, fiber_target=30.0)
    assert b.fiber.achieved is False
    assert s == 0

    # Water target 2500: >= 100% is 2500.0ml
    s, b = calculate_daily_score(
        calories=0, protein=0, fiber=0, water_ml=2500.0, water_target_ml=2500.0
    )
    assert b.water.achieved is True
    assert s == 15

    s, b = calculate_daily_score(
        calories=0, protein=0, fiber=0, water_ml=2499.0, water_target_ml=2500.0
    )
    assert b.water.achieved is False
    assert s == 0


@pytest.mark.asyncio
async def test_streak_continuation_and_breaks(db_session: AsyncSession):
    """Test streak continuation across consecutive days and breaks when score < 60."""
    user_id = uuid.uuid4()
    now = datetime.now(UTC)

    # Goal: 2000 cal, 100 prot, 250 carbs, 65 fat, 30 fiber, 2000 water
    goal = Goal(
        user_id=user_id,
        calorie_target=2000.0,
        protein_target=100.0,
        carbohydrates_target=250.0,
        fat_target=65.0,
        fiber_target=30.0,
        water_target_ml=2000.0,
    )
    db_session.add(goal)

    # Helper to add a qualifying day (score 70 = 40 cal + 30 protein)
    def add_day_meals(dt: datetime, cal: float, prot: float):
        m = Meal(
            user_id=user_id,
            meal_type="dinner",
            total_calories=cal,
            total_protein=prot,
            total_carbohydrates=100.0,
            total_fat=20.0,
            total_fiber=5.0,
            created_at=dt,
        )
        db_session.add(m)

    # Day -4: qualified (2000 cal, 95 prot) -> score 70
    add_day_meals(now - timedelta(days=4), 2000.0, 95.0)
    # Day -3: qualified (1900 cal, 95 prot) -> score 70
    add_day_meals(now - timedelta(days=3), 1900.0, 95.0)
    # Day -2: UNQUALIFIED (100 cal, 5 prot) -> score 0 (breaks streak!)
    add_day_meals(now - timedelta(days=2), 100.0, 5.0)
    # Day -1 (yesterday): qualified (2000 cal, 95 prot) -> score 70
    add_day_meals(now - timedelta(days=1), 2000.0, 95.0)
    # Day 0 (today): qualified (2050 cal, 95 prot) -> score 70
    add_day_meals(now, 2050.0, 95.0)

    await db_session.commit()

    service = StreakService(db_session)
    res = await service.get_user_streaks_and_badges(user_id=user_id, tz_offset=0)

    # Current streak should be 2 (yesterday + today), longest streak 2
    assert res.current_streak == 2
    assert res.longest_streak == 2
    assert res.streak_active_today is True


@pytest.mark.asyncio
async def test_streak_ending_yesterday_preserved_today(db_session: AsyncSession):
    """If today is not yet qualified, yesterday's streak is still counted as current_streak."""
    user_id = uuid.uuid4()
    now = datetime.now(UTC)

    goal = Goal(
        user_id=user_id,
        calorie_target=2000.0,
        protein_target=100.0,
        carbohydrates_target=250.0,
        fat_target=65.0,
        fiber_target=30.0,
        water_target_ml=2000.0,
    )
    db_session.add(goal)

    # Add 3 consecutive qualified days ending yesterday
    for i in range(1, 4):
        dt = now - timedelta(days=i)
        db_session.add(
            Meal(
                user_id=user_id,
                meal_type="lunch",
                total_calories=2000.0,
                total_protein=95.0,
                total_carbohydrates=100.0,
                total_fat=20.0,
                total_fiber=5.0,
                created_at=dt,
            )
        )
    await db_session.commit()

    service = StreakService(db_session)
    res = await service.get_user_streaks_and_badges(user_id=user_id, tz_offset=0)

    # Current streak should be 3 (consecutive ending yesterday)
    assert res.current_streak == 3
    assert res.longest_streak == 3
    assert res.streak_active_today is False
    # streak_3 badge should be unlocked
    unlocked_ids = {b.id for b in res.badges if b.unlocked}
    assert "streak_3" in unlocked_ids
    assert "streak_7" not in unlocked_ids


@pytest.mark.asyncio
async def test_badge_unlocks_streak_and_protein(db_session: AsyncSession):
    """Verify streak_7 unlock and hit_protein_today unlock."""
    user_id = uuid.uuid4()
    now = datetime.now(UTC)

    goal = Goal(
        user_id=user_id,
        calorie_target=2000.0,
        protein_target=100.0,
        carbohydrates_target=250.0,
        fat_target=65.0,
        fiber_target=30.0,
        water_target_ml=2000.0,
    )
    db_session.add(goal)

    # Add 7 consecutive qualified days ending today
    for i in range(7):
        dt = now - timedelta(days=i)
        db_session.add(
            Meal(
                user_id=user_id,
                meal_type="dinner",
                total_calories=2000.0,
                total_protein=95.0,
                total_carbohydrates=100.0,
                total_fat=20.0,
                total_fiber=5.0,
                created_at=dt,
            )
        )
    await db_session.commit()

    service = StreakService(db_session)
    res = await service.get_user_streaks_and_badges(user_id=user_id, tz_offset=0)

    assert res.current_streak == 7
    assert res.longest_streak == 7
    unlocked_ids = {b.id for b in res.badges if b.unlocked}
    assert "streak_3" in unlocked_ids
    assert "streak_7" in unlocked_ids
    assert "hit_protein_today" in unlocked_ids


@pytest.mark.asyncio
async def test_get_streaks_endpoint(client: AsyncClient, auth_headers: dict[str, str]):
    """Test GET /api/v1/analytics/streaks endpoint."""
    response = await client.get("/api/v1/analytics/streaks?tz_offset=0", headers=auth_headers)
    assert response.status_code == 200
    data = response.json()
    assert "current_streak" in data
    assert "longest_streak" in data
    assert "today_score" in data
    assert "breakdown" in data["today_score"]
    assert "calories" in data["today_score"]["breakdown"]
    assert "protein" in data["today_score"]["breakdown"]
    assert "fiber" in data["today_score"]["breakdown"]
    assert "water" in data["today_score"]["breakdown"]
    assert "badges" in data
    assert len(data["badges"]) >= 5
