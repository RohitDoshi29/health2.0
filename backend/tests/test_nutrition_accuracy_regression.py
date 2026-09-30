"""Comprehensive regression test suite for nutrition pipeline physical accuracy.

Explicitly validates:
- The exact screenshot bug scenario (300g food with 8563 kcal and 609.8g protein)
- Test 1: 300g pizza -> plausible 700-900 kcal
- Test 2: 609g protein in 300g food -> rejected
- Test 3: 8563 kcal in 300g food -> rejected
- Test 4: Macro calories disagreeing with reported calories -> rejected
- Test 5: Unmatched food -> flagged low confidence / needs confirmation, not verified 0 kcal
- Test 6: Pizza + cheese -> no automatic double counting
- Test 7: Quantity changed 1 slice -> 2 slices -> deterministic recalculation
- Test 8: Same image analyzed twice -> content-hash cache hit
- Test 9: Different image -> cache miss
- Test 10: Database food with invalid nutrition -> rejected from use
"""

import io
from unittest.mock import AsyncMock

import pytest
from PIL import Image
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.food import Food
from app.schemas.analysis import (
    FoodDetection,
    GeminiAnalysisResult,
    QuantityUnit,
)
from app.schemas.verification import VerificationStatus
from app.services.calorie_verification_service import (
    CalorieVerificationService,
    VerificationInput,
)
from app.services.meal_service import MealService
from app.services.nutrition_service import (
    NutritionService,
)


@pytest.fixture
def pizza_db_food() -> Food:
    return Food(
        name="Cheese pizza",
        canonical_name="cheese_pizza",
        serving_size=100.0,
        serving_unit="g",
        calories=280.0,
        protein=11.7,
        carbohydrates=29.9,
        fat=12.6,
        fiber=1.7,
        source="usda",
    )


def _make_dummy_image(color: tuple[int, int, int]) -> bytes:
    img = Image.new("RGB", (400, 300), color=color)
    buf = io.BytesIO()
    img.save(buf, format="JPEG")
    return buf.getvalue()


# ---------------------------------------------------------------------------
# EXACT SCREENSHOT BUG SCENARIO
# ---------------------------------------------------------------------------


def test_screenshot_scenario_physically_impossible_result_rejected() -> None:
    """Exact bug reproduction:

    food_weight = 300g, protein = 609.8g, carbs = 205.7g, fat = 637.2g, calories = 8563.
    MUST NEVER be presented as verified. Must be assigned NEEDS_CONFIRMATION.
    """
    item = VerificationInput(
        food_name="Pizza with Paneer and Pepper",
        detected_quantity=300.0,
        unit="g",
        grams=300.0,
        calories=8563.0,
        protein=609.8,
        carbohydrates=205.7,
        fat=637.2,
        fiber=20.5,
        nutrition_source="local_database",
        is_matched_in_db=True,
    )

    result = CalorieVerificationService.verify(item)

    assert result.verification_status == VerificationStatus.NEEDS_CONFIRMATION
    assert len(result.anomaly_flags) > 0
    # Must flag physical impossibilities
    assert "macronutrient_mass_exceeds_weight" in result.anomaly_flags
    assert "extreme_calorie_density" in result.anomaly_flags
    assert "protein_exceeds_weight" in result.anomaly_flags
    assert result.confidence_score <= 25.0


# ---------------------------------------------------------------------------
# TEST 1: 300g pizza -> plausible nutrition range (700-900 kcal)
# ---------------------------------------------------------------------------


def test_1_300g_pizza_reasonable_nutrition_range(pizza_db_food: Food) -> None:
    res = NutritionService.calculate_nutrition_for_quantity(pizza_db_food, quantity=300.0, unit="g")
    # 280 kcal per 100g -> 840 kcal for 300g (within 700-900 kcal range)
    assert 700.0 <= res.calories <= 900.0
    assert 30.0 <= res.protein <= 45.0
    assert 70.0 <= res.carbohydrates <= 100.0
    assert 30.0 <= res.fat <= 45.0


# ---------------------------------------------------------------------------
# TEST 2: 609g protein in 300g food -> rejected
# ---------------------------------------------------------------------------


def test_2_protein_exceeding_food_weight_rejected() -> None:
    item = VerificationInput(
        food_name="Protein Anomaly",
        detected_quantity=300.0,
        unit="g",
        grams=300.0,
        calories=2700.0,
        protein=609.8,  # > 300g physical mass!
        carbohydrates=20.0,
        fat=10.0,
        nutrition_source="local_database",
        is_matched_in_db=True,
    )
    result = CalorieVerificationService.verify(item)
    assert result.verification_status == VerificationStatus.NEEDS_CONFIRMATION
    assert "protein_exceeds_weight" in result.anomaly_flags


