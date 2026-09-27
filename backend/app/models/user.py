"""User model.

Authentication is intentionally minimal at this stage (see
app/core/security.py). This model only stores basic profile data.
"""

import uuid
from datetime import datetime

from sqlalchemy import DateTime, String, func
from sqlalchemy.dialects.postgresql import UUID as PGUUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base


class User(Base):
    __tablename__ = "users"

    id: Mapped[uuid.UUID] = mapped_column(
        PGUUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    name: Mapped[str] = mapped_column(String(255), nullable=False)
    email: Mapped[str] = mapped_column(String(255), nullable=False, unique=True, index=True)
    hashed_password: Mapped[str | None] = mapped_column(String(255), nullable=True)
    auth_provider: Mapped[str] = mapped_column(String(50), default="email", nullable=False)
    avatar_url: Mapped[str | None] = mapped_column(String(500), nullable=True)
    firebase_uid: Mapped[str | None] = mapped_column(String(255), nullable=True, index=True)


    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now(),
        nullable=False,
    )

    meals: Mapped[list["Meal"]] = relationship(  # noqa: F821
        "Meal", back_populates="user", cascade="all, delete-orphan"
    )
    goal: Mapped["Goal | None"] = relationship(  # noqa: F821
        "Goal", back_populates="user", uselist=False, cascade="all, delete-orphan"
    )
    favorites: Mapped[list["FavoriteMeal"]] = relationship(  # noqa: F821
        "FavoriteMeal", back_populates="user", cascade="all, delete-orphan"
    )
    water_logs: Mapped[list["WaterLog"]] = relationship(  # noqa: F821
        "WaterLog", back_populates="user", cascade="all, delete-orphan"
    )

    def __repr__(self) -> str:  # pragma: no cover
        return f"<User id={self.id} email={self.email!r}>"

