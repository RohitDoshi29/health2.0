"""MealItem model.

Each MealItem is one detected/logged food entry within a Meal. Nutrition
values here are a SNAPSHOT captured at analysis time — deliberately
duplicated from Food rather than joined live, so that later edits to the
Food table never silently rewrite the nutrition of a historical meal.
"""

import uuid
from datetime import datetime

from sqlalchemy import DateTime, Float, ForeignKey, String, func
from sqlalchemy.dialects.postgresql import UUID as PGUUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base


class MealItem(Base):
    __tablename__ = "meal_items"

    id: Mapped[uuid.UUID] = mapped_column(
        PGUUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    meal_id: Mapped[uuid.UUID] = mapped_column(
        PGUUID(as_uuid=True), ForeignKey("meals.id", ondelete="CASCADE"), nullable=False, index=True
    )

    # Nullable: a detected food might not have matched a row in `foods` yet.
    food_id: Mapped[uuid.UUID | None] = mapped_column(
        PGUUID(as_uuid=True), ForeignKey("foods.id", ondelete="SET NULL"), nullable=True
    )

    # The name as detected/entered, preserved even if `food_id` is later
    # unmatched or the Food row is renamed.
    food_name: Mapped[str] = mapped_column(String(255), nullable=False)

    quantity: Mapped[float] = mapped_column(Float, nullable=False)
    unit: Mapped[str] = mapped_column(String(20), nullable=False, default="g")

    # Snapshot of computed nutrition at analysis/save time (see module docstring).
    calories: Mapped[float] = mapped_column(Float, nullable=False)
    protein: Mapped[float] = mapped_column(Float, nullable=False, default=0.0)
    carbohydrates: Mapped[float] = mapped_column(Float, nullable=False, default=0.0)
    fat: Mapped[float] = mapped_column(Float, nullable=False, default=0.0)
    fiber: Mapped[float] = mapped_column(Float, nullable=False, default=0.0)

    # Gemini's detection confidence (0-1). Null for manually-added items.
    confidence: Mapped[float | None] = mapped_column(Float, nullable=True)

    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )

    meal: Mapped["Meal"] = relationship("Meal", back_populates="items")  # noqa: F821

    def __repr__(self) -> str:  # pragma: no cover
        return (
            f"<MealItem id={self.id} food_name={self.food_name!r} "
            f"qty={self.quantity}{self.unit}>"
        )
