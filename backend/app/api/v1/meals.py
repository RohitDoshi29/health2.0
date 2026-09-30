"""Meal CRUD endpoints with JWT authentication and per-user authorization."""

import uuid

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.core.security import get_current_user
from app.models.user import User
from app.schemas.meal import MealCreate, MealRead, MealUpdate, RecentFoodRead
from app.services.gemini_service import GeminiService, get_gemini_service
from app.services.meal_service import MealNotFoundError, MealService

router = APIRouter(prefix="/meals", tags=["meals"])


def _get_meal_service(
    db: AsyncSession = Depends(get_db),
    gemini_service: GeminiService = Depends(get_gemini_service),
) -> MealService:
    return MealService(db=db, gemini_service=gemini_service)


@router.post("", response_model=MealRead, status_code=status.HTTP_201_CREATED)
async def create_meal(
    payload: MealCreate,
    current_user: User = Depends(get_current_user),
    service: MealService = Depends(_get_meal_service),
) -> MealRead:
    """Create a new saved meal belonging to the authenticated user."""
    meal = await service.create_meal(payload, user_id=current_user.id)
    return MealRead.model_validate(meal)


@router.get("", response_model=list[MealRead])
async def list_meals(
    limit: int = Query(default=50, ge=1, le=200),
    offset: int = Query(default=0, ge=0),
    current_user: User = Depends(get_current_user),
    service: MealService = Depends(_get_meal_service),
) -> list[MealRead]:
    """List meals belonging to the authenticated user."""
    meals = await service.list_meals(user_id=current_user.id, limit=limit, offset=offset)
    return [MealRead.model_validate(m) for m in meals]


@router.get("/recent-foods", response_model=list[RecentFoodRead])
async def get_recent_foods(
    limit: int = Query(default=20, ge=1, le=100),
    current_user: User = Depends(get_current_user),
    service: MealService = Depends(_get_meal_service),
) -> list[RecentFoodRead]:
    """Get deduplicated food items recently logged by the authenticated user."""
    return await service.get_recent_foods(user_id=current_user.id, limit=limit)


@router.post("/{meal_id}/relog", response_model=MealRead, status_code=status.HTTP_201_CREATED)
async def relog_meal(
    meal_id: uuid.UUID,
    tz_offset: int = Query(default=0, description="Client timezone offset in minutes"),
    current_user: User = Depends(get_current_user),
    service: MealService = Depends(_get_meal_service),
) -> MealRead:
    """Relog an existing meal with current timestamp and time-mapped meal type."""
    try:
        new_meal = await service.relog_meal(meal_id=meal_id, user_id=current_user.id, tz_offset=tz_offset)
    except MealNotFoundError as exc:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(exc)) from exc
    return MealRead.model_validate(new_meal)


@router.get("/{meal_id}", response_model=MealRead)
async def get_meal(
    meal_id: uuid.UUID,
    current_user: User = Depends(get_current_user),
    service: MealService = Depends(_get_meal_service),
) -> MealRead:
    """Get a single meal by ID if owned by the authenticated user."""
    try:
        meal = await service.get_meal(meal_id, user_id=current_user.id)
    except MealNotFoundError as exc:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(exc)) from exc
    return MealRead.model_validate(meal)


@router.patch("/{meal_id}", response_model=MealRead)
async def update_meal(
    meal_id: uuid.UUID,
    payload: MealUpdate,
    current_user: User = Depends(get_current_user),
    service: MealService = Depends(_get_meal_service),
) -> MealRead:
    """Update a meal if owned by the authenticated user."""
    try:
        meal = await service.update_meal(meal_id, payload, user_id=current_user.id)
    except MealNotFoundError as exc:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(exc)) from exc
    return MealRead.model_validate(meal)


@router.delete("/{meal_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_meal(
    meal_id: uuid.UUID,
    current_user: User = Depends(get_current_user),
    service: MealService = Depends(_get_meal_service),
) -> None:
    """Delete a meal if owned by the authenticated user."""
    try:
        await service.delete_meal(meal_id, user_id=current_user.id)
    except MealNotFoundError as exc:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(exc)) from exc
