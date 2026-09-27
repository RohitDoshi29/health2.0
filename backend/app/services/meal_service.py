"""Meal orchestration and persistence.

Two distinct responsibilities live here, kept deliberately separate per
the task spec:

  1. `analyze_image` — orchestrates Gemini -> NutritionService for a
     photo, WITHOUT touching the database. Pure analysis.
  2. `create_meal` / `get_meal` / ... — persistence of a meal a user has
     chosen to save (possibly built from an analysis result, possibly
     edited first).
"""

import uuid

from fastapi import UploadFile
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.models.meal import Meal
from app.models.meal_item import MealItem
from app.schemas.analysis import GeminiAnalysisResult, MealAnalysisResponse, MealItemAnalysis
from app.schemas.meal import MealCreate, MealUpdate
from app.schemas.nutrition import NutritionSummary
from app.services.gemini_service import GeminiService
from app.services.nutrition_service import NutritionService
from app.utils.image import resize_if_needed, save_image_bytes, validate_and_read_image


class MealServiceError(Exception):
    """Base error for meal-service failures."""


class MealNotFoundError(MealServiceError):
    pass


class MealService:
    def __init__(self, db: AsyncSession, gemini_service: GeminiService) -> None:
        self.db = db
        self.gemini_service = gemini_service
        self.nutrition_service = NutritionService(db)

    # ---- Analysis (no persistence) -----------------------------------

    async def analyze_image(self, upload: UploadFile) -> MealAnalysisResponse:
        """Full analysis pipeline for an uploaded image.

        IMAGE -> validate -> GeminiService -> FoodDetection[]
              -> NutritionService -> NutritionResult[] -> MealAnalysisResponse

        Raises the same exceptions as its collaborators
        (InvalidImageError/ImageTooLargeError, GeminiServiceError,
        GeminiResponseParsingError) — the API layer maps these to HTTP
        status codes.
        """
        validated = await validate_and_read_image(upload)
        optimized = resize_if_needed(validated)

        detection_result: GeminiAnalysisResult = await self.gemini_service.detect_foods(
            image_bytes=optimized.content, mime_type=optimized.content_type
        )


        items: list[MealItemAnalysis] = []
        nutrition_results = []
        unmatched_items: list[str] = []
        for detection in detection_result.foods:
            nutrition = await self.nutrition_service.calculate_for_detection(
                name=detection.name,
                quantity=detection.estimated_quantity,
                unit=detection.unit.value,
            )
            nutrition_results.append(nutrition)

            is_matched = nutrition.matched
            if not is_matched:
                unmatched_items.append(detection.name)

            items.append(
                MealItemAnalysis(
                    name=detection.name,
                    quantity=detection.estimated_quantity,
                    unit=detection.unit,
                    estimated_calories=nutrition.calories,
                    protein=nutrition.protein,
                    carbohydrates=nutrition.carbohydrates,
                    fat=nutrition.fat,
                    fiber=nutrition.fiber,
                    confidence=detection.confidence,
                    matched=is_matched,
                    matched_food_id=str(nutrition.matched_food.id)
                    if is_matched and nutrition.matched_food
                    else None,
                    bounding_box=detection.bounding_box,
                )
            )

        total: NutritionSummary = self.nutrition_service.sum_totals(nutrition_results)
        image_url: str | None = None
        try:
            image_url = save_image_bytes(optimized.content, optimized.content_type)
        except Exception:
            pass

        return MealAnalysisResponse(
            total=total,
            items=items,
            unmatched_items=unmatched_items,
            image_url=image_url,
        )

    # ---- Persistence ----------------------------------------------------

    async def create_meal(self, payload: MealCreate, user_id: uuid.UUID | None = None) -> Meal:
        target_user_id = user_id or payload.user_id
        if target_user_id is None:
            raise MealServiceError("user_id is required to create a meal.")

        totals = {
            "total_calories": sum(i.calories for i in payload.items),
            "total_protein": sum(i.protein for i in payload.items),
            "total_carbohydrates": sum(i.carbohydrates for i in payload.items),
            "total_fat": sum(i.fat for i in payload.items),
            "total_fiber": sum(i.fiber for i in payload.items),
        }

        meal = Meal(
            user_id=target_user_id,
            image_url=payload.image_url,
            meal_type=payload.meal_type,
            **totals,
        )
        if payload.created_at is not None:
            meal.created_at = payload.created_at
        meal.items = [
            MealItem(
                food_id=item.food_id,
                food_name=item.food_name,
                quantity=item.quantity,
                unit=item.unit.value,
                calories=item.calories,
                protein=item.protein,
                carbohydrates=item.carbohydrates,
                fat=item.fat,
                fiber=item.fiber,
                confidence=item.confidence,
            )
            for item in payload.items
        ]

        self.db.add(meal)
        await self.db.commit()
        return await self.get_meal(meal.id, user_id=target_user_id)

    async def get_meal(self, meal_id: uuid.UUID, user_id: uuid.UUID | None = None) -> Meal:
        query = select(Meal).where(Meal.id == meal_id).options(selectinload(Meal.items))
        if user_id is not None:
            query = query.where(Meal.user_id == user_id)

        result = await self.db.execute(query)
        meal = result.scalar_one_or_none()
        if meal is None:
            raise MealNotFoundError(f"Meal {meal_id} not found.")
        return meal

    async def list_meals(
        self, user_id: uuid.UUID | None = None, limit: int = 50, offset: int = 0
    ) -> list[Meal]:
        query = select(Meal).options(selectinload(Meal.items)).offset(offset).limit(limit)
        if user_id is not None:
            query = query.where(Meal.user_id == user_id)
        result = await self.db.execute(query.order_by(Meal.created_at.desc()))
        return list(result.scalars().all())

    async def update_meal(
        self, meal_id: uuid.UUID, payload: MealUpdate, user_id: uuid.UUID | None = None
    ) -> Meal:
        meal = await self.get_meal(meal_id, user_id=user_id)
        if payload.image_url is not None:
            meal.image_url = payload.image_url
        if payload.meal_type is not None:
            meal.meal_type = payload.meal_type
        await self.db.commit()
        return await self.get_meal(meal_id, user_id=user_id)


    async def delete_meal(self, meal_id: uuid.UUID, user_id: uuid.UUID | None = None) -> None:
        meal = await self.get_meal(meal_id, user_id=user_id)
        await self.db.delete(meal)
        await self.db.commit()

