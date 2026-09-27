"""Goal model for tracking per-user daily nutrition targets."""

import uuid
from datetime import datetime

from sqlalchemy import DateTime, Float, ForeignKey, func
from sqlalchemy.dialects.postgresql import UUID as PGUUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base


class Goal(Base):
    __tablename__ = "goals"

    id: Mapped[uuid.UUID] = mapped_column(
        PGUUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    user_id: Mapped[uuid.UUID] = mapped_column(
        PGUUID(as_uuid=True),
        ForeignKey("users.id", ondelete="CASCADE"),
        unique=True,
        nullable=False,
        index=True,
    )

    calorie_target: Mapped[float] = mapped_column(Float, nullable=False, default=2000.0)
    protein_target: Mapped[float] = mapped_column(Float, nullable=False, default=120.0)
    carbohydrates_target: Mapped[float] = mapped_column(Float, nullable=False, default=250.0)
    fat_target: Mapped[float] = mapped_column(Float, nullable=False, default=65.0)
    fiber_target: Mapped[float] = mapped_column(Float, nullable=False, default=30.0)
    water_target_ml: Mapped[float] = mapped_column(Float, nullable=False, default=2500.0)

    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now(),
        nullable=False,
    )

    user: Mapped["User"] = relationship("User", back_populates="goal")  # noqa: F821

    def __repr__(self) -> str:  # pragma: no cover
        return f"<Goal user_id={self.user_id} calories={self.calorie_target}>"

