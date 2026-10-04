"""Schemas for portion guides."""

import uuid

from pydantic import BaseModel, ConfigDict, Field


class PortionGuideRead(BaseModel):
    id: uuid.UUID
    food_canonical_name: str = Field(description="Food canonical name, e.g. 'dal' or 'roti'")
    label: str = Field(description="Display label, e.g. '1 katori dal (150g)'")
    grams: float = Field(gt=0, description="Portion weight in grams")
    image_asset: str | None = Field(default=None, description="Asset path for portion visual")

    model_config = ConfigDict(from_attributes=True)
