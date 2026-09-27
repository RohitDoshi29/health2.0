"""Seed the local Food table with a handful of sample foods for development.

Run with:
    python -m scripts.seed_foods

Safe to re-run: existing rows (matched by canonical_name) are skipped.
"""

import asyncio

from sqlalchemy import select

from app.core.database import AsyncSessionLocal
from app.models.food import Food

# Approximate values per 100g, for local development only — NOT verified
# against a real nutrition database. Replace/extend via a real source in
# a future phase.
SEED_FOODS = [
    dict(
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
    dict(
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
    dict(
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
    dict(
        name="Roti (chapati)",
        canonical_name="roti",
        serving_size=100,
        serving_unit="g",
        calories=297,
        protein=11.0,
        carbohydrates=48.0,
        fat=7.0,
        fiber=4.9,
    ),
    dict(
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
    dict(
        name="Banana",
        canonical_name="banana",
        serving_size=100,
        serving_unit="g",
        calories=89,
        protein=1.1,
        carbohydrates=23.0,
        fat=0.3,
        fiber=2.6,
    ),
    dict(
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
]


async def seed() -> None:
    async with AsyncSessionLocal() as db:
        for item in SEED_FOODS:
            existing = await db.execute(
                select(Food).where(Food.canonical_name == item["canonical_name"])
            )
            if existing.scalar_one_or_none() is not None:
                print(f"skip (exists): {item['canonical_name']}")
                continue
            db.add(Food(source="seed", **item))
            print(f"added: {item['canonical_name']}")
        await db.commit()


if __name__ == "__main__":
    asyncio.run(seed())
