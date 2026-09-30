"""Meal and MealItem schemas."""

import uuid
from datetime import datetime

from typing import Any
from pydantic import BaseModel, ConfigDict, Field, field_validator

from app.schemas.analysis import QuantityUnit


class MealItemCreate(BaseModel):
    """A meal item as provided when creating/saving a meal.

    Typically populated from a MealAnalysisResponse (possibly edited by the
    user) or entered manually.
    """

    food_id: uuid.UUID | None = None
    food_name: str = Field(min_length=1)
    quantity: float = Field(gt=0)
    unit: str = "g"
    calories: float = Field(ge=0)
    protein: float = Field(ge=0, default=0.0)
    carbohydrates: float = Field(ge=0, default=0.0)
    fat: float = Field(ge=0, default=0.0)
    fiber: float = Field(ge=0, default=0.0)
    confidence: float | None = Field(default=None, ge=0.0, le=1.0)
    original_calories: float | None = None
    final_calories: float | None = None
    verification_status: str | None = None
    verification_confidence: float | None = None
    verification_sources: list[str] | None = None
    verification_note: str | None = None

    @field_validator("food_id", mode="before")
    @classmethod
    def clean_food_id(cls, v: Any) -> uuid.UUID | None:
        if not v or v == "" or v == "null":
            return None
        if isinstance(v, uuid.UUID):
            return v
        try:
            return uuid.UUID(str(v))
        except (ValueError, TypeError):
            return None


class MealItemRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    food_id: uuid.UUID | None
    food_name: str
    quantity: float
    unit: str
    calories: float
    protein: float
    carbohydrates: float
    fat: float
    fiber: float
    confidence: float | None
    original_calories: float | None = None
    final_calories: float | None = None
    verification_status: str | None = None
    verification_confidence: float | None = None
    verification_sources: list[str] | None = None
    verification_note: str | None = None
    created_at: datetime


class MealCreate(BaseModel):
    user_id: uuid.UUID | None = None
    image_url: str | None = None
    meal_type: str = "snack"
    created_at: datetime | None = None
    items: list[MealItemCreate] = Field(default_factory=list)



class MealUpdate(BaseModel):
    """Partial update. Only image_url/meal_type are patchable directly;
    items are managed via their own sub-resource in a future phase."""

    image_url: str | None = None
    meal_type: str | None = None


class MealRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    user_id: uuid.UUID
    image_url: str | None
    meal_type: str
    total_calories: float
    total_protein: float
    total_carbohydrates: float
    total_fat: float
    total_fiber: float
    created_at: datetime
    updated_at: datetime
    items: list[MealItemRead] = Field(default_factory=list)


class RecentFoodRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    food_id: uuid.UUID | None = None
    food_name: str
    quantity: float
    unit: str
    calories: float
    protein: float = 0.0
    carbohydrates: float = 0.0
    fat: float = 0.0
    fiber: float = 0.0
    last_logged_at: datetime
