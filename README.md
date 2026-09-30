# Heathify 2.0 — Nutrition Tracking System

Heathify is a full-stack nutrition tracking application with a **FastAPI** async backend and a **Flutter** cross-platform mobile frontend.

---

## 6 Core Features Implementation Summary

### 1. Onboarding Calculator
- **Description**: Collects user biological metrics and computes BMR and TDEE using the Mifflin-St Jeor formula, establishes daily caloric targets based on primary goal (`lose`, `maintain`, `gain`) with safe floor clamping (1200 kcal female / 1500 kcal male), and calculates macro splits.
- **Endpoints**:
  - `POST /api/v1/users/me/profile`: Saves user profile, computes targets, updates user goal, and returns profile & goal.
  - `GET /api/v1/users/me/profile`: Fetches current profile and computed BMR/TDEE.
  - `POST /api/v1/users/me/profile/preview`: Calculates BMR, TDEE, and targets without persisting (for live UI feedback).
- **Request Example**:
  ```json
  POST /api/v1/users/me/profile
  {
    "age": 28,
    "sex": "male",
    "height_cm": 178.0,
    "weight_kg": 75.0,
    "activity_level": "moderate",
    "goal": "lose"
  }
  ```
- **Response Example**:
  ```json
  {
    "profile": {
      "user_id": "90e3df84-3c66-4d2a-8d32-d8cb877c8e22",
      "age": 28,
      "sex": "male",
      "height_cm": 178.0,
      "weight_kg": 75.0,
      "activity_level": "moderate",
      "goal": "lose",
      "onboarding_completed": true
    },
    "goal": {
      "target_calories": 2154.0,
      "target_protein": 120.0,
      "target_carbohydrates": 268.0,
      "target_fat": 60.0,
      "target_fiber": 30.0,
      "target_water_ml": 2625.0
    },
    "bmr": 1712.5,
    "tdee": 2654.4
  }
  ```
- **Database Migration**: `0008_add_user_profile.py` (`user_profiles` table).

---

### 2. Weight Tracking
- **Description**: Allows users to log historical body weights with optional notes, view 7/30/90 day trends, delete logs, and displays a dual-axis trend chart overlaying daily calorie intake on body weight. Automatically syncs the latest logged weight back to the user profile.
- **Endpoints**:
  - `POST /api/v1/weight`: Logs a weight entry (`weight_kg`, `logged_at`, `note`).
  - `GET /api/v1/weight/history?days=30`: Returns weight history entries along with daily calorie summaries.
  - `DELETE /api/v1/weight/{id}`: Deletes a specific weight log.
- **Request Example**:
  ```json
  POST /api/v1/weight
  {
    "weight_kg": 74.2,
    "note": "Morning weigh-in after workout"
  }
  ```
- **Response Example**:
  ```json
  {
    "id": "18f98c76-23b1-419b-a0d4-d5f0b5d8434a",
    "weight_kg": 74.2,
    "logged_at": "2026-09-30T07:15:00Z",
    "note": "Morning weigh-in after workout"
  }
  ```
- **Database Migration**: `0009_add_weight_logs.py` (`weight_logs` table).

---

### 3. Streaks & Daily Score
- **Description**: Calculates consecutive daily logging streaks and evaluates an objective 0–100 daily score:
  - 40 pts: Calories within ±10% of target (linearly scaled down outside).
  - 30 pts: Protein ≥ 90% of target.
  - 15 pts: Fiber ≥ 80% of target.
  - 15 pts: Water ≥ 100% of target.
  - Returns badges: `streak_3`, `streak_7`, `streak_14`, `streak_30`, `hit_protein_today`.
- **Endpoints**:
  - `GET /api/v1/analytics/streaks?tz_offset=330`
- **Response Example**:
  ```json
  {
    "current_logging_streak": 5,
    "longest_streak": 12,
    "days_logged_this_week": 4,
    "today_score": 85,
    "breakdown": {
      "calorie_points": 40.0,
      "protein_points": 30.0,
      "fiber_points": 0.0,
      "water_points": 15.0,
      "notes": [
        "Calories within target range (+40 pts)",
        "Protein target achieved (+30 pts)",
        "Water target achieved (+15 pts)"
      ]
    },
    "badges": [
      {
        "id": "streak_3",
        "name": "3-Day Streak",
        "description": "Logged meals for 3 consecutive days",
        "unlocked": true,
        "icon": "local_fire_department"
      },
      {
        "id": "hit_protein_today",
        "name": "Protein Champion",
        "description": "Hit 90%+ of your daily protein target today",
        "unlocked": true,
        "icon": "fitness_center"
      }
    ]
  }
  ```

---

### 4. Weekly Nutrition Report
- **Description**: Aggregates average intake across 7 days, detects best and worst days by daily score, checks goal hits per nutrient (e.g. "protein 5/7 days"), displays weight changes, and compares intake vs. the previous week.
- **Endpoints**:
  - `GET /api/v1/analytics/weekly?tz_offset=330&week_offset=0`
