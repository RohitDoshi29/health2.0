"""Food-photo analysis endpoint.

POST /api/v1/analysis/analyze — analyzes an image and returns estimated
nutrition. Deliberately does NOT save anything; saving is a separate,
explicit step via POST /api/v1/meals.
"""

from fastapi import APIRouter, Depends, File, HTTPException, Request, UploadFile, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.core.limiter import limiter
from app.schemas.analysis import MealAnalysisResponse
from app.services.gemini_service import (
    GeminiResponseParsingError,
    GeminiService,
    GeminiServiceError,
    get_gemini_service,
)
from app.services.meal_service import MealService
from app.utils.image import ImageTooLargeError, InvalidImageError

router = APIRouter(prefix="/analysis", tags=["analysis"])


@router.post("/analyze", response_model=MealAnalysisResponse)
@limiter.limit("15/minute")
async def analyze_meal_image(
    request: Request,
    image: UploadFile = File(..., description="Food photo (JPEG/PNG/WEBP)"),
    db: AsyncSession = Depends(get_db),
    gemini_service: GeminiService = Depends(get_gemini_service),
) -> MealAnalysisResponse:

    service = MealService(db=db, gemini_service=gemini_service)

    try:
        return await service.analyze_image(image)
    except InvalidImageError as exc:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(exc)) from exc
    except ImageTooLargeError as exc:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST, detail=str(exc)
        ) from exc
    except GeminiServiceError as exc:
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail="The AI food-recognition service is currently unavailable.",
        ) from exc
    except GeminiResponseParsingError as exc:
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail="The AI food-recognition service returned an unexpected response.",
        ) from exc
