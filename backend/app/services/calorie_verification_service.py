"""Calorie Verification Engine.

Performs multi-source corroboration, independent macro consistency checking
(Atwater 4-9-4 rule), ingredient decomposition for mixed dishes, strict biological
anomaly detection, and source-priority resolution to deliver transparent, calibrated,
and physically plausible caloric estimations.
"""

from dataclasses import dataclass
import logging
from typing import Any

from app.schemas.verification import (
    ConfidenceBreakdown,
    VerificationDetail,
    VerificationStatus,
)

logger = logging.getLogger(__name__)

# Ingredient decomposition recipes for common mixed dishes
COMPOSITE_DISH_RECIPES: dict[str, list[dict[str, Any]]] = {
    "paneer butter masala": [
        {"ingredient": "paneer", "grams": 30.0, "cals_per_100g": 296.0},
        {"ingredient": "butter", "grams": 8.0, "cals_per_100g": 717.0},
        {"ingredient": "cream", "grams": 10.0, "cals_per_100g": 340.0},
        {"ingredient": "tomato onion gravy", "grams": 52.0, "cals_per_100g": 65.0},
    ],
    "pav bhaji": [
        {"ingredient": "mashed vegetable bhaji", "grams": 70.0, "cals_per_100g": 115.0},
        {"ingredient": "butter", "grams": 10.0, "cals_per_100g": 717.0},
        {"ingredient": "pav bread", "grams": 20.0, "cals_per_100g": 265.0},
    ],
    "biryani": [
        {"ingredient": "cooked basmati rice", "grams": 65.0, "cals_per_100g": 130.0},
        {"ingredient": "chicken / protein", "grams": 25.0, "cals_per_100g": 165.0},
        {"ingredient": "ghee / oil", "grams": 5.0, "cals_per_100g": 884.0},
        {"ingredient": "spices and yogurt", "grams": 5.0, "cals_per_100g": 60.0},
    ],
    "poha": [
        {"ingredient": "flattened rice (cooked)", "grams": 70.0, "cals_per_100g": 130.0},
        {"ingredient": "roasted peanuts", "grams": 10.0, "cals_per_100g": 567.0},
        {"ingredient": "potato and onion", "grams": 15.0, "cals_per_100g": 77.0},
        {"ingredient": "oil", "grams": 5.0, "cals_per_100g": 884.0},
    ],
    "upma": [
        {"ingredient": "cooked semolina / rava", "grams": 80.0, "cals_per_100g": 120.0},
        {"ingredient": "vegetables", "grams": 12.0, "cals_per_100g": 45.0},
        {"ingredient": "ghee / oil", "grams": 8.0, "cals_per_100g": 884.0},
    ],
    "misal pav": [
        {"ingredient": "sprouted moth usal & rassa", "grams": 70.0, "cals_per_100g": 110.0},
        {"ingredient": "farsan / sev", "grams": 15.0, "cals_per_100g": 520.0},
        {"ingredient": "pav bread", "grams": 15.0, "cals_per_100g": 265.0},
    ],
    "cheese pizza": [
        {"ingredient": "pizza crust", "grams": 50.0, "cals_per_100g": 270.0},
        {"ingredient": "mozzarella cheese", "grams": 30.0, "cals_per_100g": 300.0},
        {"ingredient": "tomato pizza sauce", "grams": 20.0, "cals_per_100g": 45.0},
    ],
    "cheeseburger": [
        {"ingredient": "burger bun", "grams": 40.0, "cals_per_100g": 275.0},
        {"ingredient": "cooked patty", "grams": 40.0, "cals_per_100g": 250.0},
        {"ingredient": "cheddar cheese slice", "grams": 12.0, "cals_per_100g": 402.0},
        {"ingredient": "sauce & lettuce", "grams": 8.0, "cals_per_100g": 80.0},
    ],
}


@dataclass
class VerificationInput:
    """Input payload for the Calorie Verification Service."""

    food_name: str
    detected_quantity: float
    unit: str
    grams: float
    calories: float
    protein: float
    carbohydrates: float
    fat: float
    fiber: float = 0.0
    nutrition_source: str = "local_database"
    food_category: str | None = None
    food_confidence: float = 0.8
    portion_confidence: float | None = None
    barcode_calories: float | None = None
    reference_usda_calories: float | None = None
    is_matched_in_db: bool = True
    is_component: bool = False
    parent_food: str | None = None


