"""Nutrition mapping and calculation.

Maps a detected/entered food name to a Food record using a strict multi-tier
matching pipeline and scales that record's per-serving nutrition based on
quantity and food-specific culinary unit conversions.
"""

from dataclasses import dataclass
import logging
import re
import uuid

from rapidfuzz import fuzz, process
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.food import Food
from app.schemas.nutrition import NutritionSummary

logger = logging.getLogger(__name__)

# Configurable minimum similarity score (0-100) for fuzzy food-name matching.
FUZZY_MATCH_THRESHOLD: float = 85.0

# Keywords denoting composite dishes — matching an ingredient to a composite dish
# or vice-versa is strictly guarded to prevent false matches (e.g. paneer pizza -> paneer).
COMPOSITE_DISH_KEYWORDS: set[str] = {
    "pizza",
    "burger",
    "sandwich",
    "biryani",
    "curry",
    "pasta",
    "roll",
    "wrap",
    "salad",
    "soup",
    "taco",
    "burrito",
    "noodles",
    "fried_rice",
    "fried rice",
    "poha",
    "upma",
    "khichdi",
    "dosa",
}

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
    "cheese pizza": "cheese_pizza",
    "pizza slice": "cheese_pizza",
    "paneer pizza": "cheese_pizza",
    "veggie pizza": "cheese_pizza",
    "veg pizza": "cheese_pizza",
    "margherita pizza": "cheese_pizza",
    "pepperoni pizza": "cheese_pizza",
    "pepper pizza": "cheese_pizza",
    "capsicum pizza": "cheese_pizza",
    "burger": "cheeseburger",
    "cheeseburger": "cheeseburger",
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
    "paneer": "paneer",
    "cottage cheese": "cottage_cheese",
    "bell pepper": "green_bell_pepper",
    "green bell pepper": "green_bell_pepper",
    "red bell pepper": "red_bell_pepper",
    "capsicum": "green_bell_pepper",
    "pepper": "green_bell_pepper",
    "olives": "black_olives",
    "black olives": "black_olives",
}

# Average reference weight (in grams) for 1 slice of food.
_SLICE_WEIGHTS_GRAMS: dict[str, float] = {
    "pizza": 115.0,
    "cheese_pizza": 115.0,
    "pepperoni_pizza": 120.0,
    "bread": 35.0,
    "white_bread": 35.0,
    "whole_wheat_bread": 35.0,
    "toast": 35.0,
    "cheese": 21.0,
    "cheddar_cheese": 21.0,
    "swiss_cheese": 21.0,
    "mozzarella_cheese": 21.0,
    "cake": 90.0,
    "pie": 120.0,
    "watermelon": 280.0,
    "tomato": 20.0,
    "cucumber": 10.0,
    "onion": 15.0,
}

# Average reference weight (in grams) for 1 whole piece/item of common foods.
_PIECE_WEIGHTS_GRAMS: dict[str, float] = {
    # Proteins & dairy
    "paneer": 15.0,  # 1 standard cube of paneer is ~12-15g
    "tofu": 18.0,
    "egg": 50.0,
    "boiled_egg": 50.0,
    "fried_egg": 50.0,
    "chicken": 150.0,
    "cooked_chicken": 150.0,
    "chicken_breast": 170.0,
    "chicken_thigh": 110.0,
    "chicken_wing": 45.0,
    # Breads & staples
    "roti": 40.0,
    "chapati": 40.0,
    "flatbread": 40.0,
    "paratha": 75.0,
    "puri": 25.0,
    "bhatura": 60.0,
    "naan_bread": 90.0,
    "naan": 90.0,
    "idli": 45.0,
    "dosa": 100.0,
    "vada": 50.0,
    "samosa": 80.0,
    "cooked_white_rice": 150.0,
    "dal": 150.0,
    # Fruits
    "apple": 182.0,
    "banana": 118.0,
    "orange": 131.0,
    "grape": 5.0,
    "strawberry": 12.0,
    # Nuts, toppings, garnishes
    "olive": 4.0,
    "olives": 4.0,
    "black_olives": 4.0,
    "almond": 1.2,
    "walnut": 2.5,
    "cashew": 1.5,
    "peanut": 0.8,
    "garlic": 3.0,
    "mushroom": 15.0,
    "green_bell_pepper": 120.0,
    "red_bell_pepper": 120.0,
    "pepper": 20.0,
    "cookie": 15.0,
    "biscuit": 15.0,
    "cheeseburger": 180.0,
    "burger": 180.0,
    "pizza": 450.0,
    "coffee": 240.0,
    "black_coffee": 240.0,
    "iced_coffee": 240.0,
    "latte": 240.0,
    "cappuccino": 240.0,
    "espresso": 30.0,
}

