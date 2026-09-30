"""Tests for authentication endpoints (/api/v1/auth)."""

import pytest
from httpx import AsyncClient


@pytest.mark.asyncio
async def test_signup_success(client: AsyncClient) -> None:
    response = await client.post(
        "/api/v1/auth/signup",
        json={
            "name": "Jane Doe",
            "email": "jane@example.com",
            "password": "securepassword123",
        },
    )
    assert response.status_code == 201
    data = response.json()
    assert "access_token" in data
    assert data["token_type"] == "bearer"
    assert data["user"]["email"] == "jane@example.com"
    assert data["user"]["name"] == "Jane Doe"
    assert "id" in data["user"]


@pytest.mark.asyncio
async def test_signup_duplicate_email(client: AsyncClient) -> None:
    payload = {
        "name": "John Doe",
        "email": "john@example.com",
        "password": "securepassword123",
    }
    res1 = await client.post("/api/v1/auth/signup", json=payload)
    assert res1.status_code == 201

    res2 = await client.post("/api/v1/auth/signup", json=payload)
    assert res2.status_code == 400
    assert "already registered" in res2.json()["detail"].lower()


@pytest.mark.asyncio
async def test_signup_short_password(client: AsyncClient) -> None:
    response = await client.post(
        "/api/v1/auth/signup",
        json={
            "name": "Short Pass",
            "email": "short@example.com",
            "password": "123",
        },
    )
    assert response.status_code == 422


@pytest.mark.asyncio
async def test_login_success(client: AsyncClient) -> None:
    # First sign up
    await client.post(
        "/api/v1/auth/signup",
        json={
            "name": "Login User",
            "email": "login@example.com",
            "password": "mypassword123",
        },
    )

    # Now login
    response = await client.post(
        "/api/v1/auth/login",
        json={
            "email": "login@example.com",
            "password": "mypassword123",
        },
    )
    assert response.status_code == 200
    data = response.json()
    assert "access_token" in data
    assert data["user"]["email"] == "login@example.com"


@pytest.mark.asyncio
async def test_login_invalid_password(client: AsyncClient) -> None:
    await client.post(
        "/api/v1/auth/signup",
        json={
            "name": "User",
            "email": "user@example.com",
            "password": "correctpassword123",
        },
    )

    response = await client.post(
        "/api/v1/auth/login",
        json={
            "email": "user@example.com",
            "password": "wrongpassword123",
        },
    )
    assert response.status_code == 401
    assert "invalid email or password" in response.json()["detail"].lower()


@pytest.mark.asyncio
async def test_login_nonexistent_user(client: AsyncClient) -> None:
    response = await client.post(
        "/api/v1/auth/login",
        json={
            "email": "nobody@example.com",
            "password": "somepassword123",
        },
    )
    assert response.status_code == 401


@pytest.mark.asyncio
async def test_get_me_success(client: AsyncClient, auth_headers: dict[str, str], test_user) -> None:
    response = await client.get("/api/v1/auth/me", headers=auth_headers)
    assert response.status_code == 200
    data = response.json()
    assert data["id"] == str(test_user.id)
    assert data["email"] == test_user.email


@pytest.mark.asyncio
async def test_get_me_unauthorized(client: AsyncClient) -> None:
    response = await client.get("/api/v1/auth/me")
    assert response.status_code == 401
