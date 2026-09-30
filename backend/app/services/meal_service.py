"""Meal orchestration and persistence.

Two distinct responsibilities live here, kept deliberately separate per
the task spec:

  1. `analyze_image` — orchestrates Gemini -> NutritionService for a
     photo, WITHOUT touching the database. Pure analysis.
  2. `create_meal` / `get_meal` / ... — persistence of a meal a user has
     chosen to save (possibly built from an analysis result, possibly
     edited first).
"""

import hashlib
import logging
import uuid

from fastapi import UploadFile
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.models.meal import Meal
from app.models.meal_item import MealItem
from app.schemas.analysis import (
    GeminiAnalysisResult,
    MealAnalysisResponse,
    MealItemAnalysis,
)
from app.schemas.meal import MealCreate, MealUpdate
from app.schemas.nutrition import NutritionSummary
from app.schemas.verification import VerificationStatus
from app.services.calorie_verification_service import (
    CalorieVerificationService,
    VerificationInput,
)
from app.services.gemini_service import GeminiService
from app.services.nutrition_service import (
    NutritionService,
    convert_quantity_to_grams,
)
from app.utils.image import resize_if_needed, save_image_bytes, validate_and_read_image

logger = logging.getLogger(__name__)

# In-memory image analysis cache keyed by SHA-256 content hash.
# Version suffix v2 ensures automatic cache busting across engine upgrades.
_IMAGE_ANALYSIS_CACHE: dict[str, MealAnalysisResponse] = {}

