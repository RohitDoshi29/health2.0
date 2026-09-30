"""Tests for image upload and static serving endpoints."""

import io

import pytest
from httpx import AsyncClient
from PIL import Image


def _create_synthetic_image(width: int = 400, height: int = 400, fmt: str = "JPEG") -> bytes:
    img = Image.new("RGB", (width, height), color=(100, 150, 200))
    buf = io.BytesIO()
    img.save(buf, format=fmt)
    return buf.getvalue()


@pytest.mark.asyncio
async def test_upload_image_success(client: AsyncClient) -> None:
    img_bytes = _create_synthetic_image(200, 200, "JPEG")
    files = {"image": ("food.jpg", io.BytesIO(img_bytes), "image/jpeg")}
    response = await client.post("/api/v1/uploads", files=files)

    assert response.status_code == 201
    data = response.json()
    assert "image_url" in data
    assert data["image_url"].startswith("/uploads/meal_")
    assert data["content_type"] == "image/jpeg"
    assert data["size_bytes"] > 0

    # Verify static file serving
    get_res = await client.get(data["image_url"])
    assert get_res.status_code == 200
    assert len(get_res.content) > 0


@pytest.mark.asyncio
async def test_upload_image_rejects_invalid_type(client: AsyncClient) -> None:
    files = {"image": ("doc.txt", io.BytesIO(b"not an image"), "text/plain")}
    response = await client.post("/api/v1/uploads", files=files)
    assert response.status_code == 400


@pytest.mark.asyncio
async def test_analyze_populates_image_url(client: AsyncClient) -> None:
    img_bytes = _create_synthetic_image(600, 400, "PNG")
    files = {"image": ("meal.png", io.BytesIO(img_bytes), "image/png")}
    response = await client.post("/api/v1/analysis/analyze", files=files)

    assert response.status_code == 200
    data = response.json()
    assert "image_url" in data
    assert data["image_url"] is not None
    assert data["image_url"].startswith("/uploads/meal_")
