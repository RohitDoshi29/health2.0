"""Schemas for Weekly Nutrition & Hydration Report."""

from pydantic import BaseModel, Field


class DailyAveragesRead(BaseModel):
    calories: float
    protein: float
    carbohydrates: float
    fat: float
    fiber: float
    water_ml: float


class DaySummaryRead(BaseModel):
    date: str
    day_name: str
    score: int
    calories: float


class NutrientHitsRead(BaseModel):
    calories: int = Field(..., ge=0, le=7)
    protein: int = Field(..., ge=0, le=7)
    carbohydrates: int = Field(..., ge=0, le=7)
    fat: int = Field(..., ge=0, le=7)
    fiber: int = Field(..., ge=0, le=7)
    water: int = Field(..., ge=0, le=7)


class WeightChangeRead(BaseModel):
    start_weight_kg: float
    end_weight_kg: float
    change_kg: float


class PriorWeekComparisonRead(BaseModel):
    prior_average_calories: float
    prior_average_protein: float
    calories_pct_change: float | None = None
    protein_pct_change: float | None = None


class DailyBarPoint(BaseModel):
    date: str
    day_name: str
    calories: float
    calorie_target: float
    score: int
    target_hit: bool


class WeeklyReportResponse(BaseModel):
    week_offset: int
    start_date: str
    end_date: str
    daily_averages: DailyAveragesRead
    best_day: DaySummaryRead
    worst_day: DaySummaryRead
    nutrient_hits: NutrientHitsRead
    weight_change: WeightChangeRead | None = None
    prior_week_comparison: PriorWeekComparisonRead
    daily_points: list[DailyBarPoint] = Field(default_factory=list)
