"""add favorites table

Revision ID: 0004
Revises: 0003
Create Date: 2026-09-22 00:00:00
"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

# revision identifiers, used by Alembic.
revision: str = "0004"
down_revision: Union[str, None] = "0003"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "favorite_meals",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column(
            "user_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("users.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column("name", sa.String(length=255), nullable=False),
        sa.Column("meal_type", sa.String(length=50), nullable=False, server_default="snack"),
        sa.Column("items_json", sa.JSON(), nullable=False),
        sa.Column("total_calories", sa.Float(), nullable=False, server_default="0.0"),
        sa.Column("total_protein", sa.Float(), nullable=False, server_default="0.0"),
        sa.Column("total_carbohydrates", sa.Float(), nullable=False, server_default="0.0"),
        sa.Column("total_fat", sa.Float(), nullable=False, server_default="0.0"),
        sa.Column("total_fiber", sa.Float(), nullable=False, server_default="0.0"),
        sa.Column(
            "created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False
        ),
        sa.Column(
            "updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False
        ),
    )
    op.create_index("ix_favorite_meals_user_id", "favorite_meals", ["user_id"])


def downgrade() -> None:
    op.drop_index("ix_favorite_meals_user_id", table_name="favorite_meals")
    op.drop_table("favorite_meals")