class CalorieVerificationService:
    """Verifies food items, evaluates multi-source consensus, and enforces macro physics."""

    @staticmethod
    def calculate_macro_calories(
        protein: float, carbohydrates: float, fat: float, fiber: float = 0.0
    ) -> float:
        """Independently calculate calories from macronutrients via Atwater general factors.

        Protein: 4 kcal/g
        Carbohydrates (digestible): 4 kcal/g
        Fat: 9 kcal/g
        Fiber: 2 kcal/g (insoluble/partially fermented fiber contribution)
        """
        digestible_carbs = max(0.0, carbohydrates - fiber)
        macro_cals = (protein * 4.0) + (digestible_carbs * 4.0) + (fiber * 2.0) + (fat * 9.0)
        return round(macro_cals, 2)

    @classmethod
    def decompose_ingredients_calories(
        cls, food_name: str, total_grams: float
    ) -> tuple[float | None, list[str]]:
        """Compute expected calories by summing known ingredient decomposition."""
        canonical = food_name.strip().lower()

        recipe: list[dict[str, Any]] | None = None
        for key, rec in COMPOSITE_DISH_RECIPES.items():
            if key in canonical or canonical in key:
                recipe = rec
                break

        if not recipe or total_grams <= 0:
            return None, ["ingredient_data_unavailable"]

        total_recipe_cals = 0.0
        recipe_grams = sum(item["grams"] for item in recipe)

        for item in recipe:
            scaled_grams = (item["grams"] / recipe_grams) * total_grams
            total_recipe_cals += (scaled_grams / 100.0) * item["cals_per_100g"]

        return round(total_recipe_cals, 2), ["ingredient_decomposition"]

    @classmethod
    def detect_anomalies(
        cls,
        calories: float,
        protein: float,
        carbohydrates: float,
        fat: float,
        fiber: float,
        grams: float,
    ) -> list[str]:
        """Detect physically impossible or physiologically implausible values.

        Enforces Checks A through F:
        Check A: No negative calories or macronutrients.
        Check B: Macronutrient mass cannot exceed total physical food weight (+5% tolerance).
        Check C: Discrepancy between reported calories and independent macro-derived calories.
        Check D: Caloric density cannot exceed the physical energy density of pure fat (9.5 kcal/g).
        Check E: Protein mass cannot exceed physical food weight (+2% tolerance).
        Check F: Plausibility bounds for single meal portions.
        """
        anomalies: list[str] = []

        # Check A: Negative values
        if calories < 0.0:
            anomalies.append("negative_calories")
        if protein < 0.0 or carbohydrates < 0.0 or fat < 0.0 or fiber < 0.0:
            anomalies.append("negative_macronutrients")

        if grams > 0:
            # Check B: Macro mass vs physical weight
            digestible_carbs = max(0.0, carbohydrates - fiber)
            total_macro_mass = protein + digestible_carbs + fat + fiber
            if total_macro_mass > (grams * 1.05) and grams > 5.0:
                anomalies.append("macronutrient_mass_exceeds_weight")

            # Check D: Caloric density limit (fat is ~9.0 kcal/g; normal food <= 9.5 kcal/g)
            caloric_density = calories / grams
            if caloric_density > 9.5:
                anomalies.append("extreme_calorie_density")

            # Check E: Protein mass cannot exceed food weight
            if protein > (grams * 1.02) and grams > 5.0:
                anomalies.append("protein_exceeds_weight")

        # Check F: Single portion plausibility threshold (flag suspicious extreme single items)
        if calories > 3500.0:
            anomalies.append("excessive_single_item_calories")
        if protein > 200.0:
            anomalies.append("excessive_single_item_protein")

        return anomalies

    @classmethod
    def compute_confidences(
        cls,
        food_confidence_raw: float,
        portion_confidence_raw: float | None,
        unit: str,
        is_matched_in_db: bool,
        has_barcode_or_usda: bool,
        discrepancy_pct: float,
        has_anomalies: bool = False,
        is_zero_nutrition: bool = False,
    ) -> ConfidenceBreakdown:
        """Calculate 3-part confidence scores (0-100 scale)."""
        # If critical anomalies are present, confidences collapse
        if has_anomalies:
            return ConfidenceBreakdown(
                food_confidence=round(food_confidence_raw * 100.0, 1),
                portion_confidence=15.0,
                nutrition_confidence=10.0,
                overall_confidence=15.0,
            )

        # 1. Food identification confidence
        food_conf = max(0.0, min(100.0, food_confidence_raw * 100.0))

        # 2. Portion confidence: precise metric units (g, ml) are high confidence;
        # ambiguous units have lower confidence.
        if portion_confidence_raw is not None:
            portion_conf = max(0.0, min(100.0, portion_confidence_raw * 100.0))
        else:
            unit_clean = unit.strip().lower()
            if unit_clean in ("g", "gram", "grams", "ml"):
                portion_conf = 95.0
            elif unit_clean in ("slice", "cup", "tbsp", "tsp"):
                portion_conf = 85.0
            elif unit_clean in ("piece", "item"):
                portion_conf = 75.0
            elif unit_clean in ("bowl", "plate"):
                portion_conf = 70.0
            else:
                portion_conf = 60.0

        # 3. Nutrition data confidence
        if has_barcode_or_usda:
            base_nutri = 95.0
        elif is_matched_in_db:
            base_nutri = 85.0
        elif is_zero_nutrition:
            base_nutri = 5.0
        else:
            base_nutri = 35.0

        penalty = min(35.0, discrepancy_pct * 0.7)
        nutrition_conf = max(5.0, min(100.0, base_nutri - penalty))

        overall = (food_conf * 0.40) + (portion_conf * 0.30) + (nutrition_conf * 0.30)

        # Unmatched food is capped at moderate-low confidence
        if not is_matched_in_db and not has_barcode_or_usda:
            if is_zero_nutrition:
                overall = min(35.0, overall)
            else:
                overall = min(65.0, overall)

        return ConfidenceBreakdown(
            food_confidence=round(food_conf, 1),
            portion_confidence=round(portion_conf, 1),
            nutrition_confidence=round(nutrition_conf, 1),
            overall_confidence=round(overall, 1),
        )

    @classmethod
    def verify(cls, item: VerificationInput) -> VerificationDetail:
        """Run full multi-source verification and safety gates for a food item."""
        anomalies = cls.detect_anomalies(
            calories=item.calories,
            protein=item.protein,
            carbohydrates=item.carbohydrates,
            fat=item.fat,
            fiber=item.fiber,
            grams=item.grams,
        )

        macro_cals = cls.calculate_macro_calories(
            protein=item.protein,
            carbohydrates=item.carbohydrates,
            fat=item.fat,
            fiber=item.fiber,
        )

        sources_consulted: list[str] = [item.nutrition_source]
        source_breakdown: dict[str, float] = {item.nutrition_source: item.calories}

        # Add macro consistency calculation as an independent validation source
        if item.calories > 0 and (item.protein > 0 or item.carbohydrates > 0 or item.fat > 0):
            sources_consulted.append("macro_consistency")
            source_breakdown["macro_consistency"] = macro_cals

        # Check external reference sources
        if item.reference_usda_calories is not None:
            sources_consulted.append("usda_fdc")
            source_breakdown["usda_fdc"] = item.reference_usda_calories

        if item.barcode_calories is not None:
            sources_consulted.append("barcode_label")
            source_breakdown["barcode_label"] = item.barcode_calories

        # Check ingredient decomposition for composite dishes
        decomp_cals, decomp_sources = cls.decompose_ingredients_calories(
            item.food_name, item.grams
        )
        if decomp_cals is not None:
            sources_consulted.extend(decomp_sources)
            source_breakdown["ingredient_decomposition"] = decomp_cals

        original_cals = item.calories
        final_cals = original_cals
        discrepancy_pct = 0.0
        note = "Nutrition values are consistent across available sources."
        status = VerificationStatus.VERIFIED

        # Component / Topping handling (Anti-Double-Counting)
        if item.is_component:
            status = VerificationStatus.VERIFIED
            parent_name = item.parent_food or "composite dish"
            note = f"Topping/ingredient included in {parent_name}. Calories accounted for in parent dish."
            confidence_breakdown = cls.compute_confidences(
                food_confidence_raw=item.food_confidence,
                portion_confidence_raw=item.portion_confidence,
                unit=item.unit,
                is_matched_in_db=item.is_matched_in_db,
                has_barcode_or_usda=False,
                discrepancy_pct=0.0,
            )
            return VerificationDetail(
                final_calories=0.0,
                original_calories=round(original_cals, 2),
                macro_derived_calories=0.0,
                verification_status=status,
                confidence_score=confidence_breakdown.overall_confidence,
                confidence_breakdown=confidence_breakdown,
                verification_sources=sources_consulted,
                source_breakdown=source_breakdown,
                discrepancy_percent=0.0,
                verification_note=note,
                anomaly_flags=[],
            )

        # 1. Hard failure on biological / physical anomalies (negative macros, macro mass > grams, etc.)
        if anomalies:
            status = VerificationStatus.NEEDS_CONFIRMATION
            note = (
                f"Critical physical anomaly detected ({', '.join(anomalies)}). "
                "Values are physically impossible or inconsistent. Please confirm portion."
            )
            discrepancy_pct = 100.0

        # 2. Unmatched food handling
        elif not item.is_matched_in_db and item.barcode_calories is None and item.reference_usda_calories is None:
            status = VerificationStatus.LOW_CONFIDENCE
            note = (
                "Food not found in reference database. "
                "Values are estimated from AI and macro modeling. Please confirm portion."
            )
            if macro_cals > 0 and original_cals > 0:
                discrepancy_pct = round(
                    abs(original_cals - macro_cals) / max(original_cals, 1.0) * 100.0, 1
                )
            else:
                discrepancy_pct = 0.0

        # 3. Barcode/Nutrition Label takes highest priority
        elif item.barcode_calories is not None:
            trusted_val = item.barcode_calories
            diff_pct = abs(original_cals - trusted_val) / max(trusted_val, 1.0) * 100.0
            discrepancy_pct = round(diff_pct, 1)

            if diff_pct > 12.0:
                status = VerificationStatus.CORRECTED
                final_cals = trusted_val
                note = (
                    f"Adjusted to verified barcode label ({trusted_val} kcal, "
                    f"{discrepancy_pct}% difference from visual estimate)."
                )
            else:
                status = VerificationStatus.VERIFIED
                final_cals = trusted_val
                note = "Verified against packaged product barcode nutrition label."

        # 4. USDA external reference check
        elif item.reference_usda_calories is not None:
            trusted_val = item.reference_usda_calories
            diff_pct = abs(original_cals - trusted_val) / max(trusted_val, 1.0) * 100.0
            discrepancy_pct = round(diff_pct, 1)

            if diff_pct > 35.0:
                status = VerificationStatus.NEEDS_CONFIRMATION
                note = (
                    f"Significant divergence ({discrepancy_pct}%) between database and USDA reference "
                    f"({original_cals} vs {trusted_val} kcal). Please confirm portion."
                )
            elif diff_pct > 15.0:
                status = VerificationStatus.CORRECTED
                final_cals = trusted_val
                note = f"Corrected using USDA reference standard ({trusted_val} kcal)."
            elif diff_pct > 8.0:
                status = VerificationStatus.VERIFIED_WITH_WARNING
                note = f"Verified with moderate variance ({discrepancy_pct}%) against USDA reference."
            else:
                status = VerificationStatus.VERIFIED
                note = "Verified against USDA FoodData Central reference standard."

        # 5. Ingredient decomposition for mixed dishes
        elif decomp_cals is not None:
            diff_pct = abs(original_cals - decomp_cals) / max(decomp_cals, 1.0) * 100.0
            discrepancy_pct = round(diff_pct, 1)

            if diff_pct > 35.0:
                status = VerificationStatus.NEEDS_CONFIRMATION
                note = (
                    f"Discrepancy ({discrepancy_pct}%) between composite dish estimate and "
                    f"ingredient sum ({original_cals} vs {decomp_cals} kcal). Please confirm portion."
                )
            elif diff_pct > 15.0:
                status = VerificationStatus.VERIFIED_WITH_WARNING
                note = (
                    f"Ingredient recipe sum ({decomp_cals} kcal) has {discrepancy_pct}% variance "
                    "from standard database serving."
                )
            else:
                status = VerificationStatus.VERIFIED
                note = "Verified against culinary ingredient breakdown."

        # 6. Standard local database + Atwater macro consistency check
        else:
            if original_cals > 0 and macro_cals > 0:
                diff_pct = abs(original_cals - macro_cals) / max(original_cals, 1.0) * 100.0
                discrepancy_pct = round(diff_pct, 1)

                if diff_pct > 35.0:
                    status = VerificationStatus.NEEDS_CONFIRMATION
                    note = (
                        f"Macro consistency discrepancy is high ({discrepancy_pct}%). "
                        "Reported calories diverge from physical macronutrient calculation. Please confirm portion."
                    )
                    anomalies.append("macro_consistency_discrepancy")
                elif diff_pct > 15.0:
                    status = VerificationStatus.VERIFIED_WITH_WARNING
                    note = (
                        f"Calories verified with {discrepancy_pct}% variance against "
                        "macronutrient totals."
                    )
                else:
                    status = VerificationStatus.VERIFIED
                    note = "Verified against local reference database and macro consistency."
            else:
                status = VerificationStatus.VERIFIED
                discrepancy_pct = 0.0

        confidence_breakdown = cls.compute_confidences(
            food_confidence_raw=item.food_confidence,
            portion_confidence_raw=item.portion_confidence,
            unit=item.unit,
            is_matched_in_db=item.is_matched_in_db,
            has_barcode_or_usda=(item.barcode_calories is not None or item.reference_usda_calories is not None),
            discrepancy_pct=discrepancy_pct,
            has_anomalies=bool(anomalies),
            is_zero_nutrition=(item.calories == 0.0 and item.protein == 0.0),
        )

        return VerificationDetail(
            final_calories=max(0.0, round(final_cals, 2)),
            original_calories=round(original_cals, 2),
            macro_derived_calories=max(0.0, macro_cals),
            verification_status=status,
            confidence_score=confidence_breakdown.overall_confidence,
            confidence_breakdown=confidence_breakdown,
            verification_sources=sources_consulted,
            source_breakdown=source_breakdown,
            discrepancy_percent=discrepancy_pct,
            verification_note=note,
            anomaly_flags=anomalies,
        )

    @classmethod
    def validate_final_meal(
        cls, items: list[Any], total: Any
    ) -> tuple[VerificationStatus, list[str]]:
        """Run a final safety validation gate on the aggregated meal response."""
        warnings: list[str] = []
        overall_status = VerificationStatus.VERIFIED

        # Check total values
        if total.estimated_calories < 0.0 or total.protein < 0.0 or total.carbohydrates < 0.0 or total.fat < 0.0:
            warnings.append("Total meal contains negative nutrient values.")
            overall_status = VerificationStatus.NEEDS_CONFIRMATION

        # Total macro consistency check
        total_macro_cals = cls.calculate_macro_calories(
            total.protein, total.carbohydrates, total.fat, total.fiber
        )
        if total.estimated_calories > 20.0 and total_macro_cals > 0.0:
            diff = abs(total.estimated_calories - total_macro_cals) / total.estimated_calories * 100.0
            if diff > 35.0:
                warnings.append(
                    f"Overall meal calories diverge from total macronutrient calories by {diff:.1f}%."
                )
                overall_status = VerificationStatus.NEEDS_CONFIRMATION

        # If any non-component item has NEEDS_CONFIRMATION or critical anomalies
        for item in items:
            v = getattr(item, "verification", None)
            if v:
                if v.verification_status == VerificationStatus.NEEDS_CONFIRMATION and not getattr(item, "is_component", False):
                    overall_status = VerificationStatus.NEEDS_CONFIRMATION
                    warnings.append(f"Item '{item.name}' requires portion/nutrition confirmation.")
                elif v.verification_status == VerificationStatus.VERIFIED_WITH_WARNING and overall_status == VerificationStatus.VERIFIED:
                    overall_status = VerificationStatus.VERIFIED_WITH_WARNING

        return overall_status, warnings
