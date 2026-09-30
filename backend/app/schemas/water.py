"""Schemas for water intake logging and hydration analytics."""

import uuid
from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field


class WaterLogCreate(BaseModel):
    amount_ml: float = Field(..., gt=0, le=5000, description="Amount in milliliters, e.g. 250, 500")
    logged_at: datetime | None = Field(default=None, description="Optional custom timestamp")


class WaterLogRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    user_id: uuid.UUID
    amount_ml: float
    logged_at: datetime


class DailyWaterSummary(BaseModel):
    date: str
    total_ml: float
    target_ml: float
    percentage: float
    logs_count: int
    logs: list[WaterLogRead]


class WaterHistoryDay(BaseModel):
    date: str
    total_ml: float
    target_ml: float
    percentage: float
    logs_count: int


class WaterGoalUpdate(BaseModel):
    water_target_ml: float = Field(
        ..., gt=0, le=10000, description="Daily target in milliliters, e.g. 2500"
    )
