"""Weight tracking API endpoints."""

import uuid

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.core.security import get_current_user
from app.models.user import User
from app.schemas.weight import (
    WeightHistoryResponse,
    WeightLogCreate,
    WeightLogRead,
)
from app.services.weight_service import WeightService

router = APIRouter(prefix="/weight", tags=["weight"])


@router.post("", response_model=WeightLogRead, status_code=status.HTTP_201_CREATED)
async def log_weight(
    payload: WeightLogCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> WeightLogRead:
    """Log a body weight measurement and update user profile weight."""
    service = WeightService(db)
    log = await service.create_log(current_user, payload)
    return WeightLogRead.model_validate(log)


@router.get("/history", response_model=WeightHistoryResponse)
async def get_weight_history(
    days: int = Query(default=30, ge=1, le=365, description="Number of days of history"),
    tz_offset: int = Query(
        default=0, description="Timezone offset in minutes from UTC (e.g. 330 for IST)"
    ),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> WeightHistoryResponse:
    """Get weight tracking history overlaid with daily calorie trends."""
    service = WeightService(db)
    return await service.get_history(current_user, days=days, tz_offset=tz_offset)


@router.delete("/{log_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_weight_log(
    log_id: uuid.UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> None:
    """Delete a weight log entry."""
    service = WeightService(db)
    deleted = await service.delete_log(current_user, log_id)
    if not deleted:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Weight log entry not found or unauthorized.",
        )
