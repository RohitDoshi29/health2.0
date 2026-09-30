"""Tests for Google and Firebase OAuth authentication endpoints."""

import pytest
from httpx import AsyncClient


@pytest.mark.asyncio
async def test_google_auth_new_user_registration(client: AsyncClient):
    """Test registering a brand new user via Google authentication."""
    payload = {
        "id_token": "mock_google_id_token_xyz123",
        "email": "google_newbie@example.com",
        "name": "Google User",
        "avatar_url": "https://lh3.googleusercontent.com/a/default-user",
        "firebase_uid": "firebase_uid_12345",
    }

    response = await client.post("/api/v1/auth/google", json=payload)
    assert response.status_code == 200

    data = response.json()
    assert "access_token" in data
    assert data["token_type"] == "bearer"
    assert data["user"]["email"] == "google_newbie@example.com"
    assert data["user"]["name"] == "Google User"
    assert data["user"]["auth_provider"] == "google"
    assert data["user"]["avatar_url"] == "https://lh3.googleusercontent.com/a/default-user"

    # Verify accessing /me with the returned JWT token
    token = data["access_token"]
    me_resp = await client.get("/api/v1/auth/me", headers={"Authorization": f"Bearer {token}"})
    assert me_resp.status_code == 200
    assert me_resp.json()["email"] == "google_newbie@example.com"


@pytest.mark.asyncio
async def test_google_auth_existing_user_login(client: AsyncClient):
    """Test logging in an existing user via Google authentication."""
    # First sign up via email/password
    signup_payload = {
        "name": "Original User",
        "email": "existing_user@example.com",
        "password": "Password123!",
    }
    signup_resp = await client.post("/api/v1/auth/signup", json=signup_payload)
    assert signup_resp.status_code == 201

    # Now login with same email using Google Auth
    google_payload = {
        "id_token": "mock_google_token_456",
        "email": "existing_user@example.com",
        "name": "Updated Google Name",
        "avatar_url": "https://lh3.googleusercontent.com/a/new-avatar",
        "firebase_uid": "fb_uid_999",
    }
    google_resp = await client.post("/api/v1/auth/google", json=google_payload)
    assert google_resp.status_code == 200

    data = google_resp.json()
    assert "access_token" in data
    assert data["user"]["email"] == "existing_user@example.com"
    assert data["user"]["avatar_url"] == "https://lh3.googleusercontent.com/a/new-avatar"


@pytest.mark.asyncio
async def test_google_auth_empty_token_rejected(client: AsyncClient):
    """Test that empty or blank tokens are rejected."""
    payload = {
        "id_token": "   ",
        "email": "bad_token@example.com",
    }
    response = await client.post("/api/v1/auth/google", json=payload)
    assert response.status_code == 400
    assert "Valid ID Token is required" in response.json()["detail"]


@pytest.mark.asyncio
async def test_firebase_alias_endpoint(client: AsyncClient):
    """Test the /api/v1/auth/firebase alias endpoint."""
    payload = {
        "id_token": "mock_firebase_token_789",
        "email": "firebase_tester@example.com",
        "name": "Firebase Tester",
    }
    response = await client.post("/api/v1/auth/firebase", json=payload)
    assert response.status_code == 200
    data = response.json()
    assert data["user"]["email"] == "firebase_tester@example.com"
