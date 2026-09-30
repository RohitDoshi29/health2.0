"""Tests for portion guides, endpoints, and 1200g portion capping."""

import uuid

import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import create_access_token
from app.models.food import Food
from app.models.user import User
from app.services.nutrition_service import convert_quantity_to_grams


@pytest.fixture
def auth_headers(test_user: User) -> dict[str, str]:
    token = create_access_token(data={"sub": str(test_user.id), "email": test_user.email})
    return {"Authorization": f"Bearer {token}"}


@pytest.fixture
async def sample_foods(db_session: AsyncSession) -> dict[str, Food]:
    dal = Food(
        name="Moong Dal",
        canonical_name="dal",
        serving_size=100.0,
        serving_unit="g",
        calories=116.0,
        protein=9.0,
        carbohydrates=20.0,
        fat=0.4,
        fiber=4.0,
    )
    rice = Food(
        name="Cooked White Rice",
        canonical_name="cooked_white_rice",
        serving_size=100.0,
        serving_unit="g",
        calories=130.0,
        protein=2.7,
        carbohydrates=28.2,
        fat=0.3,
        fiber=0.4,
    )
    custom_item = Food(
        name="Unique Homemade Smoothie",
        canonical_name="unique_smoothie",
        serving_size=250.0,
        serving_unit="ml",
        calories=200.0,
        protein=5.0,
        carbohydrates=35.0,
        fat=2.0,
        fiber=3.0,
    )
    db_session.add_all([dal, rice, custom_item])
    await db_session.commit()
    return {"dal": dal, "rice": rice, "custom": custom_item}


@pytest.mark.asyncio
async def test_search_portions_endpoint(
    client: AsyncClient,
    auth_headers: dict[str, str],
    db_session: AsyncSession,
) -> None:
    # 1. Unauthenticated request should be rejected
    unauth_res = await client.get("/api/v1/nutrition/portions")
    assert unauth_res.status_code == 401

    # 2. Authenticated request with no query returns all seeded portions
    res = await client.get("/api/v1/nutrition/portions", headers=auth_headers)
    assert res.status_code == 200
    portions = res.json()
    assert len(portions) > 0
    labels = [p["label"] for p in portions]
    assert any("katori dal" in lbl for lbl in labels)
    assert any("roti" in lbl for lbl in labels)
    assert any("slice pizza" in lbl for lbl in labels)

    # 3. Search query filtering
    res_dal = await client.get("/api/v1/nutrition/portions?q=dal", headers=auth_headers)
    assert res_dal.status_code == 200
    dal_portions = res_dal.json()
    assert len(dal_portions) >= 1
    assert all(
        "dal" in p["food_canonical_name"] or "dal" in p["label"].lower() for p in dal_portions
    )


@pytest.mark.asyncio
async def test_food_portions_endpoint(
    client: AsyncClient,
    auth_headers: dict[str, str],
    sample_foods: dict[str, Food],
) -> None:
    dal = sample_foods["dal"]
    custom = sample_foods["custom"]

    # 1. Non-existent food returns 404
    bad_res = await client.get(
        f"/api/v1/nutrition/foods/{uuid.uuid4()}/portions", headers=auth_headers
    )
    assert bad_res.status_code == 404

    # 2. Food with registered portions returns them
    dal_res = await client.get(f"/api/v1/nutrition/foods/{dal.id}/portions", headers=auth_headers)
    assert dal_res.status_code == 200
    dal_portions = dal_res.json()
    assert len(dal_portions) >= 1
    assert any(p["grams"] == 150.0 for p in dal_portions)

    # 3. Food without registered portions returns dynamic serving portion fallback
    custom_res = await client.get(
        f"/api/v1/nutrition/foods/{custom.id}/portions", headers=auth_headers
    )
    assert custom_res.status_code == 200
    custom_portions = custom_res.json()
    assert len(custom_portions) == 1
    assert custom_portions[0]["grams"] == 250.0
    assert "250 ml" in custom_portions[0]["label"]


def test_convert_quantity_to_grams_portions_and_capping(
    sample_foods: dict[str, Food],
) -> None:
    dal = sample_foods["dal"]
    rice = sample_foods["rice"]

    # 1. Per-food portion conversions
    assert convert_quantity_to_grams(dal, 1.0, "katori") == 150.0
    assert convert_quantity_to_grams(dal, 2.0, "katori") == 300.0
    assert convert_quantity_to_grams(rice, 1.0, "katori") == 150.0
    assert convert_quantity_to_grams(rice, 1.0, "plate") == 250.0

    # 2. Indian units generic fallback
    assert convert_quantity_to_grams(None, 1.0, "katori") == 150.0
    assert convert_quantity_to_grams(None, 3.0, "roti") == 120.0
    assert convert_quantity_to_grams(None, 2.0, "idli") == 100.0
    assert convert_quantity_to_grams(None, 1.0, "dosa") == 100.0
    assert convert_quantity_to_grams(None, 1.0, "glass") == 240.0

    # 3. Hard cap at 1,200g
    assert convert_quantity_to_grams(dal, 10.0, "katori") == 1200.0  # 1500g -> 1200g
    assert convert_quantity_to_grams(None, 2000.0, "g") == 1200.0
    assert convert_quantity_to_grams(None, 2.5, "kg") == 1200.0
    assert convert_quantity_to_grams(None, 50.0, "roti") == 1200.0  # 2000g -> 1200g

    # 4. Zero / negative
    assert convert_quantity_to_grams(dal, 0.0, "katori") == 0.0
    assert convert_quantity_to_grams(dal, -1.0, "katori") == 0.0
