"""Aggregates all v1 route modules."""

from fastapi import APIRouter

from app.api.v1 import (
    analysis,
    auth,
    favorites,
    goals,
    health,
    meals,
    nutrition,
    uploads,
    users,
    water,
    weight,
)

router = APIRouter(prefix="/v1")

router.include_router(health.router)
router.include_router(auth.router)
router.include_router(users.router)
router.include_router(goals.router)
router.include_router(favorites.router)
router.include_router(meals.router)
router.include_router(nutrition.router)
router.include_router(analysis.router)
router.include_router(uploads.router)
router.include_router(water.router)
router.include_router(weight.router)


