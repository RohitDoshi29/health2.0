"""Tests for meal CRUD endpoints and per-user ownership authorization."""

import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import create_access_token, hash_password
from app.models.user import User


@pytest.fixture
def sample_meal_payload() -> dict:
    return {
        "meal_type": "lunch",
        "items": [
            {
                "food_name": "cooked white rice",
                "quantity": 150,
                "unit": "g",
                "calories": 195.0,
                "protein": 4.05,
                "carbohydrates": 42.0,
                "fat": 0.45,
                "fiber": 0.6,
                "confidence": 0.95,
            }
        ],
    }


@pytest.mark.asyncio
async def test_create_meal_authenticated(
    client: AsyncClient, auth_headers: dict[str, str], test_user: User, sample_meal_payload: dict
) -> None:
    response = await client.post(
        "/api/v1/meals", json=sample_meal_payload, headers=auth_headers
    )
    assert response.status_code == 201
    data = response.json()
    assert data["user_id"] == str(test_user.id)
    assert data["meal_type"] == "lunch"
    assert data["total_calories"] == 195.0
    assert len(data["items"]) == 1


@pytest.mark.asyncio
async def test_create_meal_with_explicit_created_at(
    client: AsyncClient, auth_headers: dict[str, str], sample_meal_payload: dict
) -> None:
    payload = {
        **sample_meal_payload,
        "created_at": "2026-09-20T14:30:00Z",
    }
    response = await client.post("/api/v1/meals", json=payload, headers=auth_headers)
    assert response.status_code == 201
    data = response.json()
    assert "2026-09-20" in data["created_at"]


@pytest.mark.asyncio
async def test_create_meal_unauthorized(client: AsyncClient, sample_meal_payload: dict) -> None:
    response = await client.post("/api/v1/meals", json=sample_meal_payload)
    assert response.status_code == 401


@pytest.mark.asyncio
async def test_list_meals_user_isolation(
    client: AsyncClient,
    auth_headers: dict[str, str],
    test_user: User,
    db_session: AsyncSession,
    sample_meal_payload: dict,
) -> None:
    # Create another user and their meal
    user2 = User(
        name="User 2",
        email="user2@example.com",
        hashed_password=hash_password("password123"),
    )
    db_session.add(user2)
    await db_session.commit()
    await db_session.refresh(user2)

    user2_token = create_access_token(data={"sub": str(user2.id), "email": user2.email})
    user2_headers = {"Authorization": f"Bearer {user2_token}"}

    # User 1 creates a meal
    res1 = await client.post("/api/v1/meals", json=sample_meal_payload, headers=auth_headers)
    assert res1.status_code == 201

    # User 2 creates a meal
    res2 = await client.post("/api/v1/meals", json=sample_meal_payload, headers=user2_headers)
    assert res2.status_code == 201

    # User 1 lists meals -> sees only 1 meal
    list1 = await client.get("/api/v1/meals", headers=auth_headers)
    assert list1.status_code == 200
    assert len(list1.json()) == 1
    assert list1.json()[0]["user_id"] == str(test_user.id)

    # User 2 lists meals -> sees only 1 meal
    list2 = await client.get("/api/v1/meals", headers=user2_headers)
    assert list2.status_code == 200
    assert len(list2.json()) == 1
    assert list2.json()[0]["user_id"] == str(user2.id)


@pytest.mark.asyncio
async def test_cannot_access_other_user_meal(
    client: AsyncClient,
    auth_headers: dict[str, str],
    db_session: AsyncSession,
    sample_meal_payload: dict,
) -> None:
    # User 2
    user2 = User(
        name="User 2",
        email="user2@example.com",
        hashed_password=hash_password("password123"),
    )
    db_session.add(user2)
    await db_session.commit()
    await db_session.refresh(user2)
    user2_token = create_access_token(data={"sub": str(user2.id), "email": user2.email})
    user2_headers = {"Authorization": f"Bearer {user2_token}"}

    # User 2 creates a meal
    res = await client.post("/api/v1/meals", json=sample_meal_payload, headers=user2_headers)
    assert res.status_code == 201
    meal_id = res.json()["id"]

    # User 1 tries to GET User 2's meal -> 404
    get_res = await client.get(f"/api/v1/meals/{meal_id}", headers=auth_headers)
    assert get_res.status_code == 404

    # User 1 tries to PATCH User 2's meal -> 404
    patch_res = await client.patch(
        f"/api/v1/meals/{meal_id}", json={"meal_type": "dinner"}, headers=auth_headers
    )
    assert patch_res.status_code == 404

    # User 1 tries to DELETE User 2's meal -> 404
    del_res = await client.delete(f"/api/v1/meals/{meal_id}", headers=auth_headers)
    assert del_res.status_code == 404


@pytest.mark.asyncio
async def test_meal_crud_flow(
    client: AsyncClient, auth_headers: dict[str, str], sample_meal_payload: dict
) -> None:
    # Create
    create_res = await client.post(
        "/api/v1/meals", json=sample_meal_payload, headers=auth_headers
    )
    assert create_res.status_code == 201
    meal_id = create_res.json()["id"]

    # Get
    get_res = await client.get(f"/api/v1/meals/{meal_id}", headers=auth_headers)
    assert get_res.status_code == 200
    assert get_res.json()["meal_type"] == "lunch"

    # Update
    update_res = await client.patch(
        f"/api/v1/meals/{meal_id}", json={"meal_type": "dinner"}, headers=auth_headers
    )
    assert update_res.status_code == 200
    assert update_res.json()["meal_type"] == "dinner"

    # Delete
    delete_res = await client.delete(f"/api/v1/meals/{meal_id}", headers=auth_headers)
    assert delete_res.status_code == 204

    # Verify deleted
    verify_res = await client.get(f"/api/v1/meals/{meal_id}", headers=auth_headers)
    assert verify_res.status_code == 404

