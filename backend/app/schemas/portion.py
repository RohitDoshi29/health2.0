"""Pydantic schemas for portion guides."""

import uuid
from pydantic import BaseModel, ConfigDict


class PortionGuideRead(BaseModel):
    id: uuid.UUID
    food_canonical_name: str
    label: str
    grams: float
    image_asset: str | None = None

    model_config = ConfigDict(from_attributes=True)