_BOWL_WEIGHTS_GRAMS: dict[str, float] = {
    "dal": 350.0,
    "cooked_white_rice": 200.0,
    "vegetable_curry": 220.0,
    "soup": 240.0,
    "salad": 120.0,
    "poha": 180.0,
    "upma": 180.0,
}

_PLATE_WEIGHTS_GRAMS: dict[str, float] = {
    "cooked_white_rice": 250.0,
    "biryani": 300.0,
    "pav_bhaji": 300.0,
    "poha": 200.0,
}


def normalize_food_name(name: str) -> str:
    """Normalize a raw food name into a lookup key."""
    cleaned = re.sub(r"[^a-z0-9\s]", "", name.strip().lower())
    cleaned = re.sub(r"\s+", " ", cleaned).strip()

    if cleaned in _SYNONYMS:
        return _SYNONYMS[cleaned]

    return re.sub(r"\s+", "_", cleaned)


# Reference per-food portion weights (in grams) for common culinary units.
_PER_FOOD_PORTIONS_GRAMS: dict[tuple[str, str], float] = {
    # Dal & curries
    ("dal", "katori"): 150.0,
    ("curd", "katori"): 150.0,
    ("curd", "bowl"): 150.0,
    ("curd", "cup"): 150.0,
    # Rice
    ("cooked_white_rice", "katori"): 150.0,
    ("cooked_white_rice", "plate"): 250.0,
    ("white_rice", "katori"): 150.0,
    ("rice", "katori"): 150.0,
    # Breads
    ("roti", "piece"): 40.0,
    ("roti", "roti"): 40.0,
    ("roti", "chapati"): 40.0,
    ("chapati", "piece"): 40.0,
    ("chapati", "roti"): 40.0,
    ("chapati", "chapati"): 40.0,
    ("paratha", "piece"): 80.0,
    ("paratha", "paratha"): 80.0,
    ("naan_bread", "piece"): 90.0,
    ("bread", "slice"): 35.0,
    # Pizza
    ("cheese_pizza", "slice"): 115.0,
    ("pepperoni_pizza", "slice"): 120.0,
    ("pizza", "slice"): 100.0,
    # South Indian
    ("idli", "piece"): 50.0,
    ("idli", "idli"): 50.0,
    ("dosa", "piece"): 100.0,
    ("dosa", "dosa"): 100.0,
    # Eggs & dairy
    ("egg", "piece"): 50.0,
    ("egg", "egg"): 50.0,
    ("boiled_egg", "piece"): 50.0,
    ("fried_egg", "piece"): 50.0,
    ("paneer", "cube"): 15.0,
    ("paneer", "piece"): 15.0,
    ("ghee", "tbsp"): 15.0,
    ("ghee", "tablespoon"): 15.0,
    ("ghee", "tsp"): 5.0,
    ("ghee", "teaspoon"): 5.0,
    # Beverages
    ("milk", "glass"): 240.0,
    ("milk", "cup"): 240.0,
    ("coffee", "cup"): 240.0,
    ("tea", "cup"): 150.0,
    # Snacks & entrees
    ("samosa", "piece"): 75.0,
    ("samosa", "samosa"): 75.0,
    ("cheeseburger", "burger"): 180.0,
    ("cheeseburger", "piece"): 180.0,
    ("cooked_chicken", "piece"): 150.0,
    ("chicken", "piece"): 150.0,
    ("salad", "bowl"): 120.0,
    ("soup", "bowl"): 240.0,
}


