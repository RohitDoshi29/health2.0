"""Tests for Recent Foods and Meal Relog features."""

from datetime import UTC, datetime, timedelta
import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import create_access_token, hash_password
from app.models.user import User
from app.services.meal_service import map_hour_to_meal_type


def test_map_hour_to_meal_type() -> None:
    """Verify hour-to-meal_type mappings per specifications:
    breakfast < 11, lunch 11-16, dinner 16-22, snack otherwise.
    """
    # Breakfast: 0..10
    assert map_hour_to_meal_type(0) == "breakfast"
    assert map_hour_to_meal_type(8) == "breakfast"
    assert map_hour_to_meal_type(10) == "breakfast"

    # Lunch: 11..15 (11 <= hour < 16)
    assert map_hour_to_meal_type(11) == "lunch"
    assert map_hour_to_meal_type(13) == "lunch"
    assert map_hour_to_meal_type(15) == "lunch"

    # Dinner: 16..21 (16 <= hour < 22)
    assert map_hour_to_meal_type(16) == "dinner"
    assert map_hour_to_meal_type(19) == "dinner"
    assert map_hour_to_meal_type(21) == "dinner"

    # Snack: 22..23
    assert map_hour_to_meal_type(22) == "snack"
    assert map_hour_to_meal_type(23) == "snack"


@pytest.mark.asyncio
async def test_recent_foods_deduplication_and_ordering(
    client: AsyncClient, auth_headers: dict[str, str]
) -> None:
    """Verify that recent foods are deduplicated case-insensitively,
    keep the most recently logged quantity and macros, and are sorted most recent first.
    """
    # Meal 1 (older)
    meal1 = {
        "meal_type": "breakfast",
        "created_at": "2026-03-25T08:00:00Z",
        "items": [
            {
                "food_name": "Banana",
                "quantity": 100,
                "unit": "g",
                "calories": 89.0,
                "protein": 1.1,
                "carbohydrates": 22.8,
                "fat": 0.3,
                "fiber": 2.6,
            },
            {
                "food_name": "Whole Milk",
                "quantity": 250,
                "unit": "ml",
                "calories": 150.0,
                "protein": 8.0,
                "carbohydrates": 12.0,
                "fat": 8.0,
                "fiber": 0.0,
            },
        ],
    }
    res1 = await client.post("/api/v1/meals", json=meal1, headers=auth_headers)
    assert res1.status_code == 201

    # Meal 2 (newer) - includes "banana" with different quantity (150g) and "Rolled Oats"
    meal2 = {
        "meal_type": "lunch",
        "created_at": "2026-03-25T13:00:00Z",
        "items": [
            {
                "food_name": "banana",
                "quantity": 150,
                "unit": "g",
                "calories": 133.5,
                "protein": 1.65,
                "carbohydrates": 34.2,
                "fat": 0.45,
                "fiber": 3.9,
            },
            {
                "food_name": "Rolled Oats",
                "quantity": 80,
                "unit": "g",
                "calories": 304.0,
                "protein": 10.4,
                "carbohydrates": 53.6,
                "fat": 5.6,
                "fiber": 8.0,
            },
        ],
    }
    res2 = await client.post("/api/v1/meals", json=meal2, headers=auth_headers)
    assert res2.status_code == 201

    # Fetch recent foods
    res = await client.get("/api/v1/meals/recent-foods", headers=auth_headers)
    assert res.status_code == 200
    foods = res.json()

    # Deduplicated food names count: should be 3 (banana, rolled oats, whole milk)
    names = [f["food_name"].lower() for f in foods]
    assert names == ["banana", "rolled oats", "whole milk"]

    # Verify the most recent "banana" usage was preserved (150g, 133.5 kcal)
    banana_entry = next(f for f in foods if f["food_name"].lower() == "banana")
    assert banana_entry["quantity"] == 150.0
    assert banana_entry["calories"] == 133.5
    assert banana_entry["protein"] == 1.65

    # Test limit parameter
    res_limit = await client.get("/api/v1/meals/recent-foods?limit=2", headers=auth_headers)
    assert res_limit.status_code == 200
    assert len(res_limit.json()) == 2


@pytest.mark.asyncio
async def test_recent_foods_user_isolation(
    client: AsyncClient, auth_headers: dict[str, str], db_session: AsyncSession
) -> None:
    """Verify that User A cannot see User B's recent foods."""
    # User A logs a meal
    meal = {
        "meal_type": "snack",
        "items": [
            {
                "food_name": "Almonds",
                "quantity": 30,
                "unit": "g",
                "calories": 170.0,
                "protein": 6.0,
                "carbohydrates": 6.0,
                "fat": 15.0,
                "fiber": 3.0,
            }
        ],
    }
    await client.post("/api/v1/meals", json=meal, headers=auth_headers)

    # User B logs in
    user_b = User(
        email="user_b_relog@example.com",
        name="User B",
        hashed_password=hash_password("Password123!"),
    )
    db_session.add(user_b)
    await db_session.commit()
    token_b = create_access_token(data={"sub": str(user_b.id), "email": user_b.email})
    headers_b = {"Authorization": f"Bearer {token_b}"}

    # User B checks recent foods
    res_b = await client.get("/api/v1/meals/recent-foods", headers=headers_b)
    assert res_b.status_code == 200
    assert len(res_b.json()) == 0


