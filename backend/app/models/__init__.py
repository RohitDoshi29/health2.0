"""ORM models.

Imported explicitly so that `Base.metadata` is fully populated for
Alembic autogenerate and for `Base.metadata.create_all` in tests.
"""

from app.models.favorite import FavoriteMeal
from app.models.food import Food
from app.models.goal import Goal
from app.models.meal import Meal
from app.models.meal_item import MealItem
from app.models.user import User
from app.models.user_profile import UserProfile
from app.models.water_log import WaterLog
from app.models.weight_log import WeightLog

__all__ = [
    "User",
    "UserProfile",
    "WeightLog",
    "Food",
    "Meal",
    "MealItem",
    "Goal",
    "FavoriteMeal",
    "WaterLog",
]

