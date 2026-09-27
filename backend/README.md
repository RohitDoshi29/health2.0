# Heathify API — Backend Foundation

Heathify is a nutrition-tracking application. A user takes or uploads a
photo of their food, the backend sends it to Google's **Gemini API** for
food identification and portion estimation, maps the identified foods to
a nutrition database, calculates estimated calories/macros, and returns
structured nutrition data. Users can later save, edit, and view meals.

This repository is **only the backend foundation** — a clean, modular
scaffold intended to be expanded in future phases. It does **not**
include the mobile app, a frontend, a production ML pipeline, payments,
notifications, or an admin dashboard.

> **Product note:** all nutrition values returned by this API are
> **estimates** derived from an AI-identified photo and a reference
> nutrition database — never claimed to be medically exact.

---

## 1. Architecture

```
IMAGE
  │
  ▼
validate (MIME type, size, magic bytes)      → app/utils/image.py
  │
  ▼
GeminiService                                 → app/services/gemini_service.py
  │  (food identification + portion estimate + confidence — NOT calories)
  ▼
FoodDetection[]
  │
  ▼
NutritionService                              → app/services/nutrition_service.py
  │  (name normalization → Food lookup → deterministic scaling)
  ▼
NutritionResult[]
  │
  ▼
MealAnalysisResponse                          → returned to client
```

`MealService` (`app/services/meal_service.py`) orchestrates the pipeline
above and keeps it out of the FastAPI route, which stays thin. Analysis
(`POST /api/v1/analysis/analyze`) never writes to the database — saving a
meal is a deliberate, separate step (`POST /api/v1/meals`).

### Layers

| Layer | Responsibility |
|---|---|
| `app/api/` | Thin HTTP routes. Validate input, call a service, map exceptions → HTTP status codes. |
| `app/services/` | Business logic: Gemini calls, nutrition calculation, meal orchestration/persistence. |
| `app/models/` | SQLAlchemy ORM models. |
| `app/schemas/` | Pydantic request/response models. |
| `app/core/` | Config, database engine/session, auth placeholder. |
| `app/utils/` | Small stateless helpers (image validation). |

---

## 2. Technology Stack

- **Python 3.12+**, **FastAPI**, **Uvicorn**
- **Pydantic v2** / **pydantic-settings**
- **SQLAlchemy 2.x** (async) + **asyncpg** + **PostgreSQL**
- **Alembic** for migrations
- **httpx** for outbound HTTP where needed
- **google-genai** for the Gemini API
- **pytest** / **pytest-asyncio** for tests
- **Ruff** for linting
- **Docker** + **docker-compose**

---

## 3. Folder Structure

```
backend/
├── app/
│   ├── main.py                  # FastAPI app, CORS, root/health routes
│   ├── core/
│   │   ├── config.py             # Pydantic Settings (env-driven)
│   │   ├── database.py           # async engine, session factory, Base
│   │   └── security.py           # placeholder auth (X-User-Id header) + TODOs
│   ├── api/
│   │   ├── router.py             # mounts /api
│   │   └── v1/
│   │       ├── router.py         # mounts /api/v1
│   │       ├── health.py         # GET /api/v1/health
│   │       ├── users.py          # POST/GET /api/v1/users
│   │       ├── meals.py          # CRUD /api/v1/meals
│   │       ├── nutrition.py      # GET /api/v1/nutrition/foods...
│   │       └── analysis.py       # POST /api/v1/analysis/analyze
│   ├── models/                   # User, Food, Meal, MealItem
│   ├── schemas/                  # user, meal, nutrition, analysis
│   ├── services/
│   │   ├── gemini_service.py     # Gemini call + prompt + response validation
│   │   ├── nutrition_service.py  # name normalization + deterministic scaling
│   │   └── meal_service.py       # orchestration + meal persistence
│   └── utils/
│       └── image.py              # MIME/size/magic-byte validation
├── scripts/
│   └── seed_foods.py             # populates a handful of sample foods
├── tests/
│   ├── conftest.py               # SQLite test DB + fake Gemini service
│   ├── test_health.py
│   ├── test_analysis.py
│   └── test_nutrition.py
├── alembic/
│   ├── env.py                    # async-aware migration environment
│   └── versions/0001_initial_schema.py
├── .env.example
├── .gitignore
├── requirements.txt
├── Dockerfile
├── docker-compose.yml
├── alembic.ini
└── pyproject.toml
```

---

## 4. Environment Variables

Copy `.env.example` to `.env` and fill in real values:

```
APP_NAME=Heathify API
ENVIRONMENT=development
DATABASE_URL=postgresql+asyncpg://postgres:postgres@db:5432/heathify
GEMINI_API_KEY=              # get one at https://aistudio.google.com/app/apikey
GEMINI_MODEL=gemini-2.5-flash
CORS_ORIGINS=http://localhost:3000,http://localhost:5173
MAX_UPLOAD_SIZE_MB=8
USDA_API_KEY=                # optional: get free key at https://fdc.nal.usda.gov/api-key-signup.html
```

