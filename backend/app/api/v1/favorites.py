"""Favorite meal templates endpoints."""

import uuid

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.core.security import get_current_user
from app.models.favorite import FavoriteMeal
from app.models.user import User
from app.schemas.favorite import FavoriteCreate, FavoriteRead
from app.schemas.meal import MealCreate, MealItemCreate, MealRead
from app.services.meal_service import MealService

router = APIRouter(prefix="/favorites", tags=["favorites"])


@router.get("", response_model=list[FavoriteRead])
async def list_favorites(
    limit: int = Query(default=50, ge=1, le=100),
    offset: int = Query(default=0, ge=0),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> list[FavoriteRead]:
    """List all saved favorite templates for the authenticated user."""
    query = (
        select(FavoriteMeal)
        .where(FavoriteMeal.user_id == current_user.id)
        .order_by(FavoriteMeal.created_at.desc())
        .offset(offset)
        .limit(limit)
    )
    result = await db.execute(query)
    favorites = list(result.scalars().all())
    return [FavoriteRead.model_validate(f) for f in favorites]


@router.post("", response_model=FavoriteRead, status_code=status.HTTP_201_CREATED)
async def create_favorite(
    payload: FavoriteCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> FavoriteRead:
    """Save a meal template into the user's favorites."""
    items_data = [item.model_dump() for item in payload.items]

    total_calories = round(sum(i["calories"] for i in items_data), 1)
    total_protein = round(sum(i["protein"] for i in items_data), 1)
    total_carbohydrates = round(sum(i["carbohydrates"] for i in items_data), 1)
    total_fat = round(sum(i["fat"] for i in items_data), 1)
    total_fiber = round(sum(i["fiber"] for i in items_data), 1)

    favorite = FavoriteMeal(
        user_id=current_user.id,
        name=payload.name.strip(),
        meal_type=payload.meal_type,
        items_json=items_data,
        total_calories=total_calories,
        total_protein=total_protein,
        total_carbohydrates=total_carbohydrates,
        total_fat=total_fat,
        total_fiber=total_fiber,
    )
    db.add(favorite)
    await db.commit()
    await db.refresh(favorite)
    return FavoriteRead.model_validate(favorite)


@router.delete("/{favorite_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_favorite(
    favorite_id: uuid.UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> None:
    """Delete a saved favorite template."""
    query = select(FavoriteMeal).where(
        FavoriteMeal.id == favorite_id, FavoriteMeal.user_id == current_user.id
    )
    result = await db.execute(query)
    favorite = result.scalar_one_or_none()
    if favorite is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Favorite not found.")

    await db.delete(favorite)
    await db.commit()


@router.post("/{favorite_id}/log", response_model=MealRead, status_code=status.HTTP_201_CREATED)
async def quick_log_favorite(
    favorite_id: uuid.UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> MealRead:
    """1-Tap Log: creates a logged meal for today directly from a favorite template."""
    query = select(FavoriteMeal).where(
        FavoriteMeal.id == favorite_id, FavoriteMeal.user_id == current_user.id
    )
    result = await db.execute(query)
    favorite = result.scalar_one_or_none()
    if favorite is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Favorite not found.")

    meal_items = [
        MealItemCreate(
            food_id=uuid.UUID(i["food_id"]) if i.get("food_id") else None,
            food_name=i["food_name"],
            quantity=i["quantity"],
            unit=i["unit"],
            calories=i["calories"],
            protein=i["protein"],
            carbohydrates=i["carbohydrates"],
            fat=i["fat"],
            fiber=i["fiber"],
        )
        for i in favorite.items_json
    ]

    meal_payload = MealCreate(
        meal_type=favorite.meal_type,
        items=meal_items,
    )

    from app.services.gemini_service import get_gemini_service

    gemini_service = get_gemini_service()
    service = MealService(db=db, gemini_service=gemini_service)
    meal = await service.create_meal(payload=meal_payload, user_id=current_user.id)
    return MealRead.model_validate(meal)
