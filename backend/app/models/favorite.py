"""FavoriteMeal model for storing reusable meal templates."""

import uuid
from datetime import datetime
from typing import Any

from sqlalchemy import JSON, DateTime, Float, ForeignKey, String, func
from sqlalchemy.dialects.postgresql import UUID as PGUUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base


class FavoriteMeal(Base):
    __tablename__ = "favorite_meals"

    id: Mapped[uuid.UUID] = mapped_column(
        PGUUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    user_id: Mapped[uuid.UUID] = mapped_column(
        PGUUID(as_uuid=True),
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )

    name: Mapped[str] = mapped_column(String(255), nullable=False)
    meal_type: Mapped[str] = mapped_column(String(50), nullable=False, default="snack")

    # JSON array of food items: [{name, quantity, unit, calories, protein, carbs, fat, fiber}]
    items_json: Mapped[list[dict[str, Any]]] = mapped_column(JSON, nullable=False, default=list)

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

    user: Mapped["User"] = relationship("User", back_populates="favorites")  # noqa: F821

    def __repr__(self) -> str:  # pragma: no cover
        return f"<FavoriteMeal id={self.id} user_id={self.user_id} name={self.name!r}>"
