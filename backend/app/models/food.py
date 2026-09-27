"""Food model — trusted nutrition-database reference data.

Nutrition values are stored PER SERVING (see `serving_size` /
`serving_unit`), e.g. "per 100 g". The nutrition service scales these
values by the quantity detected/entered for a given meal item.
"""

import uuid
from datetime import datetime

from sqlalchemy import DateTime, Float, String, func
from sqlalchemy.dialects.postgresql import UUID as PGUUID
from sqlalchemy.orm import Mapped, mapped_column

from app.core.database import Base


class Food(Base):
    __tablename__ = "foods"

    id: Mapped[uuid.UUID] = mapped_column(
        PGUUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )

    # Display name as it might appear to a user, e.g. "White rice (cooked)".
    name: Mapped[str] = mapped_column(String(255), nullable=False, index=True)

    # Normalized lookup key used by the food-name matching logic, e.g.
    # "cooked_white_rice". See services/nutrition_service.py.
    canonical_name: Mapped[str] = mapped_column(
        String(255), nullable=False, unique=True, index=True
    )

    # The basis the nutrition columns below are expressed against,
    # e.g. serving_size=100, serving_unit="g".
    serving_size: Mapped[float] = mapped_column(Float, nullable=False, default=100.0)
    serving_unit: Mapped[str] = mapped_column(String(20), nullable=False, default="g")

    calories: Mapped[float] = mapped_column(Float, nullable=False)
    protein: Mapped[float] = mapped_column(Float, nullable=False, default=0.0)
    carbohydrates: Mapped[float] = mapped_column(Float, nullable=False, default=0.0)
    fat: Mapped[float] = mapped_column(Float, nullable=False, default=0.0)
    fiber: Mapped[float] = mapped_column(Float, nullable=False, default=0.0)

    # Where this nutrition data came from, e.g. "seed", "usda", "manual".
    source: Mapped[str] = mapped_column(String(100), nullable=False, default="seed")

    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now(),
        nullable=False,
    )

    def __repr__(self) -> str:  # pragma: no cover
        return f"<Food id={self.id} canonical_name={self.canonical_name!r}>"
