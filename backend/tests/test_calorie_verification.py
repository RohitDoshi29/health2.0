"""Automated tests for the Calorie Verification Engine.

Covers:
1. Sources agree (tolerance <= 8% -> verified)
2. Moderate discrepancy (verified_with_warning)
3. Reliable source correction (corrected with original and final preserved)
4. No external source (macro consistency fallback + confidence scaling)
5. Impossible / Anomaly values (negative macros, extreme caloric density)
6. Large disagreement (needs_confirmation)
7. Packaged food priority (barcode/label nutrition priority)
8. Mixed dish ingredient decomposition (paneer butter masala, biryani)
"""

import pytest

from app.schemas.verification import VerificationStatus
from app.services.calorie_verification_service import (
    CalorieVerificationService,
    VerificationInput,
)


def test_scenario_1_sources_agree() -> None:
    """Test 1: DB = 465, Reference USDA = 468, Macro = 460 -> status: verified."""
    item = VerificationInput(
        food_name="Cooked White Rice & Chicken",
        detected_quantity=300.0,
        unit="g",
        grams=300.0,
        calories=465.0,
        protein=35.0,  # 35 * 4 = 140
        carbohydrates=60.0,  # 60 * 4 = 240
        fat=9.0,  # 9 * 9 = 81 -> total ~ 461 kcal
        fiber=2.0,
        nutrition_source="local_database",
        reference_usda_calories=468.0,
        is_matched_in_db=True,
    )

    result = CalorieVerificationService.verify(item)

    assert result.verification_status == VerificationStatus.VERIFIED
    assert result.original_calories == 465.0
    assert result.final_calories == 465.0
    assert "local_database" in result.verification_sources
    assert "usda_fdc" in result.verification_sources
    assert "macro_consistency" in result.verification_sources
    assert result.confidence_score >= 80.0


def test_scenario_2_moderate_discrepancy() -> None:
    """Test 2: DB = 450, Reference = 500 (~10-11% variance) -> status: verified_with_warning."""
    item = VerificationInput(
        food_name="Steamed Chicken Dumpling",
        detected_quantity=200.0,
        unit="g",
        grams=200.0,
        calories=450.0,
        protein=25.0,
        carbohydrates=50.0,
        fat=15.0,
        fiber=1.0,
        nutrition_source="local_database",
        reference_usda_calories=500.0,
        is_matched_in_db=True,
    )

    result = CalorieVerificationService.verify(item)

    assert result.verification_status == VerificationStatus.VERIFIED_WITH_WARNING
    assert result.discrepancy_percent > 8.0
    assert result.original_calories == 450.0


def test_scenario_3_reliable_source_correction() -> None:
    """Test 3: Local = 500, Trusted USDA Source = 410 (>15% variance) -> status: corrected."""
    item = VerificationInput(
        food_name="Grilled Salmon Fillet",
        detected_quantity=200.0,
        unit="g",
        grams=200.0,
        calories=500.0,
        protein=40.0,
        carbohydrates=0.0,
        fat=28.0,
        nutrition_source="local_database",
        reference_usda_calories=410.0,
        is_matched_in_db=True,
    )

    result = CalorieVerificationService.verify(item)

    assert result.verification_status == VerificationStatus.CORRECTED
    assert result.original_calories == 500.0
    assert result.final_calories == 410.0
    assert "usda_fdc" in result.verification_sources
    assert "Corrected using USDA reference standard" in result.verification_note


def test_scenario_4_no_external_source_unmatched_ai() -> None:
    """Test 4: Food not matched in reference database -> low_confidence with macro check."""
    item = VerificationInput(
        food_name="Mysterious Alien Snack",
        detected_quantity=100.0,
        unit="g",
        grams=100.0,
        calories=250.0,
        protein=10.0,
        carbohydrates=30.0,
        fat=10.0,
        nutrition_source="ai_estimate",
        is_matched_in_db=False,
    )

    result = CalorieVerificationService.verify(item)

    assert result.verification_status == VerificationStatus.LOW_CONFIDENCE
    assert result.confidence_score < 70.0
    assert "Food not found in reference database" in result.verification_note


