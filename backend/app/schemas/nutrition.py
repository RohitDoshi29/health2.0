"""Nutrition-related schemas: Food records and aggregate summaries."""

import uuid
from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field


class FoodBase(BaseModel):
    name: str
    canonical_name: str
    serving_size: float = Field(gt=0)
    serving_unit: str
    calories: float = Field(ge=0)
    protein: float = Field(ge=0, default=0.0)
    carbohydrates: float = Field(ge=0, default=0.0)
    fat: float = Field(ge=0, default=0.0)
    fiber: float = Field(ge=0, default=0.0)
    source: str = "seed"


class FoodCreate(FoodBase):
    pass


class FoodRead(FoodBase):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    created_at: datetime
    updated_at: datetime


class NutritionSummary(BaseModel):
    """An aggregate nutrition total, used for meal totals and analysis totals.

    Values are estimates — see product rule in README ("estimated_calories").
    """

    estimated_calories: float = Field(ge=0)
    protein: float = Field(ge=0)
    carbohydrates: float = Field(ge=0)
    fat: float = Field(ge=0)
    fiber: float = Field(ge=0)
