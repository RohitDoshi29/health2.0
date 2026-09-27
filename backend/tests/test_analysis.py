"""Tests for POST /api/v1/analysis/analyze, image resizing/compression, and rate limiting."""

import io

import pytest
from httpx import AsyncClient
from PIL import Image

from app.utils.image import ValidatedImage, resize_if_needed

PNG_MAGIC_BYTES = b"\x89PNG\r\n\x1a\n" + b"\x00" * 32


def _create_synthetic_image(width: int = 2400, height: int = 1800, fmt: str = "JPEG") -> bytes:
    img = Image.new("RGB", (width, height), color=(73, 109, 137))
    buf = io.BytesIO()
    img.save(buf, format=fmt)
    return buf.getvalue()


@pytest.mark.asyncio
async def test_analyze_rejects_invalid_file_type(client: AsyncClient) -> None:
    files = {"image": ("food.txt", io.BytesIO(b"not an image"), "text/plain")}
    response = await client.post("/api/v1/analysis/analyze", files=files)
    assert response.status_code == 400


@pytest.mark.asyncio
async def test_analyze_rejects_missing_image(client: AsyncClient) -> None:
    response = await client.post("/api/v1/analysis/analyze")
    assert response.status_code == 422


@pytest.mark.asyncio
async def test_analyze_returns_valid_response_shape(client: AsyncClient) -> None:
    img_bytes = _create_synthetic_image(800, 600, "PNG")
    files = {"image": ("food.png", io.BytesIO(img_bytes), "image/png")}
    response = await client.post("/api/v1/analysis/analyze", files=files)

    assert response.status_code == 200
    body = response.json()

    assert "total" in body
    assert "items" in body
    assert "unmatched_items" in body
    assert "disclaimer" in body

    total = body["total"]
    for key in ("estimated_calories", "protein", "carbohydrates", "fat", "fiber"):
        assert key in total

    assert len(body["items"]) == 1
    item = body["items"][0]
    assert item["name"] == "cooked white rice"
    assert item["quantity"] == 180
    assert item["confidence"] == 0.9
    assert item["matched"] is False
    assert item["matched_food_id"] is None
    assert body["unmatched_items"] == ["cooked white rice"]
    assert item["bounding_box"] is not None
    assert item["bounding_box"]["ymin"] == 0.15
    assert item["bounding_box"]["xmin"] == 0.20
    assert item["bounding_box"]["ymax"] == 0.85
    assert item["bounding_box"]["xmax"] == 0.80


@pytest.mark.asyncio
async def test_resize_if_needed_downscales_oversized_images() -> None:
    large_bytes = _create_synthetic_image(2400, 1800, "JPEG")
    orig_val = ValidatedImage(
        content=large_bytes,
        content_type="image/jpeg",
        size_bytes=len(large_bytes),
    )

    optimized = resize_if_needed(orig_val, max_dimension_px=1600)
    assert optimized.size_bytes > 0

    with Image.open(io.BytesIO(optimized.content)) as res_img:
        w, h = res_img.size
        assert w <= 1600
        assert h <= 1600
        assert w == 1600 or h == 1200


@pytest.mark.asyncio
async def test_analyze_processes_large_synthetic_image(client: AsyncClient) -> None:
    large_bytes = _create_synthetic_image(2000, 2000, "JPEG")
    files = {"image": ("highres_food.jpg", io.BytesIO(large_bytes), "image/jpeg")}
    response = await client.post("/api/v1/analysis/analyze", files=files)
    assert response.status_code == 200


def test_gemini_service_parses_bounding_boxes() -> None:
    from app.services.gemini_service import GeminiService

    service = GeminiService(api_key="mock", model="gemini")

    # 1. 0-1000 integer coordinates
    box1 = service._parse_bounding_box([100, 200, 900, 800])
    assert box1 is not None
    assert box1.ymin == 0.1
    assert box1.xmin == 0.2
    assert box1.ymax == 0.9
    assert box1.xmax == 0.8

    # 2. 0.0-1.0 float coordinates
    box2 = service._parse_bounding_box([0.15, 0.25, 0.75, 0.85])
    assert box2 is not None
    assert box2.ymin == 0.15
    assert box2.xmin == 0.25
    assert box2.ymax == 0.75
    assert box2.xmax == 0.85

    # 3. Invalid or inverted box coordinates
    assert service._parse_bounding_box([0.8, 0.2, 0.1, 0.8]) is None
    assert service._parse_bounding_box(None) is None
    assert service._parse_bounding_box("not-a-box") is None

