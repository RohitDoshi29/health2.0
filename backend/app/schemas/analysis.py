"""Schemas for the food-image analysis pipeline (Gemini + nutrition mapping)."""

from enum import Enum

from pydantic import BaseModel, Field, field_validator

from app.schemas.nutrition import NutritionSummary


class QuantityUnit(str, Enum):
    """Units Gemini or manual entry is allowed to return."""

    G = "g"
    ML = "ml"
    PIECE = "piece"
    CUP = "cup"
    TBSP = "tbsp"
    TSP = "tsp"
    SLICE = "slice"
    BOWL = "bowl"
    SERVING = "serving"
    PLATE = "plate"


class BoundingBox(BaseModel):
    """Normalized 2D bounding box coordinates [0.0, 1.0]."""

    ymin: float = Field(ge=0.0, le=1.0, description="Top boundary ratio")
    xmin: float = Field(ge=0.0, le=1.0, description="Left boundary ratio")
    ymax: float = Field(ge=0.0, le=1.0, description="Bottom boundary ratio")
    xmax: float = Field(ge=0.0, le=1.0, description="Right boundary ratio")


class FoodDetection(BaseModel):
    """A single food item as detected by Gemini, before nutrition mapping.

    This is intentionally Gemini's full responsibility and nothing more:
    identification + portion estimate + confidence + spatial localization. No calorie math here.
    """

    name: str = Field(min_length=1, description="Best-guess canonical food name")
    estimated_quantity: float = Field(gt=0)
    unit: QuantityUnit
    confidence: float = Field(ge=0.0, le=1.0)
    bounding_box: BoundingBox | None = Field(
        default=None, description="Normalized 2D bounding box if detected"
    )

    @field_validator("name")
    @classmethod
    def name_must_not_be_blank(cls, v: str) -> str:
        v = v.strip()
        if not v:
            raise ValueError("food name must not be blank")
        return v


class GeminiAnalysisResult(BaseModel):
    """Raw, validated shape of Gemini's JSON response."""

    foods: list[FoodDetection] = Field(default_factory=list)


class MealItemAnalysis(BaseModel):
    """A single analyzed meal item: detection + calculated nutrition.

    Frontends should check `matched` (or `matched_food_id is not None`) to
    distinguish between a food whose nutrition was verified in the database
    and an unmatched food whose values default to 0.0.
    """

    name: str
    quantity: float
    unit: QuantityUnit
    estimated_calories: float = Field(ge=0)
    protein: float = Field(ge=0)
    carbohydrates: float = Field(ge=0)
    fat: float = Field(ge=0)
    fiber: float = Field(ge=0)
    confidence: float = Field(ge=0.0, le=1.0)
    matched: bool = Field(
        default=False,
        description=(
            "True if the food item was matched in the nutrition database; "
            "False if unmatched (calories/macros will be 0.0)"
        ),
    )
    matched_food_id: str | None = Field(
        default=None, description="Food.id if a nutrition-database match was found, else None"
    )
    bounding_box: BoundingBox | None = Field(
        default=None, description="Normalized 2D bounding box if detected"
    )


class MealAnalysisResponse(BaseModel):
    """Response returned by POST /api/v1/analysis/analyze.

    Note: analysis does NOT save anything to the database. Saving is a
    separate, explicit step via the /meals endpoints.
    """

    total: NutritionSummary
    items: list[MealItemAnalysis]
    unmatched_items: list[str] = Field(
        default_factory=list,
        description="List of detected food item names that had no match in the nutrition database",
    )
    image_url: str | None = Field(
        default=None, description="Persisted image URL on the server"
    )
    disclaimer: str = (
        "Nutrition values are estimates derived from an AI-identified photo "
        "and a reference nutrition database. They are not medically exact "
        "measurements."
    )
