"""Portion guide model — reference portions and unit conversions for common foods."""

import uuid
from datetime import datetime

from sqlalchemy import DateTime, Float, String, func
from sqlalchemy.dialects.postgresql import UUID as PGUUID
from sqlalchemy.orm import Mapped, mapped_column

from app.core.database import Base


class PortionGuide(Base):
    __tablename__ = "portions"

    id: Mapped[uuid.UUID] = mapped_column(
        PGUUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )

    # Food canonical name matching food records (e.g. "dal", "cooked_white_rice", "roti", "cheese_pizza")
    food_canonical_name: Mapped[str] = mapped_column(
        String(255), nullable=False, index=True
    )

    # Human-readable portion label (e.g. "1 katori", "1 roti", "1 slice", "1 glass", "1 idli")
    label: Mapped[str] = mapped_column(String(100), nullable=False)

    # Weight in grams for this single portion unit
    grams: Mapped[float] = mapped_column(Float, nullable=False)

    # Optional local/bundled image asset path in Flutter frontend
    image_asset: Mapped[str | None] = mapped_column(String(255), nullable=True)

    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )

    def __repr__(self) -> str:  # pragma: no cover
        return f"<PortionGuide {self.food_canonical_name}: {self.label} = {self.grams}g>"


DEFAULT_PORTION_SEEDS: list[dict[str, object]] = [
    {"food_canonical_name": "dal", "label": "1 katori dal", "grams": 150.0, "image_asset": "assets/portions/katori.png"},
    {"food_canonical_name": "roti", "label": "1 roti / chapati", "grams": 40.0, "image_asset": "assets/portions/roti.png"},
    {"food_canonical_name": "chapati", "label": "1 chapati", "grams": 40.0, "image_asset": "assets/portions/roti.png"},
    {"food_canonical_name": "cooked_white_rice", "label": "1 katori rice", "grams": 150.0, "image_asset": "assets/portions/katori.png"},
    {"food_canonical_name": "cooked_white_rice", "label": "1 plate rice", "grams": 250.0, "image_asset": "assets/portions/plate.png"},
    {"food_canonical_name": "cheese_pizza", "label": "1 slice pizza", "grams": 100.0, "image_asset": "assets/portions/slice.png"},
    {"food_canonical_name": "pizza", "label": "1 slice pizza", "grams": 100.0, "image_asset": "assets/portions/slice.png"},
    {"food_canonical_name": "milk", "label": "1 glass milk", "grams": 240.0, "image_asset": "assets/portions/glass.png"},
    {"food_canonical_name": "idli", "label": "1 idli", "grams": 50.0, "image_asset": "assets/portions/piece.png"},
    {"food_canonical_name": "dosa", "label": "1 plain dosa", "grams": 100.0, "image_asset": "assets/portions/piece.png"},
    {"food_canonical_name": "egg", "label": "1 whole egg", "grams": 50.0, "image_asset": "assets/portions/piece.png"},
    {"food_canonical_name": "boiled_egg", "label": "1 boiled egg", "grams": 50.0, "image_asset": "assets/portions/piece.png"},
    {"food_canonical_name": "ghee", "label": "1 tbsp ghee", "grams": 15.0, "image_asset": "assets/portions/tbsp.png"},
    {"food_canonical_name": "ghee", "label": "1 tsp ghee", "grams": 5.0, "image_asset": "assets/portions/tsp.png"},
    {"food_canonical_name": "paratha", "label": "1 paratha", "grams": 80.0, "image_asset": "assets/portions/roti.png"},
    {"food_canonical_name": "samosa", "label": "1 samosa", "grams": 75.0, "image_asset": "assets/portions/piece.png"},
    {"food_canonical_name": "paneer", "label": "1 paneer cube", "grams": 15.0, "image_asset": "assets/portions/piece.png"},
    {"food_canonical_name": "curd", "label": "1 bowl curd / yogurt", "grams": 150.0, "image_asset": "assets/portions/katori.png"},
    {"food_canonical_name": "salad", "label": "1 bowl green salad", "grams": 120.0, "image_asset": "assets/portions/bowl.png"},
    {"food_canonical_name": "soup", "label": "1 bowl soup", "grams": 240.0, "image_asset": "assets/portions/bowl.png"},
    {"food_canonical_name": "apple", "label": "1 medium apple", "grams": 182.0, "image_asset": "assets/portions/piece.png"},
    {"food_canonical_name": "banana", "label": "1 medium banana", "grams": 118.0, "image_asset": "assets/portions/piece.png"},
    {"food_canonical_name": "coffee", "label": "1 cup coffee", "grams": 240.0, "image_asset": "assets/portions/cup.png"},
    {"food_canonical_name": "tea", "label": "1 cup tea", "grams": 150.0, "image_asset": "assets/portions/cup.png"},
    {"food_canonical_name": "bread", "label": "1 slice bread", "grams": 35.0, "image_asset": "assets/portions/slice.png"},
    {"food_canonical_name": "cooked_chicken", "label": "1 piece chicken", "grams": 150.0, "image_asset": "assets/portions/piece.png"},
    {"food_canonical_name": "chicken", "label": "1 piece chicken", "grams": 150.0, "image_asset": "assets/portions/piece.png"},
    {"food_canonical_name": "cheeseburger", "label": "1 burger", "grams": 180.0, "image_asset": "assets/portions/piece.png"},
]
