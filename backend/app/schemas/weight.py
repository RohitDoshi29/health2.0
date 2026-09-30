"""Schemas for weight tracking and history analytics."""

import uuid
from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field


class WeightLogBase(BaseModel):
    weight_kg: float = Field(..., ge=20.0, le=400.0, description="Body weight in kilograms")
    logged_at: datetime | None = Field(default=None, description="Timestamp of the weight entry")
    note: str | None = Field(default=None, max_length=255, description="Optional note or context")


class WeightLogCreate(WeightLogBase):
    pass


class WeightLogRead(WeightLogBase):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    user_id: uuid.UUID
    logged_at: datetime
    created_at: datetime


class WeightHistoryPoint(BaseModel):
    date: str
    weight_kg: float
    calories_consumed: float | None = None


class WeightHistoryResponse(BaseModel):
    points: list[WeightHistoryPoint]
    current_weight: float | None = None
    start_weight: float | None = None
    change_total_kg: float | None = None
    change_7d_kg: float | None = None
    days: int