# ---------------------------------------------------------------------------
# TEST 3: 8563 kcal in 300g food -> rejected
# ---------------------------------------------------------------------------


def test_3_extreme_caloric_density_rejected() -> None:
    item = VerificationInput(
        food_name="Calorie Bomb",
        detected_quantity=300.0,
        unit="g",
        grams=300.0,
        calories=8563.0,  # 8563 / 300 = 28.5 kcal/g (> 9.5 kcal/g max fat density)
        protein=30.0,
        carbohydrates=40.0,
        fat=20.0,
        nutrition_source="local_database",
        is_matched_in_db=True,
    )
    result = CalorieVerificationService.verify(item)
    assert result.verification_status == VerificationStatus.NEEDS_CONFIRMATION
    assert "extreme_calorie_density" in result.anomaly_flags


# ---------------------------------------------------------------------------
# TEST 4: Macro calories disagreeing with reported calories -> rejected
# ---------------------------------------------------------------------------


def test_4_macro_consistency_discrepancy_rejected() -> None:
    item = VerificationInput(
        food_name="Ghost Calories Meal",
        detected_quantity=200.0,
        unit="g",
        grams=200.0,
        calories=900.0,  # Reported 900
        protein=10.0,  # 40 kcal
        carbohydrates=20.0,  # 80 kcal
        fat=5.0,  # 45 kcal -> macro cals = 165 kcal (diff > 80%)
        nutrition_source="local_database",
        is_matched_in_db=True,
    )
    result = CalorieVerificationService.verify(item)
    assert result.verification_status == VerificationStatus.NEEDS_CONFIRMATION
    assert result.discrepancy_percent > 35.0


# ---------------------------------------------------------------------------
# TEST 5: Unmatched food -> low confidence / needs confirmation, not verified 0 kcal
# ---------------------------------------------------------------------------


@pytest.mark.asyncio
async def test_5_unmatched_food_flagged_with_low_confidence(db_session: AsyncSession) -> None:
    svc = NutritionService(db_session)
    result = await svc.calculate_for_detection("interstellar plasma dust", quantity=100.0, unit="g")
    assert result.matched is False

    v_input = VerificationInput(
        food_name="interstellar plasma dust",
        detected_quantity=100.0,
        unit="g",
        grams=100.0,
        calories=result.calories,
        protein=result.protein,
        carbohydrates=result.carbohydrates,
        fat=result.fat,
        nutrition_source="ai_estimate",
        is_matched_in_db=False,
    )
    verification = CalorieVerificationService.verify(v_input)

    assert verification.verification_status == VerificationStatus.LOW_CONFIDENCE
    assert verification.confidence_score <= 35.0
    assert "not found in reference database" in verification.verification_note.lower()


# ---------------------------------------------------------------------------
# TEST 6: Pizza + Cheese -> no automatic double counting
# ---------------------------------------------------------------------------


@pytest.mark.asyncio
async def test_6_pizza_and_cheese_no_double_counting(db_session: AsyncSession) -> None:
    # Seed pizza and cheese into database
    pizza = Food(
        name="Cheese pizza",
        canonical_name="cheese_pizza",
        serving_size=100.0,
        serving_unit="g",
        calories=280.0,
        protein=11.7,
        carbohydrates=29.9,
        fat=12.6,
        source="usda",
    )
    cheese = Food(
        name="Mozzarella cheese",
        canonical_name="mozzarella_cheese",
        serving_size=100.0,
        serving_unit="g",
        calories=300.0,
        protein=22.0,
        carbohydrates=2.2,
        fat=22.4,
        source="usda",
    )
    db_session.add_all([pizza, cheese])
    await db_session.commit()

    mock_gemini = AsyncMock()
    mock_gemini.detect_foods.return_value = GeminiAnalysisResult(
        foods=[
            FoodDetection(
                name="Pizza",
                estimated_quantity=2.0,
                unit=QuantityUnit.SLICE,
                confidence=0.92,
            ),
            FoodDetection(
                name="Cheese",
                estimated_quantity=50.0,
                unit=QuantityUnit.G,
                confidence=0.85,
            ),
        ]
    )

    meal_svc = MealService(db=db_session, gemini_service=mock_gemini)

    # Synthetic upload
    class MockUpload:
        filename = "pizza_photo.jpg"
        content_type = "image/jpeg"

        async def read(self) -> bytes:
            return _make_dummy_image((200, 100, 50))

    response = await meal_svc.analyze_image(MockUpload())

    # Find the pizza and cheese items
    pizza_item = next(i for i in response.items if "pizza" in i.name.lower())
    cheese_item = next(i for i in response.items if "cheese" in i.name.lower())

    assert cheese_item.is_component is True
    assert cheese_item.parent_food == "Pizza"
    assert cheese_item.estimated_calories == 0.0

    # Total meal calories must NOT include the cheese topping
    assert response.total.estimated_calories == pizza_item.final_calories


