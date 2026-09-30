"""Schemas for user profile, biometric data, and onboarding calculations."""

import uuid
from datetime import datetime
from typing import Literal

from pydantic import BaseModel, ConfigDict, Field

from app.schemas.goal import GoalRead

ActivityLevel = Literal["sedentary", "light", "moderate", "active", "very_active"]
GoalType = Literal["lose", "maintain", "gain"]
SexType = Literal["male", "female"]


class UserProfileBase(BaseModel):
    age: int = Field(..., ge=13, le=100, description="Age in years (13-100)")
    sex: SexType = Field(..., description="Biological sex ('male' or 'female')")
    height_cm: float = Field(..., ge=100.0, le=250.0, description="Height in cm (100-250)")
    weight_kg: float = Field(..., ge=30.0, le=300.0, description="Weight in kg (30-300)")
    activity_level: ActivityLevel = Field(
        ..., description="Activity level: sedentary, light, moderate, active, very_active"
    )
    goal: GoalType = Field(..., description="Health goal: lose, maintain, gain")


class UserProfileCreate(UserProfileBase):
    pass


class UserProfilePreviewRequest(UserProfileBase):
    pass


class NutritionTargets(BaseModel):
    bmr: float
    tdee: float
    calorie_target: float
    protein_target: float
    carbohydrates_target: float
    fat_target: float
    fiber_target: float
    water_target_ml: float


class UserProfilePreviewResponse(NutritionTargets):
    pass


class UserProfileRead(UserProfileBase):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    user_id: uuid.UUID
    onboarding_completed: bool
    bmr: float | None = None
    tdee: float | None = None
    created_at: datetime
    updated_at: datetime


class UserProfileResponse(BaseModel):
    profile: UserProfileRead
    goal: GoalRead
    bmr: float
    tdee: float
