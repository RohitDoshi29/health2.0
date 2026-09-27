"""add goals table

Revision ID: 0003
Revises: 0002
Create Date: 2026-09-22 00:00:00
"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

# revision identifiers, used by Alembic.
revision: str = "0003"
down_revision: Union[str, None] = "0002"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "goals",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column(
            "user_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("users.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column("calorie_target", sa.Float(), nullable=False, server_default="2000.0"),
        sa.Column("protein_target", sa.Float(), nullable=False, server_default="120.0"),
        sa.Column("carbohydrates_target", sa.Float(), nullable=False, server_default="250.0"),
        sa.Column("fat_target", sa.Float(), nullable=False, server_default="65.0"),
        sa.Column("fiber_target", sa.Float(), nullable=False, server_default="30.0"),
        sa.Column(
            "created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False
        ),
        sa.Column(
            "updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False
        ),
    )
    op.create_unique_constraint("uq_goals_user_id", "goals", ["user_id"])
    op.create_index("ix_goals_user_id", "goals", ["user_id"])


def downgrade() -> None:
    op.drop_index("ix_goals_user_id", table_name="goals")
    op.drop_constraint("uq_goals_user_id", "goals", type_="unique")
    op.drop_table("goals")

