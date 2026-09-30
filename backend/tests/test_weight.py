"""Tests for body weight tracking, history analytics, and profile synchronization."""

from datetime import UTC, datetime, timedelta
import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import create_access_token, hash_password
from app.models.meal import Meal
from app.models.user import User
from app.models.user_profile import UserProfile


@pytest.mark.asyncio
async def test_log_weight_and_profile_sync(
    client: AsyncClient,
    auth_headers: dict[str, str],
    test_user: User,
    db_session: AsyncSession,
):
    # Setup user profile with initial weight 75.0kg
    profile = UserProfile(
        user_id=test_user.id,
        age=28,
        sex="male",
        height_cm=180.0,
        weight_kg=75.0,
        activity_level="moderate",
        goal="lose",
        onboarding_completed=True,
    )
    db_session.add(profile)
    await db_session.commit()

    # Log new weight 74.2kg
    payload = {"weight_kg": 74.2, "note": "Morning weigh-in fasting"}
    response = await client.post("/api/v1/weight", json=payload, headers=auth_headers)
    assert response.status_code == 201
    data = response.json()
    assert data["weight_kg"] == 74.2
    assert data["note"] == "Morning weigh-in fasting"

    # Verify profile weight was updated
    await db_session.refresh(profile)
    assert profile.weight_kg == 74.2


@pytest.mark.asyncio
async def test_weight_history_and_deltas(
    client: AsyncClient,
    auth_headers: dict[str, str],
    test_user: User,
    db_session: AsyncSession,
):
    now = datetime.now(UTC)
    # Log 1: 10 days ago at 78.0kg
    await client.post(
        "/api/v1/weight",
        json={"weight_kg": 78.0, "logged_at": (now - timedelta(days=10)).isoformat()},
        headers=auth_headers,
    )
    # Log 2: 7 days ago at 77.0kg
    await client.post(
        "/api/v1/weight",
        json={"weight_kg": 77.0, "logged_at": (now - timedelta(days=7)).isoformat()},
        headers=auth_headers,
    )
    # Log 3: Today at 75.5kg
    await client.post(
        "/api/v1/weight",
        json={"weight_kg": 75.5, "logged_at": now.isoformat()},
        headers=auth_headers,
    )

    # Log a meal today to check calorie overlay
    meal = Meal(
        user_id=test_user.id,
        meal_type="lunch",
        total_calories=650.0,
        total_protein=35.0,
        total_carbohydrates=70.0,
        total_fat=20.0,
        total_fiber=8.0,
        created_at=now,
    )
    db_session.add(meal)
    await db_session.commit()

    # Get 30 days history
    res = await client.get("/api/v1/weight/history?days=30", headers=auth_headers)
    assert res.status_code == 200
    data = res.json()

    assert data["current_weight"] == 75.5
    assert data["start_weight"] == 78.0
    assert data["change_total_kg"] == -2.5  # 75.5 - 78.0
    assert data["change_7d_kg"] == -1.5  # 75.5 - 77.0
    assert len(data["points"]) > 0

    # Verify today's calorie point has 650 kcal
    today_str = now.date().isoformat()
    today_point = next((p for p in data["points"] if p["date"] == today_str), None)
    assert today_point is not None
    assert today_point["weight_kg"] == 75.5
    assert today_point["calories_consumed"] == 650.0


@pytest.mark.asyncio
async def test_weight_log_user_isolation_and_delete(
    client: AsyncClient,
    auth_headers: dict[str, str],
    db_session: AsyncSession,
):
    # Create user B
    other_user = User(
        name="Other User",
        email="other@example.com",
        hashed_password=hash_password("pw123"),
    )
    db_session.add(other_user)
    await db_session.commit()
    await db_session.refresh(other_user)

    other_token = create_access_token(data={"sub": str(other_user.id), "email": other_user.email})
    other_headers = {"Authorization": f"Bearer {other_token}"}

    # User A creates a weight log
    res = await client.post("/api/v1/weight", json={"weight_kg": 80.0}, headers=auth_headers)
    log_id = res.json()["id"]

    # User B cannot delete User A's weight log
    del_other = await client.delete(f"/api/v1/weight/{log_id}", headers=other_headers)
    assert del_other.status_code == 404

    # User A deletes their own log
    del_res = await client.delete(f"/api/v1/weight/{log_id}", headers=auth_headers)
    assert del_res.status_code == 204

    # Deleting again returns 404
    del_res2 = await client.delete(f"/api/v1/weight/{log_id}", headers=auth_headers)
    assert del_res2.status_code == 404
