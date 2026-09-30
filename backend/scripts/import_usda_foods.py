"""Import common reference foods from USDA FoodData Central API into local Food table.

Usage:
    python -m scripts.import_usda_foods

Prerequisites:
    Set USDA_API_KEY in your environment or .env file.
    Free key signup: https://fdc.nal.usda.gov/api-key-signup.html

Safe to re-run: existing foods (matched by canonical_name) are skipped idempotently.
"""

import asyncio
import logging
import os
import re
from typing import Any

import httpx
from dotenv import load_dotenv
from sqlalchemy import select

from app.core.database import AsyncSessionLocal
from app.models.food import Food

load_dotenv()

logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(message)s")
logger = logging.getLogger(__name__)

USDA_API_URL = "https://api.nal.usda.gov/fdc/v1/foods/search"

# Curated search list covering 120+ common staple foods across major dietary categories
COMMON_FOOD_SEARCH_TERMS = [
    # Grains, Rice, Breads & Pasta
    "cooked white rice",
    "cooked brown rice",
    "basmati rice",
    "jasmine rice",
    "white bread",
    "whole wheat bread",
    "sourdough bread",
    "rye bread",
    "bagel",
    "pita bread",
    "flour tortilla",
    "corn tortilla",
    "cooked pasta",
    "spaghetti",
    "noodles",
    "rolled oats",
    "cooked oatmeal",
    "cooked quinoa",
    "cornmeal",
    "couscous",
    # Poultry & Meats
    "cooked chicken breast",
    "cooked chicken thigh",
    "roasted chicken",
    "ground turkey",
    "cooked turkey breast",
    "cooked ground beef",
    "beef steak",
    "cooked beef roast",
    "pork chop",
    "pork tenderloin",
    "bacon",
    "ham",
    "lamb chop",
    # Fish & Seafood
    "cooked salmon",
    "canned tuna in water",
    "cooked shrimp",
    "cooked cod",
    "cooked tilapia",
    "canned sardines",
    "cooked trout",
    "crab meat",
    # Eggs, Dairy & Plant Milks
    "boiled egg",
    "fried egg",
    "scrambled egg",
    "whole milk",
    "low fat milk",
    "skim milk",
    "almond milk",
    "soy milk",
    "oat milk",
    "plain greek yogurt",
    "plain yogurt",
    "cheddar cheese",
    "mozzarella cheese",
    "parmesan cheese",
    "swiss cheese",
    "cottage cheese",
    "butter",
    "ghee",
    "paneer",
    # Plant Proteins, Legumes & Tofu
    "tofu",
    "tempeh",
    "edamame",
    "cooked black beans",
    "cooked chickpeas",
    "cooked kidney beans",
    "cooked lentils",
    "cooked pinto beans",
    "hummus",
    "falafel",
    # Common Vegetables
    "broccoli",
    "spinach",
    "carrot",
    "tomato",
    "cucumber",
    "baked potato",
    "baked sweet potato",
    "yellow onion",
    "garlic",
    "red bell pepper",
    "green bell pepper",
    "cauliflower",
    "green peas",
    "green beans",
    "romaine lettuce",
    "kale",
    "zucchini",
    "white button mushroom",
    "green cabbage",
    "avocado",
    "asparagus",
    "eggplant",
    "celery",
    "corn sweet yellow",
    # Fruits
    "apple",
    "banana",
    "orange",
    "strawberries",
    "blueberries",
    "raspberries",
    "blackberries",
    "mango",
    "red grapes",
    "pineapple",
    "watermelon",
    "cantaloupe",
    "peach",
    "pear",
    "kiwi fruit",
    "lemon",
    "lime",
    "papaya",
    "cherries",
    "pomegranate",
    # Nuts, Seeds & Nut Butters
    "almonds",
    "walnuts",
    "peanuts",
    "cashews",
    "pistachios",
    "chia seeds",
    "flax seeds",
    "pumpkin seeds",
    "sunflower seeds",
    "peanut butter",
    "almond butter",
    # Common Prepared / Indian & Global Dishes
    "roti chapati",
    "naan bread",
    "dal lentil soup",
    "vegetable curry",
    "cheese pizza",
    "cheeseburger",
    "french fries",
    # Beverages & Coffee
    "brewed coffee",
    "espresso",
    "iced coffee",
    "latte",
    "cappuccino",
    "chocolate syrup",
]


def canonicalize_name(raw_name: str) -> str:
    """Slugify food name into a unique canonical lookup key."""
    cleaned = re.sub(r"[^a-zA-Z0-9\s]", "", raw_name.lower())
    cleaned = re.sub(r"\s+", "_", cleaned).strip()
    return cleaned


def extract_nutrients(food_nutrients: list[dict[str, Any]]) -> dict[str, float]:
    """Extract standard macro nutrients per 100g from USDA nutrient array."""
    nutrients = {
        "calories": 0.0,
        "protein": 0.0,
        "carbohydrates": 0.0,
        "fat": 0.0,
        "fiber": 0.0,
    }

    for item in food_nutrients:
        name = str(item.get("nutrientName", "")).lower()
        num = str(item.get("nutrientNumber", ""))
        unit = str(item.get("unitName", "")).upper()
        val = float(item.get("value") or 0.0)

        # Calories (Energy)
        if ("energy" in name and unit in ("KCAL", "CAL")) or num in ("1008", "208"):
            if nutrients["calories"] == 0.0 or unit == "KCAL":
                nutrients["calories"] = round(val, 2)
        # Protein
        elif name == "protein" or num in ("1003", "203"):
            nutrients["protein"] = round(val, 2)
        # Carbohydrates
        elif "carbohydrate" in name or num in ("1005", "205"):
            nutrients["carbohydrates"] = round(val, 2)
        # Total Fat
        elif "total lipid" in name or name == "fat" or num in ("1004", "204"):
            nutrients["fat"] = round(val, 2)
        # Dietary Fiber
        elif "fiber" in name or num in ("1079", "291"):
            nutrients["fiber"] = round(val, 2)

    return nutrients


