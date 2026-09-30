"""Schemas for Streaks, Daily Nutrition Scores, and Badges."""

from pydantic import BaseModel, Field


class ScoreBreakdownItem(BaseModel):
    points: float = Field(..., description="Points earned for this category")
    max_points: float = Field(..., description="Maximum possible points for this category")
    achieved: bool = Field(..., description="Whether the criteria was met")
    value: float = Field(..., description="Current consumed value")
    target: float = Field(..., description="Target value for this category")
    description: str = Field(..., description="Human-readable explanation of points rule")


class DailyScoreBreakdown(BaseModel):
    calories: ScoreBreakdownItem
    protein: ScoreBreakdownItem
    fiber: ScoreBreakdownItem
    water: ScoreBreakdownItem


class DailyScoreRead(BaseModel):
    date: str
    score: int = Field(..., ge=0, le=100, description="Overall health score (0-100)")
    breakdown: DailyScoreBreakdown


class EarnedBadgeId(BaseModel):
    id: str
    earned_at: str


class BadgeItem(BaseModel):
    id: str
    name: str
    description: str
    icon: str
    unlocked: bool
    earned_at: str | None = None


class StreaksResponse(BaseModel):
    current_streak: int = Field(..., description="Consecutive days >= 60 score ending yesterday or today")
    longest_streak: int = Field(..., description="Longest consecutive days >= 60 score")
    today_score: DailyScoreRead
    streak_active_today: bool = Field(..., description="Whether today has achieved >= 60 score")
    earned_badges: list[EarnedBadgeId] = Field(default_factory=list)
    badges: list[BadgeItem] = Field(default_factory=list)
