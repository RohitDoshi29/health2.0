"""Schemas for the Calorie Verification Engine.

Defines verification status, multi-source corroboration details,
3-part confidence breakdowns, and anomaly detection results.
"""

from enum import Enum

from pydantic import BaseModel, Field


class VerificationStatus(str, Enum):
    """Outcomes produced by the Calorie Verification Engine."""

    VERIFIED = "verified"
    VERIFIED_WITH_WARNING = "verified_with_warning"
    CORRECTED = "corrected"
    LOW_CONFIDENCE = "low_confidence"
    NEEDS_CONFIRMATION = "needs_confirmation"


class ConfidenceBreakdown(BaseModel):
    """Separate confidences for food ID, portion sizing, and nutrition data (0-100 scale)."""

    food_confidence: float = Field(
        ge=0.0, le=100.0, description="Confidence of visual food identification"
    )
    portion_confidence: float = Field(
        ge=0.0, le=100.0, description="Confidence of portion & volume estimation"
    )
    nutrition_confidence: float = Field(
        ge=0.0, le=100.0, description="Confidence of reference nutrition data"
    )
    overall_confidence: float = Field(
        ge=0.0, le=100.0, description="Weighted composite confidence score"
    )


class VerificationDetail(BaseModel):
    """Comprehensive verification result returned for a food item."""

    final_calories: float = Field(ge=0.0, description="Verified calories to display/log")
    original_calories: float = Field(description="Original estimate before verification")
    macro_derived_calories: float = Field(
        ge=0.0, description="Independently computed calories via Atwater 4-9-4"
    )
    verification_status: VerificationStatus
    confidence_score: float = Field(ge=0.0, le=100.0, description="Overall confidence (0-100)")
    confidence_breakdown: ConfidenceBreakdown
    verification_sources: list[str] = Field(
        default_factory=list,
        description="Independent sources used (e.g., local_database, usda_fdc, macro_consistency, barcode_label)",
    )
    source_breakdown: dict[str, float] = Field(
        default_factory=dict,
        description="Caloric values from each consulted source",
    )
    discrepancy_percent: float = Field(
        ge=0.0,
        description="Percentage difference between evaluated sources or against macro calculation",
    )
    verification_note: str = Field(
        description="Human-readable explanation of how the value was validated or adjusted",
    )
    anomaly_flags: list[str] = Field(
        default_factory=list,
        description="Any anomaly warnings raised (e.g. impossible_macros, extreme_calorie_density)",
    )
