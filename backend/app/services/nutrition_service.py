"""Nutrition mapping and calculation.

Maps a detected/entered food name to a Food record using fuzzy string
matching and scales that record's per-serving nutrition based on
quantity and culinary unit conversions.
"""

import re
import uuid
from dataclasses import dataclass

from rapidfuzz import fuzz, process
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.food import Food
from app.schemas.nutrition import NutritionSummary

# Configurable minimum similarity score (0-100) for fuzzy food-name matching.
FUZZY_MATCH_THRESHOLD: float = 80.0

# Basic synonym table for common short phrases/aliases.
_SYNONYMS: dict[str, str] = {
    "white rice": "cooked_white_rice",
    "cooked rice": "cooked_white_rice",
    "rice": "cooked_white_rice",
    "steamed rice": "cooked_white_rice",
    "basmati rice": "cooked_white_rice",
    "steamed basmati rice": "cooked_white_rice",
    "chicken": "chicken",
    "chicken curry": "chicken",
    "grilled chicken": "chicken",
    "dal": "dal",
    "lentils": "dal",
    "lentil curry": "dal",
    "roti": "roti",
    "chapati": "roti",
    "flatbread": "roti",
    "naan": "naan_bread",
    "garlic naan": "naan_bread",
    "butter naan": "naan_bread",
    "naan bread": "naan_bread",
    "apple": "apple",
    "banana": "banana",
    "egg": "egg",
    "boiled egg": "egg",
    "fried egg": "egg",
    "scrambled egg": "scrambled_eggs",
    "scrambled eggs": "scrambled_eggs",
    "french fries": "french_fries",
    "fries": "french_fries",
    "pizza": "cheese_pizza",
    "burger": "cheeseburger",
    "pasta": "cooked_pasta",
    "coffee": "coffee",
    "brewed coffee": "coffee",
    "black coffee": "coffee",
    "iced coffee": "iced_coffee",
    "cold coffee": "iced_coffee",
    "latte": "latte",
    "cappuccino": "cappuccino",
    "espresso": "espresso",
    "chocolate syrup": "chocolate_syrup",
}

# Average reference weight (in grams) for 1 whole piece/item of common foods.
_PIECE_WEIGHTS_GRAMS: dict[str, float] = {
    "apple": 182.0,
    "banana": 118.0,
    "egg": 50.0,
    "roti": 40.0,
    "naan_bread": 90.0,
    "chicken": 150.0,
    "cooked_white_rice": 150.0,
    "dal": 150.0,
    "coffee": 240.0,
    "black_coffee": 240.0,
    "iced_coffee": 240.0,
    "latte": 240.0,
    "cappuccino": 240.0,
    "espresso": 30.0,
}


def normalize_food_name(name: str) -> str:
    """Normalize a raw food name into a lookup key."""
    cleaned = re.sub(r"[^a-z0-9\s]", "", name.strip().lower())
    cleaned = re.sub(r"\s+", " ", cleaned).strip()

    if cleaned in _SYNONYMS:
        return _SYNONYMS[cleaned]

    return re.sub(r"\s+", "_", cleaned)


def convert_quantity_to_grams(food: Food, quantity: float, unit: str) -> float:
    """Convert an arbitrary quantity & unit into standard serving grams."""
    unit_clean = unit.strip().lower()

    if unit_clean in ("g", "gram", "grams", "ml", "milliliter", "milliliters"):
        return quantity

    if unit_clean in ("kg", "kilogram", "kilograms"):
        return quantity * 1000.0

    if unit_clean in ("oz", "ounce", "ounces"):
        return quantity * 28.3495

    if unit_clean in ("cup", "cups"):
        return quantity * 240.0

    if unit_clean in ("bowl", "bowls"):
        return quantity * 350.0

    if unit_clean in ("tbsp", "tablespoon", "tablespoons"):
        return quantity * 15.0

    if unit_clean in ("tsp", "teaspoon", "teaspoons"):
        return quantity * 5.0

    if unit_clean in ("slice", "slices"):
        return quantity * 35.0

    if unit_clean in ("serving", "servings"):
        return quantity * (food.serving_size or 100.0)

    if unit_clean in ("plate", "plates"):
        return quantity * 350.0

    if unit_clean in ("glass", "glasses"):
        return quantity * 250.0

    if unit_clean in ("piece", "pieces", "item", "items", "whole"):
        canonical = food.canonical_name.lower()
        if canonical in _PIECE_WEIGHTS_GRAMS:
            return quantity * _PIECE_WEIGHTS_GRAMS[canonical]
        for key, weight in _PIECE_WEIGHTS_GRAMS.items():
            if key in canonical or key in food.name.lower():
                return quantity * weight
        return quantity * (food.serving_size or 100.0)

    # Fallback to direct quantity if unrecognized
    return quantity


