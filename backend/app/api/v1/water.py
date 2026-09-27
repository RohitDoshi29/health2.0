"""Water intake and hydration endpoints."""

import uuid
from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.core.security import get_current_user_id
from app.schemas.goal import GoalRead
from app.schemas.water import (
    DailyWaterSummary,
    WaterGoalUpdate,
    WaterHistoryDay,
    WaterLogCreate,
)
from app.services.water_service import WaterService

router = APIRouter(prefix="/water", tags=["water"])


@router.post("", response_model=DailyWaterSummary, status_code=status.HTTP_201_CREATED)
async def log_water(
    payload: WaterLogCreate,
    user_id: Annotated[uuid.UUID, Depends(get_current_user_id)],
    db: Annotated[AsyncSession, Depends(get_db)],
) -> DailyWaterSummary:
    """Log water intake for the authenticated user and return updated today's summary."""
    service = WaterService(db)
    return await service.log_water(user_id=user_id, payload=payload)


@router.get("/today", response_model=DailyWaterSummary)
async def get_today_water_summary(
    user_id: Annotated[uuid.UUID, Depends(get_current_user_id)],
    db: Annotated[AsyncSession, Depends(get_db)],
) -> DailyWaterSummary:
    """Get today's water intake progress against user daily goal."""
    service = WaterService(db)
    return await service.get_daily_summary(user_id=user_id)


@router.get("/history", response_model=list[WaterHistoryDay])
async def get_water_history(
    user_id: Annotated[uuid.UUID, Depends(get_current_user_id)],
    db: Annotated[AsyncSession, Depends(get_db)],
    days: int = Query(7, ge=1, le=30, description="Number of past days to retrieve"),
) -> list[WaterHistoryDay]:
    """Get multi-day water intake history."""
    service = WaterService(db)
    return await service.get_history(user_id=user_id, days=days)


@router.delete("/{log_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_water_log(
    log_id: uuid.UUID,
    user_id: Annotated[uuid.UUID, Depends(get_current_user_id)],
    db: Annotated[AsyncSession, Depends(get_db)],
) -> None:
    """Delete a specific water intake log entry."""
    service = WaterService(db)
    deleted = await service.delete_log(user_id=user_id, log_id=log_id)
    if not deleted:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Water log entry not found or not owned by current user.",
        )


@router.put("/goal", response_model=GoalRead)
async def update_water_goal(
    payload: WaterGoalUpdate,
    user_id: Annotated[uuid.UUID, Depends(get_current_user_id)],
    db: Annotated[AsyncSession, Depends(get_db)],
) -> GoalRead:
    """Update daily water target goal in milliliters."""
    service = WaterService(db)
    goal = await service.update_water_goal(
        user_id=user_id, water_target_ml=payload.water_target_ml
    )
    return GoalRead.model_validate(goal)

