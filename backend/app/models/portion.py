"""PortionGuide ORM model for visual portion sizes and unit conversions."""

import uuid
from datetime import datetime

from sqlalchemy import DateTime, Float, String, func
from sqlalchemy.dialects.postgresql import UUID as PGUUID
from sqlalchemy.orm import Mapped, mapped_column

from app.core.database import Base

DEFAULT_PORTION_SEEDS = [
    {
        "food_canonical_name": "dal",
        "label": "1 standard katori dal (150g)",
        "grams": 150.0,
        "image_asset": "assets/portions/katori.png",
    },
    {
        "food_canonical_name": "dal",
        "label": "1 small katori dal (100g)",
        "grams": 100.0,
        "image_asset": "assets/portions/katori_small.png",
    },
    {
        "food_canonical_name": "dal",
        "label": "1 large katori dal (200g)",
        "grams": 200.0,
        "image_asset": "assets/portions/katori_large.png",
    },
    {
        "food_canonical_name": "cooked_white_rice",
        "label": "1 small katori rice (100g)",
        "grams": 100.0,
        "image_asset": "assets/portions/katori.png",
    },
    {
        "food_canonical_name": "cooked_white_rice",
        "label": "1 medium katori rice (150g)",
        "grams": 150.0,
        "image_asset": "assets/portions/katori.png",
    },
    {
        "food_canonical_name": "cooked_white_rice",
        "label": "1 full plate rice (250g)",
        "grams": 250.0,
        "image_asset": "assets/portions/plate.png",
    },
    {
        "food_canonical_name": "roti",
        "label": "1 medium roti / chapati (40g)",
        "grams": 40.0,
        "image_asset": "assets/portions/roti.png",
    },
    {
        "food_canonical_name": "pizza",
        "label": "1 medium slice pizza (100g)",
        "grams": 100.0,
        "image_asset": "assets/portions/slice.png",
    },
]


class PortionGuide(Base):
    __tablename__ = "portion_guides"

    id: Mapped[uuid.UUID] = mapped_column(
        PGUUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    food_canonical_name: Mapped[str] = mapped_column(String(255), nullable=False, index=True)
    label: Mapped[str] = mapped_column(String(255), nullable=False)
    grams: Mapped[float] = mapped_column(Float, nullable=False)
    image_asset: Mapped[str | None] = mapped_column(String(255), nullable=True)

    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )
