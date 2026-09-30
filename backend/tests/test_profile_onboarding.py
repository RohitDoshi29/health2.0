"""Tests for Onboarding Calculator, BMR/TDEE calculations, and user profile endpoints."""

import pytest
from httpx import AsyncClient

from app.schemas.profile import UserProfileBase
from app.services.profile_service import ProfileService


def test_mifflin_st_jeor_bmr_calculation():
    # Male: 25yo, 70kg, 175cm -> 10*70 + 6.25*175 - 5*25 + 5 = 1673.8
    male_bmr = ProfileService.calculate_bmr(weight_kg=70.0, height_cm=175.0, age=25, sex="male")
    assert abs(male_bmr - 1673.8) < 0.2

    # Female: 30yo, 55kg, 160cm -> 10*55 + 6.25*160 - 5*30 - 161 = 1239.0
    female_bmr = ProfileService.calculate_bmr(weight_kg=55.0, height_cm=160.0, age=30, sex="female")
    assert abs(female_bmr - 1239.0) < 0.2


def test_tdee_and_macro_targets_maintain():
    profile = UserProfileBase(
        age=25,
        sex="male",
        height_cm=175.0,
        weight_kg=70.0,
        activity_level="moderate",  # 1.55
        goal="maintain",  # 1.2 g/kg protein
    )
    targets = ProfileService.calculate_targets(profile)

    expected_bmr = 1673.8
    expected_tdee = round(expected_bmr * 1.55, 1)  # ~2594.4
    assert abs(targets.bmr - expected_bmr) < 0.5
    assert abs(targets.tdee - expected_tdee) < 1.0
    assert targets.calorie_target == round(expected_tdee, 0)

    # Protein: 1.2 g/kg * 70kg = 84.0g
    assert targets.protein_target == 84.0

    # Fat: 25% of calories / 9
    expected_fat = round((targets.calorie_target * 0.25) / 9.0, 1)
    assert targets.fat_target == expected_fat

    # Fiber: 14g per 1000 kcal
    expected_fiber = round((targets.calorie_target / 1000.0) * 14.0, 1)
    assert targets.fiber_target == expected_fiber


def test_calorie_floor_clamping_female():
    # Female: small, sedentary, lose (-500 kcal) -> raw would be ~1000 kcal -> clamped to 1200
    profile = UserProfileBase(
        age=45,
        sex="female",
        height_cm=150.0,
        weight_kg=45.0,
        activity_level="sedentary",  # 1.2
        goal="lose",  # -500
    )
    targets = ProfileService.calculate_targets(profile)
    assert targets.calorie_target == 1200.0  # Clamped to female floor


def test_calorie_floor_clamping_male():
    # Male: aggressive deficit -> clamped to male floor 1500
    profile = UserProfileBase(
        age=60,
        sex="male",
        height_cm=160.0,
        weight_kg=50.0,
        activity_level="sedentary",  # 1.2
        goal="lose",  # -500
    )
    targets = ProfileService.calculate_targets(profile)
    assert targets.calorie_target == 1500.0  # Clamped to male floor


@pytest.mark.asyncio
async def test_preview_profile_endpoint(client: AsyncClient, auth_headers: dict[str, str]):
    payload = {
        "age": 28,
        "sex": "male",
        "height_cm": 180.0,
        "weight_kg": 75.0,
        "activity_level": "active",
        "goal": "lose",
    }
    response = await client.post(
        "/api/v1/users/me/profile/preview", json=payload, headers=auth_headers
    )
    assert response.status_code == 200
    data = response.json()
    assert data["calorie_target"] > 0
    assert data["protein_target"] == round(75.0 * 1.6, 1)  # 120.0g
    assert data["bmr"] > 0
    assert data["tdee"] > data["calorie_target"]  # lose is -500 from TDEE


@pytest.mark.asyncio
async def test_save_and_get_profile_endpoint(client: AsyncClient, auth_headers: dict[str, str]):
    payload = {
        "age": 24,
        "sex": "female",
        "height_cm": 165.0,
        "weight_kg": 60.0,
        "activity_level": "light",
        "goal": "maintain",
    }
    # Save
    post_res = await client.post("/api/v1/users/me/profile", json=payload, headers=auth_headers)
    assert post_res.status_code == 200
    data = post_res.json()
    assert data["profile"]["onboarding_completed"] is True
    assert data["goal"]["calorie_target"] > 0
    assert data["goal"]["protein_target"] == 72.0  # 60 * 1.2

    # Get
    get_res = await client.get("/api/v1/users/me/profile", headers=auth_headers)
    assert get_res.status_code == 200
    get_data = get_res.json()
    assert get_data["profile"]["age"] == 24
    assert get_data["profile"]["sex"] == "female"


@pytest.mark.asyncio
async def test_profile_validation_errors(client: AsyncClient, auth_headers: dict[str, str]):
    # Age < 13
    res1 = await client.post(
        "/api/v1/users/me/profile/preview",
        json={
            "age": 10,
            "sex": "male",
            "height_cm": 170.0,
            "weight_kg": 70.0,
            "activity_level": "moderate",
            "goal": "lose",
        },
        headers=auth_headers,
    )
    assert res1.status_code == 422

    # Height > 250
    res2 = await client.post(
        "/api/v1/users/me/profile/preview",
        json={
            "age": 25,
            "sex": "male",
            "height_cm": 300.0,
            "weight_kg": 70.0,
            "activity_level": "moderate",
            "goal": "lose",
        },
        headers=auth_headers,
    )
    assert res2.status_code == 422

    # Weight < 30
    res3 = await client.post(
        "/api/v1/users/me/profile/preview",
        json={
            "age": 25,
            "sex": "male",
            "height_cm": 170.0,
            "weight_kg": 20.0,
            "activity_level": "moderate",
            "goal": "lose",
        },
        headers=auth_headers,
    )
    assert res3.status_code == 422

    # Invalid activity level
    res4 = await client.post(
        "/api/v1/users/me/profile/preview",
        json={
            "age": 25,
            "sex": "male",
            "height_cm": 170.0,
            "weight_kg": 70.0,
            "activity_level": "hyperactive",
            "goal": "lose",
        },
        headers=auth_headers,
    )
    assert res4.status_code == 422
