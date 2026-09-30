"""add portions table

Revision ID: 0010
Revises: 0009
Create Date: 2026-09-30 16:30:00
"""

from typing import Sequence, Union
import uuid

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

from app.models.portion import DEFAULT_PORTION_SEEDS

# revision identifiers, used by Alembic.
revision: str = "0010"
down_revision: Union[str, None] = "0009"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    portions_table = op.create_table(
        "portions",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column("food_canonical_name", sa.String(length=255), nullable=False),
        sa.Column("label", sa.String(length=100), nullable=False),
        sa.Column("grams", sa.Float(), nullable=False),
        sa.Column("image_asset", sa.String(length=255), nullable=True),
        sa.Column(
            "created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False
        ),
    )
    op.create_index("ix_portions_food_canonical_name", "portions", ["food_canonical_name"])

    # Seed default portions into database
    seed_data = [
        {
            "id": uuid.uuid4(),
            "food_canonical_name": s["food_canonical_name"],
            "label": s["label"],
            "grams": s["grams"],
            "image_asset": s["image_asset"],
        }
        for s in DEFAULT_PORTION_SEEDS
    ]
    op.bulk_insert(portions_table, seed_data)


def downgrade() -> None:
    op.drop_index("ix_portions_food_canonical_name", table_name="portions")
    op.drop_table("portions")