`.env` is git-ignored. Never commit real secrets — `GEMINI_API_KEY` in
particular.


---

## 5. Running Locally (without Docker)

```bash
# 1. Create a virtual environment
python3.12 -m venv .venv
source .venv/bin/activate

# 2. Install dependencies
pip install -r requirements.txt

# 3. Configure environment
cp .env.example .env
# edit .env — at minimum set GEMINI_API_KEY if you want /analysis/analyze to work,
# and point DATABASE_URL at a Postgres instance you have running locally,
# e.g. postgresql+asyncpg://postgres:postgres@localhost:5432/heathify

# 4. Start PostgreSQL (if not already running)
#    Easiest: docker run --name heathify-db -e POSTGRES_DB=heathify \
#      -e POSTGRES_USER=postgres -e POSTGRES_PASSWORD=postgres \
#      -p 5432:5432 -d postgres:16-alpine

# 5. Run migrations
alembic upgrade head

# 6. (optional) seed a few sample foods for local testing
python -m scripts.seed_foods

# 7. Start the API
uvicorn app.main:app --reload

# 8. Open Swagger docs
open http://localhost:8000/docs
```

---

## 6. Running with Docker

```bash
cp .env.example .env   # set GEMINI_API_KEY, etc.

docker compose up --build
```

This starts:
- `db` — PostgreSQL 16, exposed on `5432`
- `backend` — runs `alembic upgrade head` then Uvicorn with `--reload`, exposed on `8000`

Seed sample foods inside the running container:

```bash
docker compose exec backend python -m scripts.seed_foods
```

### Importing USDA Nutrition Data

To populate the local reference database with over 120+ common staple foods (grains, poultry, meats, fish, vegetables, fruits, dairy, plant proteins, and nuts) using the official USDA FoodData Central API:

1. Obtain a free API key at [https://fdc.nal.usda.gov/api-key-signup.html](https://fdc.nal.usda.gov/api-key-signup.html).
2. Set `USDA_API_KEY=your_key_here` in `.env` or in your environment.
3. Run the import script:

```bash
# Locally:
python -m scripts.import_usda_foods

# Or inside Docker:
docker compose exec backend python -m scripts.import_usda_foods
```

The import script is idempotent (skips items already present in the database), handles USDA API rate limits, and persists macro nutrients (calories, protein, carbohydrates, fat, fiber) per 100g serving. `scripts/seed_foods.py` remains available as a zero-dependency fallback for development.

---

## 7. Migrations

```bash
# Apply all migrations
alembic upgrade head

# Roll back one migration
alembic downgrade -1

# Generate a new migration after changing models
alembic revision --autogenerate -m "describe your change"
```

---

## 8. Tests

Tests run against an **in-memory SQLite** database and a **fake Gemini
service** — no Postgres instance or `GEMINI_API_KEY` required.

```bash
pip install -r requirements.txt   # includes aiosqlite for tests
pytest
```

Covers:
- `/health` and `/api/v1/health`
- `/api/v1/analysis/analyze`: invalid file type, missing image, valid response shape (mocked Gemini)
- Deterministic nutrition scaling (100g / 200g rice) and name-normalization lookup

---

## 9. API Endpoints

| Method | Path | Purpose |
|---|---|---|
| GET | `/` | Root — basic app info |
| GET | `/health` | Liveness check |
| GET | `/api/v1/health` | Liveness check (versioned) |
| POST | `/api/v1/users` | Create a user |
| GET | `/api/v1/users/{user_id}` | Get a user |
| POST | `/api/v1/analysis/analyze` | Analyze a food photo → estimated nutrition (no DB write) |
| POST | `/api/v1/meals` | Save a meal (e.g. built from an analysis result) |
| GET | `/api/v1/meals?user_id=...` | List meals |
| GET | `/api/v1/meals/{meal_id}` | Get one meal |
| PATCH | `/api/v1/meals/{meal_id}` | Update a meal |
| DELETE | `/api/v1/meals/{meal_id}` | Delete a meal |
| GET | `/api/v1/nutrition/foods` | List foods |
| GET | `/api/v1/nutrition/foods/search?q=rice` | Search foods |
| GET | `/api/v1/nutrition/foods/{food_id}` | Get one food |

Interactive docs: **`/docs`** (Swagger UI) and **`/redoc`**.

### Example: analyze a photo

```bash
curl -X POST http://localhost:8000/api/v1/analysis/analyze \
  -F "image=@/path/to/plate.jpg;type=image/jpeg"
```

Example response:

```json
{
  "total": {
    "estimated_calories": 234.0,
    "protein": 4.86,
    "carbohydrates": 50.4,
    "fat": 0.54,
    "fiber": 0.72
  },
  "items": [
    {
      "name": "cooked white rice",
      "quantity": 180,
      "unit": "g",
      "estimated_calories": 234.0,
      "protein": 4.86,
      "carbohydrates": 50.4,
      "fat": 0.54,
      "fiber": 0.72,
      "confidence": 0.94,
      "matched": true,
      "matched_food_id": "b3f1c8a1-49a4-6c3b-6d05-f3c2b80d4d2e"
    },
    {
      "name": "mystery exotic snack",
      "quantity": 50,
      "unit": "g",
      "estimated_calories": 0.0,
      "protein": 0.0,
      "carbohydrates": 0.0,
      "fat": 0.0,
      "fiber": 0.0,
      "confidence": 0.75,
      "matched": false,
      "matched_food_id": null
    }
  ],
  "unmatched_items": [
    "mystery exotic snack"
  ],
  "disclaimer": "Nutrition values are estimates derived from an AI-identified photo and a reference nutrition database. They are not medically exact measurements."
}
```

### Example: save the analyzed meal

```bash
curl -X POST http://localhost:8000/api/v1/meals \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "00000000-0000-0000-0000-000000000000",
    "meal_type": "lunch",
    "items": [
      {
        "food_name": "cooked white rice",
        "quantity": 180,
        "unit": "g",
        "calories": 234,
        "protein": 4.86,
        "carbohydrates": 50.4,
        "fat": 0.54,
        "fiber": 0.72,
        "confidence": 0.94
      }
    ]
  }'
```

---

## 10. How Gemini Is Used

`app/services/gemini_service.py` sends the uploaded image plus a fixed
prompt (`FOOD_RECOGNITION_PROMPT`) to the configured `GEMINI_MODEL`,
requesting a structured JSON response:

```json
{
  "foods": [
    { "name": "cooked white rice", "estimated_quantity": 180, "unit": "g", "confidence": 0.94 }
  ]
}
```

Gemini's responsibility stops at **identification → portion estimate →
confidence**. It never calculates calories or macros — that's
`NutritionService`'s job, using a local `Food` table (deterministic
`value * quantity / serving_size` scaling). This separation means the
calorie math stays auditable and swappable independent of the AI model.

