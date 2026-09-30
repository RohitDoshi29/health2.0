"""Profile calculations service — BMR, TDEE, Calorie/Macro goals using Mifflin-St Jeor."""

from app.schemas.profile import NutritionTargets, UserProfileBase

ACTIVITY_MULTIPLIERS: dict[str, float] = {
    "sedentary": 1.2,
    "light": 1.375,
    "moderate": 1.55,
    "active": 1.725,
    "very_active": 1.9,
}

GOAL_CALORIE_ADJUSTMENTS: dict[str, float] = {
    "lose": -500.0,
    "maintain": 0.0,
    "gain": 300.0,
}

MIN_CALORIE_FLOORS: dict[str, float] = {
    "male": 1500.0,
    "female": 1200.0,
}


class ProfileService:
    @staticmethod
    def calculate_bmr(weight_kg: float, height_cm: float, age: int, sex: str) -> float:
        """Calculate Basal Metabolic Rate (BMR) using the Mifflin-St Jeor formula."""
        base = 10.0 * weight_kg + 6.25 * height_cm - 5.0 * age
        if sex.lower() == "male":
            return round(base + 5.0, 1)
        return round(base - 161.0, 1)

    @staticmethod
    def calculate_targets(data: UserProfileBase) -> NutritionTargets:
        """Compute full nutrition targets from biometric profile."""
        bmr = ProfileService.calculate_bmr(
            weight_kg=data.weight_kg,
            height_cm=data.height_cm,
            age=data.age,
            sex=data.sex,
        )

        multiplier = ACTIVITY_MULTIPLIERS.get(data.activity_level.lower(), 1.2)
        tdee = round(bmr * multiplier, 1)

        adjustment = GOAL_CALORIE_ADJUSTMENTS.get(data.goal.lower(), 0.0)
        raw_calories = tdee + adjustment

        # Enforce floor safety clamping: never below 1200 (female) or 1500 (male)
        floor = MIN_CALORIE_FLOORS.get(data.sex.lower(), 1200.0)
        target_calories = round(max(floor, raw_calories), 0)

        # Protein: 1.2 g/kg for maintain, 1.6 g/kg for lose/gain
        protein_factor = 1.2 if data.goal.lower() == "maintain" else 1.6
        protein_target = round(protein_factor * data.weight_kg, 1)

        # Fat: 25% of calories
        fat_calories = target_calories * 0.25
        fat_target = round(fat_calories / 9.0, 1)

        # Carbs: remainder of calories
        consumed_macro_cals = (protein_target * 4.0) + (fat_target * 9.0)
        carb_calories = max(0.0, target_calories - consumed_macro_cals)
        carbs_target = round(carb_calories / 4.0, 1)

        # Fiber: 14g per 1000 kcal
        fiber_target = round((target_calories / 1000.0) * 14.0, 1)

        # Water: weight * 35 ml or at least 2500 ml
        water_target = round(max(2500.0, data.weight_kg * 35.0), 0)

        return NutritionTargets(
            bmr=bmr,
            tdee=tdee,
            calorie_target=target_calories,
            protein_target=protein_target,
            carbohydrates_target=carbs_target,
            fat_target=fat_target,
            fiber_target=fiber_target,
            water_target_ml=water_target,
        )