async def fetch_usda_food(
    client: httpx.AsyncClient, query: str, api_key: str
) -> dict[str, Any] | None:
    """Fetch best-matching food record from USDA FoodData Central search API."""
    # 1. Primary search: Foundation + SR Legacy
    params_primary: list[tuple[str, str]] = [
        ("api_key", api_key),
        ("query", query),
        ("dataType", "Foundation"),
        ("dataType", "SR Legacy"),
        ("pageSize", "1"),
    ]
    try:
        response = await client.get(USDA_API_URL, params=params_primary, timeout=10.0)
        if response.status_code == 429:
            logger.warning("USDA API rate limit reached (HTTP 429). Pausing for 5 seconds...")
            await asyncio.sleep(5.0)
            return None

        foods = []
        if response.status_code == 200:
            data = response.json()
            foods = data.get("foods", [])

        if not foods:
            # Fallback without dataType restriction to search all
            # categories (e.g. Survey FNDDS, Branded)
            params_fallback: list[tuple[str, str]] = [
                ("api_key", api_key),
                ("query", query),
                ("pageSize", "1"),
            ]
            res2 = await client.get(USDA_API_URL, params=params_fallback, timeout=10.0)
            if res2.status_code == 200:
                foods = res2.json().get("foods", [])

        if foods:
            return foods[0]
        return None
    except Exception as exc:
        logger.warning("Request failed for food %r: %s", query, exc)
        return None


async def import_usda_foods() -> None:
    """Import foods into the local database from USDA API."""
    api_key = os.getenv("USDA_API_KEY")
    if not api_key:
        logger.error(
            "USDA_API_KEY is not set.\n"
            "Please set USDA_API_KEY in your .env file or environment.\n"
            "You can obtain a free API key at: https://fdc.nal.usda.gov/api-key-signup.html"
        )
        return

    logger.info(
        "Starting USDA FoodData Central import (%d terms)...",
        len(COMMON_FOOD_SEARCH_TERMS),
    )
    added_count = 0
    skipped_count = 0
    failed_count = 0

    async with httpx.AsyncClient() as http_client, AsyncSessionLocal() as db:
        for index, term in enumerate(COMMON_FOOD_SEARCH_TERMS, start=1):
            canonical = canonicalize_name(term)

            # 1. Check idempotency: skip if already present
            existing = await db.execute(select(Food).where(Food.canonical_name == canonical))
            if existing.scalar_one_or_none() is not None:
                logger.info(
                    "[%d/%d] Skip (already exists): %s",
                    index,
                    len(COMMON_FOOD_SEARCH_TERMS),
                    canonical,
                )
                skipped_count += 1
                continue

            # 2. Fetch from USDA API
            record = await fetch_usda_food(http_client, query=term, api_key=api_key)
            if not record:
                logger.warning(
                    "[%d/%d] Not found on USDA: %s",
                    index,
                    len(COMMON_FOOD_SEARCH_TERMS),
                    term,
                )
                failed_count += 1
                await asyncio.sleep(0.3)
                continue

            # 3. Extract and parse nutrients
            food_nutrients = record.get("foodNutrients", [])
            nutrients = extract_nutrients(food_nutrients)

            # Skip if nutrition data was completely empty or 0
            if (
                nutrients["calories"] == 0.0
                and nutrients["protein"] == 0.0
                and nutrients["carbohydrates"] == 0.0
            ):
                logger.warning(
                    "[%d/%d] Skipping %r due to empty/zero nutrients",
                    index,
                    len(COMMON_FOOD_SEARCH_TERMS),
                    term,
                )
                failed_count += 1
                await asyncio.sleep(0.3)
                continue

            display_name = term.capitalize()
            food_entry = Food(
                name=display_name,
                canonical_name=canonical,
                serving_size=100.0,
                serving_unit="g",
                calories=nutrients["calories"],
                protein=nutrients["protein"],
                carbohydrates=nutrients["carbohydrates"],
                fat=nutrients["fat"],
                fiber=nutrients["fiber"],
                source="usda",
            )
            db.add(food_entry)
            await db.commit()
            added_count += 1
            logger.info(
                "[%d/%d] Added: %s (Cal: %.1f, P: %.1fg, C: %.1fg, F: %.1fg)",
                index,
                len(COMMON_FOOD_SEARCH_TERMS),
                display_name,
                nutrients["calories"],
                nutrients["protein"],
                nutrients["carbohydrates"],
                nutrients["fat"],
            )

            # Respect USDA API rate limit
            await asyncio.sleep(0.35)

    logger.info(
        "USDA import completed: %d added, %d skipped, %d failed/not found.",
        added_count,
        skipped_count,
        failed_count,
    )


if __name__ == "__main__":
    asyncio.run(import_usda_foods())