# Known composite dishes and their typical component ingredients / toppings.
# Prevents double-counting child ingredients that are already constituents of the dish.
COMPOSITE_DISH_COMPONENTS: dict[str, set[str]] = {
    "pizza": {
        "cheese", "mozzarella", "mozzarella cheese", "tomato", "tomato sauce", "pizza sauce", "crust",
        "pepper", "bell pepper", "green bell pepper", "red bell pepper", "capsicum",
        "onion", "olives", "black olives", "mushroom", "mushrooms", "paneer",
        "corn", "sweet corn", "jalapeno", "basil", "oregano", "pepperoni", "sausage",
    },
    "cheese_pizza": {
        "cheese", "mozzarella", "mozzarella cheese", "tomato", "tomato sauce", "pizza sauce", "crust",
        "pepper", "bell pepper", "green bell pepper", "red bell pepper", "capsicum",
        "onion", "olives", "black olives", "mushroom", "mushrooms", "paneer",
        "corn", "sweet corn", "jalapeno", "basil", "oregano", "pepperoni", "sausage",
    },
    "burger": {
        "bun", "burger bun", "patty", "cheese", "cheddar cheese", "lettuce",
        "tomato", "onion", "sauce", "mayo", "mayonnaise", "ketchup", "pickles",
    },
    "cheeseburger": {
        "bun", "burger bun", "patty", "cheese", "cheddar cheese", "lettuce",
        "tomato", "onion", "sauce", "mayo", "mayonnaise", "ketchup", "pickles",
    },
    "sandwich": {
        "bread", "bread slice", "toast", "cheese", "butter", "lettuce",
        "tomato", "cucumber", "onion", "mayo",
    },
    "biryani": {
        "rice", "basmati rice", "cooked basmati rice", "chicken", "meat", "mutton",
        "paneer", "spices", "onion", "fried onion", "ghee", "yogurt", "raita",
    },
    "pav_bhaji": {
        "bhaji", "mashed vegetables", "pav", "bread", "butter", "onion", "lemon", "coriander",
    },
    "poha": {
        "flattened rice", "poha", "peanuts", "onion", "potato", "curry leaves", "sev", "coriander",
    },
    "pasta": {
        "pasta", "spaghetti", "penne", "sauce", "tomato sauce", "cheese", "parmesan", "garlic", "olive oil",
    },
    "salad": {
        "lettuce", "tomato", "cucumber", "onion", "carrot", "dressing", "olive oil", "croutons", "olives",
    },
    "taco": {
        "tortilla", "taco shell", "meat", "beef", "chicken", "cheese", "lettuce", "salsa", "sour cream",
    },
    "burrito": {
        "tortilla", "rice", "beans", "black beans", "meat", "cheese", "salsa",
    },
}


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

        IMAGE -> validate -> content SHA-256 check -> GeminiService -> FoodDetection[]
              -> Anti-Double-Counting -> NutritionService -> CalorieVerificationService
              -> validate_final_meal -> MealAnalysisResponse
        """
        validated = await validate_and_read_image(upload)
        optimized = resize_if_needed(validated)

        # Check content-hash cache first (SHA-256 guarantees cache validity across identical images)
        content_hash = hashlib.sha256(optimized.content).hexdigest()
        cache_key = f"{content_hash}:v2"
        if cache_key in _IMAGE_ANALYSIS_CACHE:
            logger.info("Serving meal analysis from SHA-256 content cache (%s)", cache_key[:12])
            return _IMAGE_ANALYSIS_CACHE[cache_key].model_copy(deep=True)

        detection_result: GeminiAnalysisResult = await self.gemini_service.detect_foods(
            image_bytes=optimized.content, mime_type=optimized.content_type
        )

        # Identify composite dishes present in the detections
        composite_dishes: list[tuple[str, str]] = []  # (dish_key, display_name)
        for d in detection_result.foods:
            d_name = d.name.lower().strip()
            for comp_key in COMPOSITE_DISH_COMPONENTS:
                if comp_key in d_name or d_name in comp_key:
                    composite_dishes.append((comp_key, d.name))
                    break

        items: list[MealItemAnalysis] = []
        unmatched_items: list[str] = []
        total_cals = 0.0
        total_p = 0.0
        total_c = 0.0
        total_f = 0.0
        total_fib = 0.0

        for detection in detection_result.foods:
            det_name_clean = detection.name.lower().strip()

            # Anti-Double-Counting check:
            # Is this item a constituent component/topping of an already detected composite dish?
            is_component = False
            parent_dish_name: str | None = None

            if composite_dishes:
                for comp_key, parent_name in composite_dishes:
                    if detection.name != parent_name:
                        components = COMPOSITE_DISH_COMPONENTS[comp_key]
                        # Check if detection matches any known topping/ingredient of this dish
                        if any(c in det_name_clean or det_name_clean in c for c in components):
                            is_component = True
                            parent_dish_name = parent_name
                            break

            nutrition = await self.nutrition_service.calculate_for_detection(
                name=detection.name,
                quantity=detection.estimated_quantity,
                unit=detection.unit.value,
            )

            is_matched = nutrition.matched
            if not is_matched:
                unmatched_items.append(detection.name)

            grams = (
                convert_quantity_to_grams(
                    nutrition.matched_food, detection.estimated_quantity, detection.unit.value
                )
                if nutrition.matched_food
                else detection.estimated_quantity
            )

            v_input = VerificationInput(
                food_name=detection.name,
                detected_quantity=detection.estimated_quantity,
                unit=detection.unit.value,
                grams=grams,
                calories=nutrition.calories,
                protein=nutrition.protein,
                carbohydrates=nutrition.carbohydrates,
                fat=nutrition.fat,
                fiber=nutrition.fiber,
                nutrition_source="local_database" if is_matched else "ai_estimate",
                food_confidence=detection.confidence,
                is_matched_in_db=is_matched,
                is_component=is_component,
                parent_food=parent_dish_name,
            )
            verification = CalorieVerificationService.verify(v_input)

            ref_cals = (
                round(nutrition.reference_calories, 2)
                if is_matched and nutrition.matched_food
                else None
            )
            ref_p = (
                round(nutrition.reference_protein, 2)
                if is_matched and nutrition.matched_food
                else None
            )
            ref_c = (
                round(nutrition.reference_carbohydrates, 2)
                if is_matched and nutrition.matched_food
                else None
            )
            ref_f = (
                round(nutrition.reference_fat, 2)
                if is_matched and nutrition.matched_food
                else None
            )
            ref_fib = (
                round(nutrition.reference_fiber, 2)
                if is_matched and nutrition.matched_food
                else None
            )

            item_analysis = MealItemAnalysis(
                name=detection.name,
                quantity=detection.estimated_quantity,
                unit=detection.unit,
                estimated_calories=verification.final_calories if not is_component else 0.0,
                original_calories=verification.original_calories,
                final_calories=verification.final_calories if not is_component else 0.0,
                protein=nutrition.protein if not is_component else 0.0,
                carbohydrates=nutrition.carbohydrates if not is_component else 0.0,
                fat=nutrition.fat if not is_component else 0.0,
                fiber=nutrition.fiber if not is_component else 0.0,
                confidence=detection.confidence,
                matched=is_matched,
                matched_food_id=str(nutrition.matched_food.id)
                if is_matched and nutrition.matched_food
                else None,
                bounding_box=detection.bounding_box,
                verification=verification,
                is_component=is_component,
                parent_food=parent_dish_name,
                reference_serving_size=nutrition.reference_serving_size,
                reference_serving_unit=nutrition.reference_serving_unit,
                reference_calories_per_100g=ref_cals,
                reference_protein_per_100g=ref_p,
                reference_carbs_per_100g=ref_c,
                reference_fat_per_100g=ref_f,
                reference_fiber_per_100g=ref_fib,
            )
            items.append(item_analysis)

            # Only sum standalone foods into meal totals (anti-double counting)
            if not is_component:
                total_cals += verification.final_calories
                total_p += nutrition.protein
                total_c += nutrition.carbohydrates
                total_f += nutrition.fat
                total_fib += nutrition.fiber

        total = NutritionSummary(
            estimated_calories=round(total_cals, 2),
            protein=round(total_p, 2),
            carbohydrates=round(total_c, 2),
            fat=round(total_f, 2),
            fiber=round(total_fib, 2),
        )

        # Run final safety validation gate on the aggregated meal
        overall_status, meal_warnings = CalorieVerificationService.validate_final_meal(
            items=items, total=total
        )

        image_url: str | None = None
        try:
            image_url = save_image_bytes(optimized.content, optimized.content_type)
        except Exception:
            pass

        response = MealAnalysisResponse(
            total=total,
            items=items,
            unmatched_items=unmatched_items,
            image_url=image_url,
            verification_status=overall_status,
            warnings=meal_warnings,
        )

        # Store in content cache
        if len(_IMAGE_ANALYSIS_CACHE) > 100:
            _IMAGE_ANALYSIS_CACHE.clear()
        _IMAGE_ANALYSIS_CACHE[cache_key] = response.model_copy(deep=True)

        return response

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
            if payload.created_at.tzinfo is None:
                from datetime import UTC
                meal.created_at = payload.created_at.replace(tzinfo=UTC)
            else:
                meal.created_at = payload.created_at
        meal.items = [
            MealItem(
                food_id=item.food_id,
                food_name=item.food_name,
                quantity=item.quantity,
                unit=item.unit.value if hasattr(item.unit, "value") else str(item.unit),
                calories=item.calories,
                protein=item.protein,
                carbohydrates=item.carbohydrates,
                fat=item.fat,
                fiber=item.fiber,
                confidence=item.confidence,
                original_calories=item.original_calories,
                final_calories=item.final_calories,
                verification_status=item.verification_status,
                verification_confidence=item.verification_confidence,
                verification_sources=item.verification_sources,
                verification_note=item.verification_note,
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
