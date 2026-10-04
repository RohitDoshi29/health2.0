"""Schemas for daily score, streaks, and gamification badges."""

from pydantic import BaseModel, Field


class ScoreBreakdownItem(BaseModel):
    points: float
    max_points: float
    achieved: bool
    value: float
    target: float
    description: str


class DailyScoreBreakdown(BaseModel):
    calories: ScoreBreakdownItem
    protein: ScoreBreakdownItem
    fiber: ScoreBreakdownItem
    water: ScoreBreakdownItem


class DailyScoreRead(BaseModel):
    date: str
    score: int = Field(ge=0, le=100)
    breakdown: DailyScoreBreakdown


class BadgeItem(BaseModel):
    id: str
    name: str
    description: str
    icon: str
    unlocked: bool
    earned_at: str | None = None


class EarnedBadgeId(BaseModel):
    id: str
    earned_at: str


class StreaksResponse(BaseModel):
    current_streak: int = Field(ge=0)
    longest_streak: int = Field(ge=0)
    today_score: DailyScoreRead
    streak_active_today: bool
    earned_badges: list[EarnedBadgeId] = Field(default_factory=list)
    badges: list[BadgeItem] = Field(default_factory=list)
