"""Meal model.

A Meal represents a logged eating event (breakfast/lunch/dinner/snack)
made up of one or more MealItems. Totals are denormalized onto the meal
for fast reads, and are recalculated whenever items change.
"""

import uuid
from datetime import datetime

from sqlalchemy import DateTime, Float, ForeignKey, String, func
from sqlalchemy.dialects.postgresql import UUID as PGUUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base


class Meal(Base):
    __tablename__ = "meals"

    id: Mapped[uuid.UUID] = mapped_column(
        PGUUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    user_id: Mapped[uuid.UUID] = mapped_column(
        PGUUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True
    )

    image_url: Mapped[str | None] = mapped_column(String(1024), nullable=True)

    # e.g. "breakfast", "lunch", "dinner", "snack"
    meal_type: Mapped[str] = mapped_column(String(50), nullable=False, default="snack")

    total_calories: Mapped[float] = mapped_column(Float, nullable=False, default=0.0)
    total_protein: Mapped[float] = mapped_column(Float, nullable=False, default=0.0)
    total_carbohydrates: Mapped[float] = mapped_column(Float, nullable=False, default=0.0)
    total_fat: Mapped[float] = mapped_column(Float, nullable=False, default=0.0)
    total_fiber: Mapped[float] = mapped_column(Float, nullable=False, default=0.0)

    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now(),
        nullable=False,
    )

    user: Mapped["User"] = relationship("User", back_populates="meals")  # noqa: F821
    items: Mapped[list["MealItem"]] = relationship(  # noqa: F821
        "MealItem", back_populates="meal", cascade="all, delete-orphan"
    )

    def __repr__(self) -> str:  # pragma: no cover
        return f"<Meal id={self.id} user_id={self.user_id} type={self.meal_type!r}>"