- **Response Example**:
  ```json
  {
    "start_date": "2026-09-24",
    "end_date": "2026-09-30",
    "days_logged": 6,
    "average_calories": 2040.0,
    "average_protein": 118.5,
    "average_carbohydrates": 242.0,
    "average_fat": 58.0,
    "average_fiber": 26.5,
    "average_water_ml": 2550.0,
    "best_day": { "date": "2026-09-28", "score": 95 },
    "worst_day": { "date": "2026-09-25", "score": 55 },
    "goal_hits": {
      "calories": "5/7 days",
      "protein": "6/7 days",
      "fiber": "3/7 days",
      "water": "6/7 days"
    },
    "weight_change_kg": -0.8,
    "comparison_vs_previous_week": {
      "calories_diff": -85.0,
      "protein_diff": 4.2,
      "days_logged_diff": 1
    }
  }
  ```

---

### 5. Recent Foods & Log Again
- **Description**: Allows rapid meal re-logging and single-tap autofill from distinct past food items with their last recorded quantity, unit, and nutritional values. Re-logging a past meal duplicates the meal and items, setting the timestamp to now and mapping the meal category to current local hour.
- **Endpoints**:
  - `GET /api/v1/meals/recent-foods?limit=20`
  - `POST /api/v1/meals/{meal_id}/relog?tz_offset=330`
- **Response Example (`POST /api/v1/meals/{meal_id}/relog`)**:
  ```json
  {
    "id": "62bf19d8-9df5-4c07-9da5-f2d40ee19702",
    "user_id": "90e3df84-3c66-4d2a-8d32-d8cb877c8e22",
    "meal_type": "lunch",
    "created_at": "2026-09-30T16:25:00Z",
    "total_calories": 540.0,
    "total_protein": 28.0,
    "total_carbohydrates": 65.0,
    "total_fat": 18.0,
    "total_fiber": 8.0,
    "items": [
      {
        "food_name": "Moong Dal",
        "quantity": 150.0,
        "unit": "katori",
        "calories": 174.0
      },
      {
        "food_name": "Roti",
        "quantity": 80.0,
        "unit": "piece",
        "calories": 240.0
      }
    ]
  }
  ```

---

### 6. Portion Guides & Capping
- **Description**: Stores per-food standard culinary portions (e.g., 1 katori dal = 150g, 1 roti = 40g, 1 slice pizza = 100g, 1 glass milk = 240ml, 1 idli = 50g, 1 dosa = 100g, 1 egg = 50g, 1 tbsp ghee = 15g).
  - Uses per-food portion weights in `convert_quantity_to_grams` where one exists and falls back to generic conversion table.
  - Hard caps any single item at **1,200 g** to prevent runaway calorie explosions.
  - Interactive Flutter portion picker with visual icons and quantity stepper (`0.5, 1.0, 1.5, 2.0...`) in manual entry and scan review.
- **Endpoints**:
  - `GET /api/v1/nutrition/portions?q=dal`
  - `GET /api/v1/nutrition/foods/{food_id}/portions`
- **Response Example**:
  ```json
  [
    {
      "id": "c71f97c4-069a-4f51-b0db-5507ea9921ee",
      "food_canonical_name": "dal",
      "label": "1 katori dal",
      "grams": 150.0,
      "image_asset": "assets/portions/katori.png"
    }
  ]
  ```
- **Database Migration**: `0010_add_portions_table.py` (`portions` table + seeds).

---

## Manual Steps & Setup Instructions

1. **Apply Database Migrations**:
   Run the Alembic migration on your PostgreSQL instance (or via Docker):
   ```bash
   docker exec backend-backend-1 alembic upgrade head
   # or locally:
   cd backend && alembic upgrade head
   ```
   *Migrations applied: `0008_add_user_profile.py`, `0009_add_weight_logs.py`, `0010_add_portions_table.py`.*

2. **Frontend Assets (Optional)**:
   The UI includes fallback Material illustrated icons for all portion types. To display custom illustrations, place PNG assets in `frontend/assets/portions/`:
   - `assets/portions/katori.png` (Dal, rice, curd)
   - `assets/portions/roti.png` (Roti, chapati, paratha)
   - `assets/portions/slice.png` (Pizza, bread)
   - `assets/portions/cup.png` (Tea, coffee)
   - `assets/portions/bowl.png` (Soup, salad)
   - `assets/portions/glass.png` (Milk)
   - `assets/portions/piece.png` (Idli, egg, dosa, samosa)
   - `assets/portions/tbsp.png` (Ghee, oil)
   - `assets/portions/plate.png` (Rice plate)

---

## Assumptions & Design Choices

1. **Authentication**: All new endpoints require `Depends(get_current_user)` using the established JWT Bearer token authentication. User endpoints are strictly scoped to the requesting user.
2. **Timezone Boundaries**: Timezone offsets (`tz_offset` in minutes) are sent by the mobile client. Local date boundaries and hour calculations are derived as `UTC + tz_offset`.
3. **Calorie Floor Clamping**: Calorie goals are prevented from falling below 1,200 kcal for females and 1,500 kcal for males.
4. **Physical Sanity Cap**: Individual food portions are capped at 1,200 g to eliminate mathematical outliers or runaway multipliers.
