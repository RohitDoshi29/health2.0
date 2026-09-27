"""add water tracking and goals water target

Revision ID: 0006
Revises: 0005
Create Date: 2026-09-22 00:00:00
"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

# revision identifiers, used by Alembic.
revision: str = "0006"
down_revision: Union[str, None] = "0005"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column("goals", sa.Column("water_target_ml", sa.Float(), nullable=False, server_default="2500.0"))

    op.create_table(
        "water_logs",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column("user_id", postgresql.UUID(as_uuid=True), sa.ForeignKey("users.id", ondelete="CASCADE"), nullable=False),
        sa.Column("amount_ml", sa.Float(), nullable=False),
        sa.Column("logged_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
    )
    op.create_index("ix_water_logs_user_id", "water_logs", ["user_id"])
    op.create_index("ix_water_logs_logged_at", "water_logs", ["logged_at"])


def downgrade() -> None:
    op.drop_index("ix_water_logs_logged_at", table_name="water_logs")
    op.drop_index("ix_water_logs_user_id", table_name="water_logs")
    op.drop_table("water_logs")
    op.drop_column("goals", "water_target_ml")