@dataclass
class NutritionResult:
    """Nutrition calculated for one item, plus the Food record it matched (if any)."""

    matched_food: Food | None
    calories: float
    protein: float
    carbohydrates: float
    fat: float
    fiber: float

    @property
    def matched(self) -> bool:
        """True if this result was matched to a reference Food record in the database."""
        return self.matched_food is not None



class NutritionService:
    """Nutrition lookup + calculation against the local Food table with fuzzy matching."""

    def __init__(self, db: AsyncSession) -> None:
        self.db = db

    async def find_food_by_name(
        self, name: str, min_fuzzy_score: float | None = None
    ) -> Food | None:
        """Look up a Food record by name using a three-tier matching pipeline:

        Tier 1 (Synonym): Fast dictionary lookup in _SYNONYMS to map common aliases
        (e.g., 'white rice' -> 'cooked_white_rice') directly to canonical names.
        Tier 2 (Exact): Exact database query by Food.canonical_name or case-insensitive
        Food.name. Cheaper and fully deterministic.
        Tier 3 (Fuzzy): Fallback matching using rapidfuzz against both Food.name and
        Food.canonical_name (plus canonical synonyms) above FUZZY_MATCH_THRESHOLD (80).
        """
        if not name or not name.strip():
            return None

        threshold = min_fuzzy_score if min_fuzzy_score is not None else FUZZY_MATCH_THRESHOLD
        query_raw = name.strip()
        canonical = normalize_food_name(query_raw)

        # Tier 1 & 2: Exact canonical name match (including normalized synonyms)
        result = await self.db.execute(select(Food).where(Food.canonical_name == canonical))
        food = result.scalar_one_or_none()
        if food is not None:
            return food

        # Tier 2: Case-insensitive exact name match
        result = await self.db.execute(select(Food).where(Food.name.ilike(query_raw)))
        food = result.scalar_one_or_none()
        if food is not None:
            return food

        # Tier 3: Fuzzy matching fallback across database foods
        all_foods_res = await self.db.execute(select(Food))
        all_foods = list(all_foods_res.scalars().all())
        if not all_foods:
            return None

        # Build candidate search dictionary mapping name variations to Food entities
        choices: dict[str, Food] = {}
        for f in all_foods:
            choices[f.name.lower()] = f
            choices[f.canonical_name.replace("_", " ").lower()] = f
            choices[f.canonical_name.lower()] = f
            # Include synonym phrases that point to this canonical name
            for syn, syn_canonical in _SYNONYMS.items():
                if syn_canonical == f.canonical_name:
                    choices[syn.lower()] = f

        query_lower = query_raw.lower()
        match = process.extractOne(
            query_lower,
            list(choices.keys()),
            scorer=fuzz.token_set_ratio,
            score_cutoff=threshold,
        )

        if match is not None:
            best_match_key, _score, _ = match
            return choices[best_match_key]

        return None

    async def get_food_by_id(self, food_id: uuid.UUID) -> Food | None:
        result = await self.db.execute(select(Food).where(Food.id == food_id))
        return result.scalar_one_or_none()

    async def search_foods(self, query: str, limit: int = 20) -> list[Food]:
        result = await self.db.execute(
            select(Food).where(Food.name.ilike(f"%{query.strip()}%")).limit(limit)
        )
        return list(result.scalars().all())

    async def list_foods(self, limit: int = 100, offset: int = 0) -> list[Food]:
        result = await self.db.execute(select(Food).offset(offset).limit(limit))
        return list(result.scalars().all())

    @staticmethod
    def calculate_nutrition_for_quantity(
        food: Food, quantity: float, unit: str = "g"
    ) -> NutritionResult:
        """Scale a Food's per-serving nutrition with unit conversion."""
        grams = convert_quantity_to_grams(food, quantity, unit)
        ratio = grams / food.serving_size if food.serving_size else 0.0

        return NutritionResult(
            matched_food=food,
            calories=round(food.calories * ratio, 2),
            protein=round(food.protein * ratio, 2),
            carbohydrates=round(food.carbohydrates * ratio, 2),
            fat=round(food.fat * ratio, 2),
            fiber=round(food.fiber * ratio, 2),
        )

    async def calculate_for_detection(
        self, name: str, quantity: float, unit: str = "g"
    ) -> NutritionResult:
        """Find a matching food via fuzzy search and calculate scaled nutrition."""
        food = await self.find_food_by_name(name)
        if food is None:
            return NutritionResult(
                matched_food=None, calories=0.0, protein=0.0, carbohydrates=0.0, fat=0.0, fiber=0.0
            )
        return self.calculate_nutrition_for_quantity(food, quantity, unit=unit)

    @staticmethod
    def sum_totals(results: list[NutritionResult]) -> NutritionSummary:
        return NutritionSummary(
            estimated_calories=round(sum(r.calories for r in results), 2),
            protein=round(sum(r.protein for r in results), 2),
            carbohydrates=round(sum(r.carbohydrates for r in results), 2),
            fat=round(sum(r.fat for r in results), 2),
            fiber=round(sum(r.fiber for r in results), 2),
        )