def convert_quantity_to_grams(food: Food | None, quantity: float, unit: str) -> float:
    """Convert an arbitrary quantity & unit into standard serving grams.

    Priority:
    1. Explicit metric weight/volume (g, ml, kg, oz)
    2. Food-specific portion weights (_PER_FOOD_PORTIONS_GRAMS, _SLICE_WEIGHTS_GRAMS, etc.)
    3. Food database serving size (if serving_unit aligns)
    4. Conservative generic fallback (katori=150g, roti=40g, idli=50g, dosa=100g, etc.)

    Physical Sanity:
    - Any single item is capped at 1,200 g to prevent unrealistic runaway calorie explosions.
    """
    if quantity <= 0.0:
        return 0.0

    unit_clean = unit.strip().lower()

    if unit_clean in ("g", "gram", "grams", "ml", "milliliter", "milliliters"):
        return round(min(quantity, 1200.0), 2)

    if unit_clean in ("kg", "kilogram", "kilograms"):
        return round(min(quantity * 1000.0, 1200.0), 2)

    if unit_clean in ("oz", "ounce", "ounces"):
        return round(min(quantity * 28.3495, 1200.0), 2)

    canonical = food.canonical_name.lower() if food else ""
    food_name = food.name.lower() if food else ""

    # Check high-priority food-specific portion guide dictionary
    for (f_key, u_key), p_grams in _PER_FOOD_PORTIONS_GRAMS.items():
        if (f_key == canonical or f_key in canonical or f_key in food_name) and (
            u_key == unit_clean or u_key in unit_clean
        ):
            return round(min(quantity * p_grams, 1200.0), 2)

    # Specific Indian culinary units fallback
    if unit_clean in ("katori", "katoris"):
        return round(min(quantity * 150.0, 1200.0), 2)

    if unit_clean in ("roti", "rotis", "chapati", "chapatis"):
        return round(min(quantity * 40.0, 1200.0), 2)

    if unit_clean in ("idli", "idlis"):
        return round(min(quantity * 50.0, 1200.0), 2)

    if unit_clean in ("dosa", "dosas"):
        return round(min(quantity * 100.0, 1200.0), 2)

    if unit_clean in ("glass", "glasses"):
        return round(min(quantity * 240.0, 1200.0), 2)

    if unit_clean in ("slice", "slices"):
        for key, weight in _SLICE_WEIGHTS_GRAMS.items():
            if key in canonical or key in food_name:
                return round(min(quantity * weight, 1200.0), 2)
        return round(min(quantity * 35.0, 1200.0), 2)

    if unit_clean in ("piece", "pieces", "item", "items", "whole"):
        if canonical in _PIECE_WEIGHTS_GRAMS:
            return round(min(quantity * _PIECE_WEIGHTS_GRAMS[canonical], 1200.0), 2)
        for key, weight in _PIECE_WEIGHTS_GRAMS.items():
            if key in canonical or key in food_name:
                return round(min(quantity * weight, 1200.0), 2)
        # If food explicitly specifies per-piece serving unit
        if food and food.serving_unit.lower() in ("piece", "item", "whole"):
            return round(min(quantity * (food.serving_size or 50.0), 1200.0), 2)
        # Safe fallback when serving size is from standard 100g table:
        if food and food.serving_size:
            return round(min(quantity * min(food.serving_size, 50.0), 1200.0), 2)
        return round(min(quantity * 50.0, 1200.0), 2)

    if unit_clean in ("bowl", "bowls"):
        for key, weight in _BOWL_WEIGHTS_GRAMS.items():
            if key in canonical or key in food_name:
                return round(min(quantity * weight, 1200.0), 2)
        return round(min(quantity * 350.0, 1200.0), 2)

    if unit_clean in ("cup", "cups"):
        return round(min(quantity * 240.0, 1200.0), 2)

    if unit_clean in ("tbsp", "tablespoon", "tablespoons"):
        return round(min(quantity * 15.0, 1200.0), 2)

    if unit_clean in ("tsp", "teaspoon", "teaspoons"):
        return round(min(quantity * 5.0, 1200.0), 2)

    if unit_clean in ("plate", "plates"):
        for key, weight in _PLATE_WEIGHTS_GRAMS.items():
            if key in canonical or key in food_name:
                return round(min(quantity * weight, 1200.0), 2)
        return round(min(quantity * 350.0, 1200.0), 2)

    if unit_clean in ("serving", "servings"):
        serving = food.serving_size if food and food.serving_size else 100.0
        return round(min(quantity * serving, 1200.0), 2)

    # Unrecognized unit fallback: treat raw quantity as grams, capped at 1200g
    return round(min(quantity, 1200.0), 2)


