"""add verification metadata to meal_items

Revision ID: 0007
Revises: 0006
Create Date: 2026-09-27 22:15:00
"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa

# revision identifiers, used by Alembic.
revision: str = "0007"
down_revision: Union[str, None] = "0006"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column("meal_items", sa.Column("original_calories", sa.Float(), nullable=True))
    op.add_column("meal_items", sa.Column("final_calories", sa.Float(), nullable=True))
    op.add_column("meal_items", sa.Column("verification_status", sa.String(length=50), nullable=True))
    op.add_column("meal_items", sa.Column("verification_confidence", sa.Float(), nullable=True))
    op.add_column("meal_items", sa.Column("verification_sources", sa.JSON(), nullable=True))
    op.add_column("meal_items", sa.Column("verification_note", sa.String(length=512), nullable=True))


def downgrade() -> None:
    op.drop_column("meal_items", "verification_note")
    op.drop_column("meal_items", "verification_sources")
    op.drop_column("meal_items", "verification_confidence")
    op.drop_column("meal_items", "verification_status")
    op.drop_column("meal_items", "final_calories")
    op.drop_column("meal_items", "original_calories")

