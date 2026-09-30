"""Tests for deterministic nutrition calculation, fuzzy food matching, and unit conversions."""

import pytest
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.food import Food
from app.services.nutrition_service import NutritionService


@pytest.fixture
async def seed_test_foods(db_session: AsyncSession) -> list[Food]:
    foods = [
        Food(
            name="Cooked white rice",
            canonical_name="cooked_white_rice",
            serving_size=100,
            serving_unit="g",
            calories=130,
            protein=2.7,
            carbohydrates=28.0,
            fat=0.3,
            fiber=0.4,
        ),
        Food(
            name="Chicken (cooked)",
            canonical_name="chicken",
            serving_size=100,
            serving_unit="g",
            calories=165,
            protein=31.0,
            carbohydrates=0.0,
            fat=3.6,
            fiber=0.0,
        ),
        Food(
            name="Dal (lentil curry)",
            canonical_name="dal",
            serving_size=100,
            serving_unit="g",
            calories=116,
            protein=9.0,
            carbohydrates=20.0,
            fat=0.4,
            fiber=7.9,
        ),
        Food(
            name="Egg (boiled)",
            canonical_name="egg",
            serving_size=100,
            serving_unit="g",
            calories=155,
            protein=13.0,
            carbohydrates=1.1,
            fat=11.0,
            fiber=0.0,
        ),
        Food(
            name="Apple",
            canonical_name="apple",
            serving_size=100,
            serving_unit="g",
            calories=52,
            protein=0.3,
            carbohydrates=14.0,
            fat=0.2,
            fiber=2.4,
        ),
    ]
    for f in foods:
        db_session.add(f)
    await db_session.commit()
    return foods


@pytest.mark.asyncio
async def test_100g_rice_matches_per_serving_values(seed_test_foods: list[Food]) -> None:
    rice = seed_test_foods[0]
    result = NutritionService.calculate_nutrition_for_quantity(rice, quantity=100, unit="g")

    assert result.calories == 130
    assert result.protein == 2.7
    assert result.carbohydrates == 28.0


@pytest.mark.asyncio
async def test_200g_rice_scales_linearly(seed_test_foods: list[Food]) -> None:
    rice = seed_test_foods[0]
    result = NutritionService.calculate_nutrition_for_quantity(rice, quantity=200, unit="g")

    assert result.calories == 260
    assert result.protein == 5.4
    assert result.carbohydrates == 56.0


@pytest.mark.asyncio
async def test_find_food_by_name_uses_synonym_table(
    db_session: AsyncSession, seed_test_foods: list[Food]
) -> None:
    service = NutritionService(db_session)
    found = await service.find_food_by_name("white rice")

    assert found is not None
    assert found.canonical_name == "cooked_white_rice"


@pytest.mark.asyncio
async def test_fuzzy_matching_complex_queries(
    db_session: AsyncSession, seed_test_foods: list[Food]
) -> None:
    service = NutritionService(db_session)

    # Fuzzy matches with extra adjectives / differing word order
    found_chicken = await service.find_food_by_name("grilled chicken breast")
    assert found_chicken is not None
    assert found_chicken.canonical_name == "chicken"

    found_egg = await service.find_food_by_name("boiled brown egg")
    assert found_egg is not None
    assert found_egg.canonical_name == "egg"

    found_dal = await service.find_food_by_name("yellow lentil curry dal")
    assert found_dal is not None
    assert found_dal.canonical_name == "dal"


@pytest.mark.asyncio
async def test_unit_conversion_cups_and_bowls(
    db_session: AsyncSession, seed_test_foods: list[Food]
) -> None:
    service = NutritionService(db_session)

    # 1 cup = 240g of white rice (130 kcal / 100g * 240g = 312 kcal)
    result_cup = await service.calculate_for_detection(name="white rice", quantity=1.0, unit="cup")
    assert result_cup.matched_food is not None
    assert result_cup.calories == 312.0

    # 1 bowl = 350g of dal (116 kcal / 100g * 350g = 406 kcal)
    result_bowl = await service.calculate_for_detection(name="dal", quantity=1.0, unit="bowl")
    assert result_bowl.matched_food is not None
    assert result_bowl.calories == 406.0


@pytest.mark.asyncio
async def test_unit_conversion_pieces_and_tablespoons(
    db_session: AsyncSession, seed_test_foods: list[Food]
) -> None:
    service = NutritionService(db_session)

    # 2 whole boiled eggs (2 * 50g = 100g -> 155 kcal)
    result_eggs = await service.calculate_for_detection(name="egg", quantity=2.0, unit="piece")
    assert result_eggs.matched_food is not None
    assert result_eggs.calories == 155.0
    assert result_eggs.protein == 13.0


@pytest.mark.asyncio
async def test_unmatched_food_returns_zeroed_nutrition(db_session: AsyncSession) -> None:
    service = NutritionService(db_session)
    result = await service.calculate_for_detection(
        "unknown extraterrestrial object 999", quantity=100
    )

    assert result.matched_food is None
    assert result.matched is False
    assert result.calories == 0.0
    assert result.protein == 0.0
    assert result.carbohydrates == 0.0
    assert result.fat == 0.0
    assert result.fiber == 0.0


@pytest.mark.asyncio
async def test_fuzzy_matching_steamed_basmati_rice_and_unrelated_rejection(
    db_session: AsyncSession,
) -> None:
    rice = Food(
        name="Cooked white rice",
        canonical_name="cooked_white_rice",
        serving_size=100,
        serving_unit="g",
        calories=130,
        protein=2.7,
        carbohydrates=28.0,
        fat=0.3,
        fiber=0.4,
    )
    db_session.add(rice)
    await db_session.commit()

    service = NutritionService(db_session)

    # 1. Close-but-not-exact name matches above threshold
    matched_rice = await service.find_food_by_name("steamed basmati rice")
    assert matched_rice is not None
    assert matched_rice.canonical_name == "cooked_white_rice"

    # 2. Genuinely unrelated food returns None
    unrelated = await service.find_food_by_name("mystery food xyz")
    assert unrelated is None
