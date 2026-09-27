"""Tests for User Goals and Daily Analytics endpoints."""

import pytest
from httpx import AsyncClient


@pytest.mark.asyncio
async def test_get_default_goals(client: AsyncClient, auth_headers: dict[str, str]) -> None:
    response = await client.get("/api/v1/users/me/goals", headers=auth_headers)
    assert response.status_code == 200
    data = response.json()
    assert data["calorie_target"] == 2000.0
    assert data["protein_target"] == 120.0
    assert data["carbohydrates_target"] == 250.0
    assert data["fat_target"] == 65.0
    assert data["fiber_target"] == 30.0


@pytest.mark.asyncio
async def test_update_goals(client: AsyncClient, auth_headers: dict[str, str]) -> None:
    payload = {
        "calorie_target": 2200.0,
        "protein_target": 150.0,
        "carbohydrates_target": 200.0,
        "fat_target": 60.0,
        "fiber_target": 35.0,
    }
    response = await client.put("/api/v1/users/me/goals", json=payload, headers=auth_headers)
    assert response.status_code == 200
    data = response.json()
    assert data["calorie_target"] == 2200.0
    assert data["protein_target"] == 150.0
    assert data["carbohydrates_target"] == 200.0


@pytest.mark.asyncio
async def test_daily_analytics_with_logged_meal(
    client: AsyncClient, auth_headers: dict[str, str]
) -> None:
    # 1. Update goals
    await client.put(
        "/api/v1/users/me/goals",
        json={"calorie_target": 2000.0, "protein_target": 100.0},
        headers=auth_headers,
    )

    # 2. Log a meal
    meal_payload = {
        "meal_type": "lunch",
        "items": [
            {
                "food_name": "Cooked chicken and rice",
                "quantity": 100,
                "unit": "g",
                "calories": 500.0,
                "protein": 50.0,
                "carbohydrates": 50.0,
                "fat": 10.0,
                "fiber": 5.0,
                "confidence": 0.9,
            }
        ],
    }
    create_meal_res = await client.post("/api/v1/meals", json=meal_payload, headers=auth_headers)
    assert create_meal_res.status_code == 201

    # 3. Fetch daily analytics
    analytics_res = await client.get("/api/v1/analytics/daily", headers=auth_headers)
    assert analytics_res.status_code == 200
    data = analytics_res.json()

    assert data["consumed_calories"] == 500.0
    assert data["consumed_protein"] == 50.0
    assert data["calorie_progress"] == 0.25  # 500 / 2000
    assert data["protein_progress"] == 0.5   # 50 / 100
    assert data["meals_count"] == 1
    assert data["goal"]["calorie_target"] == 2000.0


@pytest.mark.asyncio
async def test_goals_endpoints_unauthorized(client: AsyncClient) -> None:
    res1 = await client.get("/api/v1/users/me/goals")
    assert res1.status_code == 401

    res2 = await client.get("/api/v1/analytics/daily")
    assert res2.status_code == 401

    res3 = await client.get("/api/v1/analytics/trends")
    assert res3.status_code == 401


@pytest.mark.asyncio
async def test_trends_analytics(client: AsyncClient, auth_headers: dict[str, str]) -> None:
    # 1. Log a meal today
    meal_payload = {
        "meal_type": "dinner",
        "items": [
            {
                "food_name": "Salmon bowl",
                "quantity": 250,
                "unit": "g",
                "calories": 700.0,
                "protein": 56.0,
                "carbohydrates": 60.0,
                "fat": 20.0,
                "fiber": 8.0,
                "confidence": 0.95,
            }
        ],
    }
    await client.post("/api/v1/meals", json=meal_payload, headers=auth_headers)

    # 2. Query 7-day trends
    res_7d = await client.get("/api/v1/analytics/trends?days=7", headers=auth_headers)
    assert res_7d.status_code == 200
    data_7d = res_7d.json()

    assert data_7d["period"] == "7d"
    assert data_7d["days_count"] == 7
    assert len(data_7d["data_points"]) == 7
    assert data_7d["average_calories"] == round(700.0 / 7, 2)
    assert data_7d["average_protein"] == round(56.0 / 7, 2)
    assert data_7d["goal"]["calorie_target"] == 2000.0

    # Today's point is the last element
    today_point = data_7d["data_points"][-1]
    assert today_point["calories"] == 700.0
    assert today_point["protein"] == 56.0
    assert today_point["meals_count"] == 1

    # Earlier days should have 0 calories
    assert data_7d["data_points"][0]["calories"] == 0.0
    assert data_7d["data_points"][0]["meals_count"] == 0

    # 3. Query 30-day trends
    res_30d = await client.get("/api/v1/analytics/trends?days=30", headers=auth_headers)
    assert res_30d.status_code == 200
    data_30d = res_30d.json()
    assert data_30d["period"] == "30d"
    assert data_30d["days_count"] == 30
    assert len(data_30d["data_points"]) == 30


