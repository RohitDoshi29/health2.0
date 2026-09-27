"""Tests for Favorite Meal templates and 1-tap quick logging."""

import pytest
from httpx import AsyncClient


@pytest.mark.asyncio
async def test_favorites_crud_and_quick_log(client: AsyncClient) -> None:
    # 1. Sign up and authenticate
    signup_resp = await client.post(
        "/api/v1/auth/signup",
        json={
            "name": "Favorite User",
            "email": "fav_user@example.com",
            "password": "securepassword123",
        },
    )
    assert signup_resp.status_code == 201
    token = signup_resp.json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

    # 2. List favorites initially empty
    resp = await client.get("/api/v1/favorites", headers=headers)
    assert resp.status_code == 200
    assert resp.json() == []

    # 3. Create a new favorite template
    payload = {
        "name": "Power Protein Shake",
        "meal_type": "breakfast",
        "items": [
            {
                "food_name": "Whey Protein",
                "quantity": 30.0,
                "unit": "g",
                "calories": 120.0,
                "protein": 24.0,
                "carbohydrates": 2.0,
                "fat": 1.5,
                "fiber": 0.0,
            },
            {
                "food_name": "Banana",
                "quantity": 1.0,
                "unit": "piece",
                "calories": 105.0,
                "protein": 1.3,
                "carbohydrates": 27.0,
                "fat": 0.3,
                "fiber": 3.1,
            },
        ],
    }
    create_resp = await client.post("/api/v1/favorites", json=payload, headers=headers)
    assert create_resp.status_code == 201
    fav_data = create_resp.json()
    assert fav_data["name"] == "Power Protein Shake"
    assert fav_data["total_calories"] == 225.0
    assert fav_data["total_protein"] == 25.3
    fav_id = fav_data["id"]

    # 4. List favorites includes the new template
    list_resp = await client.get("/api/v1/favorites", headers=headers)
    assert list_resp.status_code == 200
    assert len(list_resp.json()) == 1

    # 5. 1-Tap Quick Log into Meals
    log_resp = await client.post(f"/api/v1/favorites/{fav_id}/log", headers=headers)
    assert log_resp.status_code == 201
    meal_data = log_resp.json()
    assert meal_data["meal_type"] == "breakfast"
    assert meal_data["total_calories"] == 225.0
    assert len(meal_data["items"]) == 2

    # 6. Verify meal is saved in meal history
    meals_resp = await client.get("/api/v1/meals", headers=headers)
    assert meals_resp.status_code == 200
    assert len(meals_resp.json()) == 1

    # 7. Delete favorite template
    del_resp = await client.delete(f"/api/v1/favorites/{fav_id}", headers=headers)
    assert del_resp.status_code == 204

    # 8. List favorites is empty again
    list_after_resp = await client.get("/api/v1/favorites", headers=headers)
    assert list_after_resp.status_code == 200
    assert list_after_resp.json() == []


@pytest.mark.asyncio
async def test_favorite_not_found(client: AsyncClient) -> None:
    signup_resp = await client.post(
        "/api/v1/auth/signup",
        json={"name": "User 2", "email": "user2@example.com", "password": "password123"},
    )
    headers = {"Authorization": f"Bearer {signup_resp.json()['access_token']}"}

    fake_id = "00000000-0000-0000-0000-000000000000"
    resp = await client.post(f"/api/v1/favorites/{fake_id}/log", headers=headers)
    assert resp.status_code == 404

    del_resp = await client.delete(f"/api/v1/favorites/{fake_id}", headers=headers)
    assert del_resp.status_code == 404