Malformed or partially-malformed Gemini responses are handled cleanly:
individual bad items are skipped and logged; a response with no valid
items at all raises `GeminiResponseParsingError`, which the API layer
turns into a `502`.

---

## 11. Error Handling

| Status | Meaning |
|---|---|
| 400 | Invalid image / invalid request |
| 404 | Resource not found (user, meal, food) |
| 422 | Request validation failure (e.g. missing required field) |
| 500 | Unexpected server error |
| 502 | Gemini API unavailable or returned an unparseable response |

Stack traces and API keys are never exposed to clients; failures are
logged server-side with generic detail messages returned to the client.

---

## 12. Security Notes (Scaffold-Level)

- No real authentication yet. Endpoints that need "current user" accept
  a `user_id` directly, and `app/core/security.py` documents a
  temporary `X-User-Id` header dependency.
- Uploads are validated by declared MIME type **and** magic bytes (not
  the client's `Content-Type` alone), and size-limited via
  `MAX_UPLOAD_SIZE_MB`.
- Secrets are never hardcoded; `.env` is git-ignored.

**TODOs left for a future phase** (see inline comments in
`app/core/security.py` and elsewhere):
- JWT authentication
- Rate limiting (especially on `/analysis/analyze`, which triggers a paid external API call)
- Per-user authorization (users may only access their own meals)
- Object storage + signed image URLs (currently `image_url` is just a string field)
- Audit logging

---

## 13. What's Implemented

- FastAPI app with CORS, health checks, versioned routing
- Async SQLAlchemy models: `User`, `Food`, `Meal`, `MealItem` (with historical nutrition snapshotting)
- Alembic migrations (initial schema)
- Gemini-backed food detection with a reusable, structured prompt and response validation
- Deterministic nutrition calculation against a local `Food` table, with basic name normalization
- `POST /api/v1/analysis/analyze` (pure analysis, no DB write) and full `POST/GET/PATCH/DELETE /api/v1/meals` CRUD
- Image validation (MIME type, magic bytes, size limit)
- Clean, mapped error handling across the stack
- Docker + docker-compose setup
- Unit tests with a mocked Gemini service and an in-memory test database
- Auto-generated Swagger/ReDoc docs

## 14. What's Intentionally NOT Implemented Yet

- Mobile app (Flutter) / any frontend
- Real authentication (JWT), authorization, rate limiting
- Object storage for images (currently just a URL string field)
- Fuzzy/embedding-based food-name matching (simple synonym table for now)
- A production-grade external nutrition API integration (local seed table only)
- Payments, notifications, admin dashboard, wearable integrations, exercise tracking
- Advanced recommendation engine, ML training pipeline
- Production CI/CD, Kubernetes, microservices, event streaming

These are all natural next phases once the foundation above is in place.