@dataclass
class NutritionResult:
    """Nutrition calculated for one item, plus the Food record it matched (if any)."""

    matched_food: Food | None
    calories: float
    protein: float
    carbohydrates: float
    fat: float
    fiber: float
    grams: float = 0.0
    reference_serving_size: float = 100.0
    reference_serving_unit: str = "g"
    reference_calories: float = 0.0
    reference_protein: float = 0.0
    reference_carbohydrates: float = 0.0
    reference_fat: float = 0.0
    reference_fiber: float = 0.0

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
        """Look up a Food record by name using a four-tier matching pipeline:

        Tier 1 (Exact Canonical): Match by canonical_name directly.
        Tier 2 (Exact Display Name): Case-insensitive exact match on Food.name.
        Tier 3 (Synonym Table): Match via curated synonym dictionary.
        Tier 4 (Strict Fuzzy): Fallback matching with dish-boundary protection
        (e.g., prevents composite dishes like 'paneer pizza' from matching single
        ingredients like 'paneer').

        Records failing physical sanity checks (Food.is_physically_valid) are
        strictly rejected.
        """
        if not name or not name.strip():
            return None

        threshold = min_fuzzy_score if min_fuzzy_score is not None else FUZZY_MATCH_THRESHOLD
        query_raw = name.strip()
        query_lower = query_raw.lower()
        canonical = normalize_food_name(query_raw)

        # Tier 1: Exact canonical match
        result = await self.db.execute(select(Food).where(Food.canonical_name == canonical))
        food = result.scalar_one_or_none()
        if food is not None:
            if not food.is_physically_valid:
                logger.warning("Rejecting invalid database food record: %s", food.canonical_name)
                return None
            return food

        # Tier 2: Case-insensitive exact name match
        result = await self.db.execute(select(Food).where(Food.name.ilike(query_raw)))
        food = result.scalar_one_or_none()
        if food is not None:
            if not food.is_physically_valid:
                logger.warning("Rejecting invalid database food record: %s", food.canonical_name)
                return None
            return food

        # Tier 3: Synonym exact lookup
        cleaned_syn_key = re.sub(r"[^a-z0-9\s]", "", query_lower).strip()
        cleaned_syn_key = re.sub(r"\s+", " ", cleaned_syn_key)
        if cleaned_syn_key in _SYNONYMS:
            syn_canonical = _SYNONYMS[cleaned_syn_key]
            result = await self.db.execute(select(Food).where(Food.canonical_name == syn_canonical))
            food = result.scalar_one_or_none()
            if food is not None:
                if not food.is_physically_valid:
                    logger.warning("Rejecting invalid database food record: %s", food.canonical_name)
                    return None
                return food

        # Tier 4: Strict fuzzy matching across database choices (cached per service instance)
        if getattr(self, "_cached_choices", None) is None:
            all_foods_res = await self.db.execute(select(Food))
            all_foods = list(all_foods_res.scalars().all())
            choices: dict[str, Food] = {}
            for f in all_foods:
                if not f.is_physically_valid:
                    continue
                choices[f.name.lower()] = f
                choices[f.canonical_name.replace("_", " ").lower()] = f
                choices[f.canonical_name.lower()] = f
                for syn, syn_canonical in _SYNONYMS.items():
                    if syn_canonical == f.canonical_name:
                        choices[syn.lower()] = f
            self._cached_choices = choices
        else:
            choices = self._cached_choices

        if not choices:
            return None

        # Dish boundary protection:
        # If query contains a composite dish keyword (e.g. "pizza", "burger", "sandwich"),
        # choice MUST ALSO contain that keyword to be eligible.
        q_words = set(query_lower.split())
        q_dish_keywords = q_words & COMPOSITE_DISH_KEYWORDS

        eligible_choices: list[str] = []
        for choice_key in choices.keys():
            if q_dish_keywords:
                c_words = set(choice_key.split())
                c_dish_keywords = c_words & COMPOSITE_DISH_KEYWORDS
                if not (q_dish_keywords & c_dish_keywords):
                    continue
            eligible_choices.append(choice_key)

        if not eligible_choices:
            return None

        # Use token_set_ratio for candidate scoring among eligible choices
        match = process.extractOne(
            query_lower,
            eligible_choices,
            scorer=fuzz.token_set_ratio,
            score_cutoff=threshold,
        )

        if match is not None:
            best_match_key, _score, _ = match
            matched_food = choices[best_match_key]
            if not matched_food.is_physically_valid:
                logger.warning("Rejecting invalid database food record: %s", matched_food.canonical_name)
                return None
            return matched_food

        return None

    async def get_food_by_id(self, food_id: uuid.UUID) -> Food | None:
        result = await self.db.execute(select(Food).where(Food.id == food_id))
        food = result.scalar_one_or_none()
        if food and not food.is_physically_valid:
            logger.warning("Rejecting invalid database food record: %s", food.canonical_name)
            return None
        return food

    async def search_foods(self, query: str, limit: int = 20) -> list[Food]:
        result = await self.db.execute(
            select(Food).where(Food.name.ilike(f"%{query.strip()}%")).limit(limit)
        )
        return [f for f in result.scalars().all() if f.is_physically_valid]

    async def list_foods(self, limit: int = 100, offset: int = 0) -> list[Food]:
        result = await self.db.execute(select(Food).offset(offset).limit(limit))
        return [f for f in result.scalars().all() if f.is_physically_valid]

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
            grams=round(grams, 2),
            reference_serving_size=food.serving_size,
            reference_serving_unit=food.serving_unit,
            reference_calories=food.calories,
            reference_protein=food.protein,
            reference_carbohydrates=food.carbohydrates,
            reference_fat=food.fat,
            reference_fiber=food.fiber,
        )

    async def calculate_for_detection(
        self, name: str, quantity: float, unit: str = "g"
    ) -> NutritionResult:
        """Find a matching food via fuzzy search and calculate scaled nutrition."""
        food = await self.find_food_by_name(name)
        if food is None:
            grams = convert_quantity_to_grams(None, quantity, unit)
            return NutritionResult(
                matched_food=None,
                calories=0.0,
                protein=0.0,
                carbohydrates=0.0,
                fat=0.0,
                fiber=0.0,
                grams=round(grams, 2),
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
