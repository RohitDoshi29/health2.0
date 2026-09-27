"""Goal and Daily Analytics schemas."""

import uuid
from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field


class GoalBase(BaseModel):
    calorie_target: float = Field(default=2000.0, gt=0)
    protein_target: float = Field(default=120.0, ge=0)
    carbohydrates_target: float = Field(default=250.0, ge=0)
    fat_target: float = Field(default=65.0, ge=0)
    fiber_target: float = Field(default=30.0, ge=0)
    water_target_ml: float = Field(default=2500.0, gt=0)


class GoalUpdate(BaseModel):
    calorie_target: float | None = Field(default=None, gt=0)
    protein_target: float | None = Field(default=None, ge=0)
    carbohydrates_target: float | None = Field(default=None, ge=0)
    fat_target: float | None = Field(default=None, ge=0)
    fiber_target: float | None = Field(default=None, ge=0)
    water_target_ml: float | None = Field(default=None, gt=0)


class GoalRead(GoalBase):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    user_id: uuid.UUID
    created_at: datetime
    updated_at: datetime


class DailyAnalyticsRead(BaseModel):
    date: str
    consumed_calories: float
    consumed_protein: float
    consumed_carbohydrates: float
    consumed_fat: float
    consumed_fiber: float
    calorie_progress: float
    protein_progress: float
    carbohydrates_progress: float
    fat_progress: float
    fiber_progress: float
    meals_count: int
    goal: GoalRead


class DailyTrendPoint(BaseModel):
    """Aggregated stats for one calendar day in the trend timeline."""

    date: str
    calories: float
    protein: float
    carbohydrates: float
    fat: float
    fiber: float
    meals_count: int
    calorie_target: float


class TrendsAnalyticsRead(BaseModel):
    """Historical nutrition trend dataset across a date range."""

    period: str
    days_count: int
    start_date: str
    end_date: str
    average_calories: float
    average_protein: float
    average_carbohydrates: float
    average_fat: float
    average_fiber: float
    goal: GoalRead
    data_points: list[DailyTrendPoint]


