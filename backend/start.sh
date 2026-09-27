#!/usr/bin/env bash
set -e

echo "=== Heathify Production Startup ==="

# 1. Run database migrations
echo "Applying database migrations..."
alembic upgrade head

# 2. Seed initial reference foods and accounts (idempotent)
echo "Checking seed food items..."
python -m scripts.seed_foods

echo "Checking seed user accounts..."
python -m scripts.seed_users

# 3. Import USDA foods if API key is provided (idempotent)
if [ -n "$USDA_API_KEY" ]; then
    echo "Importing USDA nutrition database..."
    python -m scripts.import_usda_foods || true
fi

# 4. Start API server on $PORT (or 8000 default)
PORT="${PORT:-8000}"
echo "Starting server on port $PORT..."
exec uvicorn app.main:app --host 0.0.0.0 --port "$PORT"

