"""Portion guide service for food portion reference weights and searches."""

import uuid

from sqlalchemy import func, or_, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.food import Food
from app.models.portion import DEFAULT_PORTION_SEEDS, PortionGuide


class PortionService:
    """Service for managing and querying portion guides."""

    def __init__(self, db: AsyncSession) -> None:
        self.db = db

    async def _ensure_seeded(self) -> None:
        """Seed default portion guides if the table is currently empty."""
        count_res = await self.db.execute(select(func.count(PortionGuide.id)))
        count = count_res.scalar() or 0
        if count == 0:
            for s in DEFAULT_PORTION_SEEDS:
                p = PortionGuide(
                    id=uuid.uuid4(),
                    food_canonical_name=str(s["food_canonical_name"]),
                    label=str(s["label"]),
                    grams=float(s["grams"]),
                    image_asset=str(s["image_asset"]) if s.get("image_asset") else None,
                )
                self.db.add(p)
            await self.db.commit()

    async def get_portions_for_food(self, food_id: uuid.UUID) -> list[PortionGuide] | None:
        """Retrieve portion guides for a specific food by its ID.

        Returns None if the food does not exist.
        """
        await self._ensure_seeded()

        food_res = await self.db.execute(select(Food).where(Food.id == food_id))
        food = food_res.scalar_one_or_none()
        if food is None:
            return None

        portions_res = await self.db.execute(
            select(PortionGuide).where(
                or_(
                    PortionGuide.food_canonical_name == food.canonical_name,
                    PortionGuide.food_canonical_name == food.name.lower().replace(" ", "_"),
                )
            )
        )
        portions = list(portions_res.scalars().all())

        if not portions:
            # Fallback: create a dynamic single serving portion from the food database record
            serving_size = (
                food.serving_size if food.serving_size and food.serving_size > 0 else 100.0
            )
            serving_unit = food.serving_unit or "g"
            size_str = int(serving_size) if serving_size.is_integer() else serving_size
            dynamic_portion = PortionGuide(
                id=uuid.uuid4(),
                food_canonical_name=food.canonical_name,
                label=f"1 serving ({size_str} {serving_unit})",
                grams=serving_size,
                image_asset="assets/portions/piece.png",
            )
            portions.append(dynamic_portion)

        return portions

    async def search_portions(self, query: str | None = None) -> list[PortionGuide]:
        """Search portion guides by query, or return all available guides."""
        await self._ensure_seeded()

        if query and query.strip():
            clean_q = f"%{query.strip().lower()}%"
            stmt = (
                select(PortionGuide)
                .where(
                    or_(
                        PortionGuide.food_canonical_name.ilike(clean_q),
                        PortionGuide.label.ilike(clean_q),
                    )
                )
                .order_by(PortionGuide.food_canonical_name, PortionGuide.label)
            )
        else:
            stmt = select(PortionGuide).order_by(
                PortionGuide.food_canonical_name, PortionGuide.label
            )

        result = await self.db.execute(stmt)
        return list(result.scalars().all())
