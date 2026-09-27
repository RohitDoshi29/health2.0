"""Favorite meal schemas."""

import uuid
from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field


class FavoriteItemSchema(BaseModel):
    """A single food item inside a favorite template."""

    food_id: str | None = None
    food_name: str = Field(min_length=1)
    quantity: float = Field(gt=0)
    unit: str = Field(min_length=1, default="g")
    calories: float = Field(ge=0)
    protein: float = Field(default=0.0, ge=0)
    carbohydrates: float = Field(default=0.0, ge=0)
    fat: float = Field(default=0.0, ge=0)
    fiber: float = Field(default=0.0, ge=0)


class FavoriteCreate(BaseModel):
    """Payload to create a new favorite template."""

    name: str = Field(
        min_length=1, max_length=255, description="Template name, e.g. 'Morning Oats'"
    )
    meal_type: str = Field(default="snack", description="Default meal type, e.g. breakfast, lunch")
    items: list[FavoriteItemSchema] = Field(
        min_length=1, description="List of food items in this template"
    )


class FavoriteRead(BaseModel):
    """Favorite template representation."""

    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    user_id: uuid.UUID
    name: str
    meal_type: str
    items_json: list[dict]
    total_calories: float
    total_protein: float
    total_carbohydrates: float
    total_fat: float
    total_fiber: float
    created_at: datetime
    updated_at: datetime
