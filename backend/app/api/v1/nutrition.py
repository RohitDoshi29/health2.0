"""Nutrition / Food catalog endpoints."""

import uuid

from fastapi import APIRouter, Depends, File, HTTPException, Query, UploadFile, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.core.security import get_current_user
from app.models.user import User
from app.schemas.barcode import BarcodeProductRead
from app.schemas.nutrition import FoodRead
from app.schemas.portion import PortionGuideRead
from app.services.barcode_service import BarcodeService, BarcodeServiceError
from app.services.gemini_service import GeminiService
from app.services.nutrition_service import NutritionService
from app.services.portion_service import PortionService

router = APIRouter(prefix="/nutrition", tags=["nutrition"])


@router.get("/portions", response_model=list[PortionGuideRead])
async def search_portions(
    q: str | None = Query(default=None, description="Search term, e.g. 'dal' or 'katori'"),
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> list[PortionGuideRead]:
    """Search available portion guides by food canonical name or label."""
    service = PortionService(db)
    portions = await service.search_portions(q)
    return [PortionGuideRead.model_validate(p) for p in portions]


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


@router.get("/foods/{food_id}/portions", response_model=list[PortionGuideRead])
async def get_food_portions(
    food_id: uuid.UUID,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> list[PortionGuideRead]:
    """Retrieve portion guides for a specific food item."""
    service = PortionService(db)
    portions = await service.get_portions_for_food(food_id)
    if portions is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Food not found.")
    return [PortionGuideRead.model_validate(p) for p in portions]


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


@router.post("/barcode/scan-image", response_model=BarcodeProductRead)
async def scan_barcode_from_image(
    file: UploadFile = File(...),
) -> BarcodeProductRead:
    """Extract barcode from an uploaded image using Gemini OCR and query OpenFoodFacts."""
    mime_type = file.content_type or "image/jpeg"
    image_bytes = await file.read()
    if not image_bytes:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Empty image uploaded.",
        )

    gemini_svc = GeminiService()
    barcode = await gemini_svc.extract_barcode(image_bytes, mime_type)
    if not barcode:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="Could not detect a clear barcode in the provided image.",
        )

    barcode_svc = BarcodeService()
    try:
        product = await barcode_svc.lookup_barcode(barcode)
    except BarcodeServiceError as exc:
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail=f"Failed to lookup barcode '{barcode}': {exc}",
        ) from exc

    if product is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Detected barcode '{barcode}', but no matching product was found in OpenFoodFacts.",
        )

    return product