# ---------------------------------------------------------------------------
# TEST 7: Quantity changed 1 slice -> 2 slices -> deterministic recalculation
# ---------------------------------------------------------------------------


def test_7_quantity_change_deterministic_scaling(pizza_db_food: Food) -> None:
    # 1 slice = 115g
    res_1_slice = NutritionService.calculate_nutrition_for_quantity(
        pizza_db_food, quantity=1.0, unit="slice"
    )
    assert res_1_slice.grams == 115.0
    cals_1 = res_1_slice.calories

    # 2 slices = 230g
    res_2_slices = NutritionService.calculate_nutrition_for_quantity(
        pizza_db_food, quantity=2.0, unit="slice"
    )
    assert res_2_slices.grams == 230.0
    cals_2 = res_2_slices.calories

    # Scales deterministically by exactly 2.0x
    assert round(cals_2, 2) == round(cals_1 * 2.0, 2)


# ---------------------------------------------------------------------------
# TEST 8 & 9: Content-hash image caching
# ---------------------------------------------------------------------------


@pytest.mark.asyncio
async def test_8_and_9_content_hash_caching(db_session: AsyncSession) -> None:
    pizza = Food(
        name="Cheese pizza",
        canonical_name="cheese_pizza",
        serving_size=100.0,
        serving_unit="g",
        calories=280.0,
        protein=11.7,
        carbohydrates=29.9,
        fat=12.6,
        source="usda",
    )
    db_session.add(pizza)
    await db_session.commit()

    mock_gemini = AsyncMock()
    mock_gemini.detect_foods.return_value = GeminiAnalysisResult(
        foods=[
            FoodDetection(
                name="Pizza",
                estimated_quantity=1.0,
                unit=QuantityUnit.SLICE,
                confidence=0.90,
            )
        ]
    )

    meal_svc = MealService(db=db_session, gemini_service=mock_gemini)

    img_1_bytes = _make_dummy_image((120, 150, 180))
    img_2_bytes = _make_dummy_image((255, 200, 100))  # Different image

    class MockUpload1:
        filename = "img1.jpg"
        content_type = "image/jpeg"

        async def read(self) -> bytes:
            return img_1_bytes

    class MockUpload2:
        filename = "img2.jpg"
        content_type = "image/jpeg"

        async def read(self) -> bytes:
            return img_2_bytes

    # First call: calls Gemini
    res1 = await meal_svc.analyze_image(MockUpload1())
    assert mock_gemini.detect_foods.call_count == 1

    # Second call with SAME image: cache hit, Gemini NOT called again
    res1_cached = await meal_svc.analyze_image(MockUpload1())
    assert mock_gemini.detect_foods.call_count == 1
    assert res1.total.estimated_calories == res1_cached.total.estimated_calories

    # Call with DIFFERENT image: cache miss, Gemini called again
    await meal_svc.analyze_image(MockUpload2())
    assert mock_gemini.detect_foods.call_count == 2


# ---------------------------------------------------------------------------
# TEST 10: Database food with invalid nutrition -> rejected from use
# ---------------------------------------------------------------------------


@pytest.mark.asyncio
async def test_10_corrupted_database_food_rejected(db_session: AsyncSession) -> None:
    # Corrupted food record with negative carbs and extreme impossible calories
    corrupt_food = Food(
        name="Corrupt Toxic Berry",
        canonical_name="corrupt_toxic_berry",
        serving_size=100.0,
        serving_unit="g",
        calories=2500.0,  # 25 kcal/g -> impossible density!
        protein=-5.0,  # negative protein!
        carbohydrates=10.0,
        fat=10.0,
        source="seed",
    )
    db_session.add(corrupt_food)
    await db_session.commit()

    assert corrupt_food.is_physically_valid is False

    svc = NutritionService(db_session)
    # The matching service must refuse to return this corrupted record
    found = await svc.find_food_by_name("corrupt_toxic_berry")
    assert found is None
