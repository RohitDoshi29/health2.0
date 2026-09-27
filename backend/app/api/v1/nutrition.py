"""Nutrition / Food catalog endpoints."""

import uuid

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.schemas.barcode import BarcodeProductRead
from app.schemas.nutrition import FoodRead
from app.services.barcode_service import BarcodeService, BarcodeServiceError
from app.services.nutrition_service import NutritionService

router = APIRouter(prefix="/nutrition", tags=["nutrition"])


@router.get("/foods", response_model=list[FoodRead])
async def list_foods(
    limit: int = Query(default=100, ge=1, le=500),
    offset: int = Query(default=0, ge=0),
    db: AsyncSession = Depends(get_db),
) -> list[FoodRead]:
    service = NutritionService(db)
    foods = await service.list_foods(limit=limit, offset=offset)
    return [FoodRead.model_validate(f) for f in foods]


@router.get("/foods/search", response_model=list[FoodRead])
async def search_foods(
    q: str = Query(min_length=1, description="Search term, e.g. 'rice'"),
    db: AsyncSession = Depends(get_db),
) -> list[FoodRead]:
    service = NutritionService(db)
    foods = await service.search_foods(q)
    return [FoodRead.model_validate(f) for f in foods]


@router.get("/foods/{food_id}", response_model=FoodRead)
async def get_food(food_id: uuid.UUID, db: AsyncSession = Depends(get_db)) -> FoodRead:
    service = NutritionService(db)
    food = await service.get_food_by_id(food_id)
    if food is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Food not found.")
    return FoodRead.model_validate(food)


@router.get("/barcode/{barcode}", response_model=BarcodeProductRead)
async def lookup_barcode(barcode: str) -> BarcodeProductRead:
    """Query OpenFoodFacts API to retrieve product nutrition and metadata for a barcode."""
    service = BarcodeService()
    try:
        product = await service.lookup_barcode(barcode)
    except BarcodeServiceError as exc:
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail=f"Failed to lookup barcode: {exc}",
        ) from exc

    if product is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Product with barcode '{barcode}' was not found in OpenFoodFacts database.",
        )

    return product

