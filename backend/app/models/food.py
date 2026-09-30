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

    @property
    def is_physically_valid(self) -> bool:
        """Sanity check to ensure nutrition database records are physically plausible.

        Checks:
        1. Non-negative nutrients (calories >= 0, protein >= 0, carbs >= 0, fat >= 0, fiber >= 0)
        2. Serving size must be strictly positive
        3. Caloric density <= 9.5 kcal/g (fat is ~9.0 kcal/g; normal food cannot exceed this)
        4. Protein mass <= serving size * 1.02
        5. Total macronutrient mass (protein + carbs + fat) <= serving size * 1.05
        """
        if (
            self.calories < 0.0
            or self.protein < 0.0
            or self.carbohydrates < 0.0
            or self.fat < 0.0
            or (self.fiber or 0.0) < 0.0
        ):
            return False

        size = self.serving_size or 0.0
        if size <= 0.0:
            return False

        if self.serving_unit.lower() in ("g", "gram", "grams", "ml"):
            cal_density = self.calories / size
            if cal_density > 9.5:
                return False
            if self.protein > (size * 1.02):
                return False
            macro_mass = self.protein + self.carbohydrates + self.fat
            if macro_mass > (size * 1.05):
                return False

        return True