@pytest.mark.asyncio
async def test_relog_meal_copy_integrity_and_mapping(
    client: AsyncClient, auth_headers: dict[str, str]
) -> None:
    """Verify that relogging a meal copies all items and macros, creates a new meal with new ID,
    and sets meal_type according to current time and timezone offset.
    """
    original_payload = {
        "meal_type": "breakfast",
        "items": [
            {
                "food_name": "Brown Rice",
                "quantity": 200,
                "unit": "g",
                "calories": 216.0,
                "protein": 5.0,
                "carbohydrates": 45.0,
                "fat": 1.8,
                "fiber": 3.5,
            },
            {
                "food_name": "Grilled Chicken",
                "quantity": 150,
                "unit": "g",
                "calories": 247.5,
                "protein": 46.5,
                "carbohydrates": 0.0,
                "fat": 5.4,
                "fiber": 0.0,
            },
        ],
    }
    orig_res = await client.post("/api/v1/meals", json=original_payload, headers=auth_headers)
    assert orig_res.status_code == 201
    orig_meal = orig_res.json()
    orig_id = orig_meal["id"]

    # Calculate tz_offset to force local hour to 13 (Lunch: 11-16)
    utc_now = datetime.now(UTC)
    current_utc_hour = utc_now.hour
    current_utc_min = utc_now.minute
    # offset in minutes to make local hour = 13
    target_offset_minutes = (13 - current_utc_hour) * 60 - current_utc_min

    relog_res = await client.post(
        f"/api/v1/meals/{orig_id}/relog?tz_offset={target_offset_minutes}",
        headers=auth_headers,
    )
    assert relog_res.status_code == 201
    relogged_meal = relog_res.json()

    # Integrity verification
    assert relogged_meal["id"] != orig_id
    assert relogged_meal["meal_type"] == "lunch"
    assert relogged_meal["total_calories"] == orig_meal["total_calories"]
    assert relogged_meal["total_protein"] == orig_meal["total_protein"]
    assert relogged_meal["total_carbohydrates"] == orig_meal["total_carbohydrates"]
    assert relogged_meal["total_fat"] == orig_meal["total_fat"]
    assert relogged_meal["total_fiber"] == orig_meal["total_fiber"]
    assert len(relogged_meal["items"]) == 2

    # Check items match
    orig_items = {i["food_name"]: i for i in orig_meal["items"]}
    for item in relogged_meal["items"]:
        orig_item = orig_items[item["food_name"]]
        assert item["quantity"] == orig_item["quantity"]
        assert item["unit"] == orig_item["unit"]
        assert item["calories"] == orig_item["calories"]
        assert item["protein"] == orig_item["protein"]
        assert item["carbohydrates"] == orig_item["carbohydrates"]
        assert item["fat"] == orig_item["fat"]
        assert item["fiber"] == orig_item["fiber"]


@pytest.mark.asyncio
async def test_relog_meal_not_found(
    client: AsyncClient, auth_headers: dict[str, str], db_session: AsyncSession
) -> None:
    """Verify that relogging nonexistent meal or meal owned by another user returns 404."""
    fake_uuid = "00000000-0000-0000-0000-000000000000"
    res = await client.post(f"/api/v1/meals/{fake_uuid}/relog", headers=auth_headers)
    assert res.status_code == 404

    # Create meal under User B
    user_b = User(
        email="user_b_relog_404@example.com",
        name="User B",
        hashed_password=hash_password("Password123!"),
    )
    db_session.add(user_b)
    await db_session.commit()
    token_b = create_access_token(data={"sub": str(user_b.id), "email": user_b.email})
    headers_b = {"Authorization": f"Bearer {token_b}"}

    meal_b_res = await client.post(
        "/api/v1/meals",
        json={
            "meal_type": "snack",
            "items": [
                {
                    "food_name": "Apple",
                    "quantity": 100,
                    "unit": "g",
                    "calories": 52.0,
                    "protein": 0.3,
                    "carbohydrates": 14.0,
                    "fat": 0.2,
                    "fiber": 2.4,
                }
            ],
        },
        headers=headers_b,
    )
    meal_b_id = meal_b_res.json()["id"]

    # User A tries to relog User B's meal -> 404
    forbidden_res = await client.post(f"/api/v1/meals/{meal_b_id}/relog", headers=auth_headers)
    assert forbidden_res.status_code == 404