def test_scenario_5_impossible_anomalies_rejected() -> None:
    """Test 5: Negative calories/macros or impossible density -> needs_confirmation."""
    # Subtest 5a: Negative calories
    item_neg = VerificationInput(
        food_name="Glitch Food",
        detected_quantity=100.0,
        unit="g",
        grams=100.0,
        calories=-50.0,
        protein=10.0,
        carbohydrates=20.0,
        fat=5.0,
        is_matched_in_db=True,
    )
    result_neg = CalorieVerificationService.verify(item_neg)
    assert result_neg.verification_status == VerificationStatus.NEEDS_CONFIRMATION
    assert "negative_calories" in result_neg.anomaly_flags

    # Subtest 5b: Impossible caloric density (> 9.0 kcal/g)
    item_dense = VerificationInput(
        food_name="Hyper-dense mystery cube",
        detected_quantity=100.0,
        unit="g",
        grams=100.0,
        calories=1500.0,  # 15 kcal/g is physically impossible in food
        protein=50.0,
        carbohydrates=100.0,
        fat=100.0,
        is_matched_in_db=True,
    )
    result_dense = CalorieVerificationService.verify(item_dense)
    assert result_dense.verification_status == VerificationStatus.NEEDS_CONFIRMATION
    assert "extreme_calorie_density" in result_dense.anomaly_flags


def test_scenario_6_large_disagreement_requires_confirmation() -> None:
    """Test 6: Discrepancy > 35% -> needs_confirmation instead of blind replacement."""
    item = VerificationInput(
        food_name="Ambiguous Rice Bowl",
        detected_quantity=200.0,
        unit="g",
        grams=200.0,
        calories=600.0,
        protein=4.0,
        carbohydrates=50.0,
        fat=2.0,
        nutrition_source="local_database",
        reference_usda_calories=260.0,  # Huge difference: 600 vs 260
        is_matched_in_db=True,
    )

    result = CalorieVerificationService.verify(item)

    assert result.verification_status == VerificationStatus.NEEDS_CONFIRMATION
    assert result.discrepancy_percent > 35.0
    assert "confirm portion" in result.verification_note.lower()


def test_scenario_7_packaged_food_barcode_priority() -> None:
    """Test 7: Packaged food with barcode/label nutrition takes precedence."""
    item = VerificationInput(
        food_name="Protein Yogurt Bar",
        detected_quantity=1.0,
        unit="piece",
        grams=60.0,
        calories=240.0,  # AI visual guess
        protein=15.0,
        carbohydrates=20.0,
        fat=8.0,
        nutrition_source="ai_estimate",
        barcode_calories=190.0,  # Exact barcode label
        is_matched_in_db=True,
    )

    result = CalorieVerificationService.verify(item)

    assert result.verification_status == VerificationStatus.CORRECTED
    assert result.final_calories == 190.0
    assert result.original_calories == 240.0
    assert "barcode_label" in result.verification_sources


def test_scenario_8_mixed_dish_ingredient_decomposition() -> None:
    """Test 8: Paneer Butter Masala uses ingredient decomposition to verify."""
    # 250g serving of Paneer Butter Masala
    # Decomposed recipe: paneer (75g), butter (20g), cream (25g), gravy (130g) -> ~470-520 kcal
    item = VerificationInput(
        food_name="Paneer Butter Masala",
        detected_quantity=1.0,
        unit="bowl",
        grams=250.0,
        calories=490.0,
        protein=18.0,
        carbohydrates=14.0,
        fat=38.0,
        nutrition_source="local_database",
        is_matched_in_db=True,
    )

    result = CalorieVerificationService.verify(item)

    assert "ingredient_decomposition" in result.verification_sources
    assert "ingredient_decomposition" in result.source_breakdown
    assert result.verification_status in (
        VerificationStatus.VERIFIED,
        VerificationStatus.VERIFIED_WITH_WARNING,
    )
    assert result.source_breakdown["ingredient_decomposition"] > 0
