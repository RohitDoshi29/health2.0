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


def test_gemini_service_parse_validation_response_confidence_threshold() -> None:
    from app.schemas.analysis import ImageClassificationType
    from app.services.gemini_service import GeminiService

    service = GeminiService(api_key="mock", model="gemini")

    # 1. High confidence food
    r1 = service._parse_validation_response('{"type": "food", "confidence": 0.95, "description": "salad bowl"}')
    assert r1.type == ImageClassificationType.FOOD
    assert r1.confidence == 0.95

    # 2. Low confidence food below threshold (< 0.65) -> converts to UNCERTAIN
    r2 = service._parse_validation_response('{"type": "food", "confidence": 0.55, "description": "unclear plate"}')
    assert r2.type == ImageClassificationType.UNCERTAIN
    assert r2.confidence == 0.55

    # 3. Non-food item (e.g. laptop / shoes)
    r3 = service._parse_validation_response('{"type": "non_food", "confidence": 0.98, "description": "laptop keyboard"}')
    assert r3.type == ImageClassificationType.NON_FOOD
    assert r3.confidence == 0.98

    # 4. Barcode
    r4 = service._parse_validation_response('{"type": "barcode", "confidence": 0.99, "description": "product barcode"}')
    assert r4.type == ImageClassificationType.BARCODE
    assert r4.confidence == 0.99

    # 5. Invalid / unparseable JSON
    r5 = service._parse_validation_response('invalid json')
    assert r5.type == ImageClassificationType.UNCERTAIN


@pytest.mark.asyncio
async def test_analyze_rejects_non_food_item(client: AsyncClient) -> None:
    from app.main import app
    from app.schemas.analysis import ImageClassificationType, ImageValidationResult
    from app.services.gemini_service import GeminiService, get_gemini_service

    class NonFoodFakeGeminiService(GeminiService):
        def __init__(self) -> None:
            super().__init__(api_key="test-key", model="fake-model")

        async def validate_image(self, image_bytes: bytes, mime_type: str) -> ImageValidationResult:
            return ImageValidationResult(
                type=ImageClassificationType.NON_FOOD,
                confidence=0.97,
                description="laptop keyboard",
            )

    app.dependency_overrides[get_gemini_service] = lambda: NonFoodFakeGeminiService()
    try:
        img = Image.new("RGB", (300, 300), color=(20, 30, 40))
        buf = io.BytesIO()
        img.save(buf, format="JPEG")
        img_bytes = buf.getvalue()
        files = {"image": ("laptop.jpg", io.BytesIO(img_bytes), "image/jpeg")}
        response = await client.post("/api/v1/analysis/analyze", files=files)

        assert response.status_code == 200
        body = response.json()
        assert body["status"] == "non_food"
        assert body["validation_type"] == "non_food"
        assert body["validation_message"] == "⚠️ Non-eatable item detected. Please upload an image of food or a food barcode."
        assert len(body["items"]) == 0
        assert body["total"]["estimated_calories"] == 0.0
    finally:
        from tests.conftest import _override_get_gemini_service
        app.dependency_overrides[get_gemini_service] = _override_get_gemini_service


@pytest.mark.asyncio
async def test_analyze_rejects_uncertain_blurry_image(client: AsyncClient) -> None:
    from app.main import app
    from app.schemas.analysis import ImageClassificationType, ImageValidationResult
    from app.services.gemini_service import GeminiService, get_gemini_service

    class UncertainFakeGeminiService(GeminiService):
        def __init__(self) -> None:
            super().__init__(api_key="test-key", model="fake-model")

        async def validate_image(self, image_bytes: bytes, mime_type: str) -> ImageValidationResult:
            return ImageValidationResult(
                type=ImageClassificationType.UNCERTAIN,
                confidence=0.45,
                description="blurry background",
            )

    app.dependency_overrides[get_gemini_service] = lambda: UncertainFakeGeminiService()
    try:
        img = Image.new("RGB", (320, 320), color=(120, 130, 140))
        buf = io.BytesIO()
        img.save(buf, format="JPEG")
        img_bytes = buf.getvalue()
        files = {"image": ("blurry.jpg", io.BytesIO(img_bytes), "image/jpeg")}
        response = await client.post("/api/v1/analysis/analyze", files=files)

        assert response.status_code == 200
        body = response.json()
        assert body["status"] == "uncertain"
        assert body["validation_type"] == "uncertain"
        assert body["validation_message"] == "⚠️ We couldn't identify food in this image. Please upload a clearer image of your food or barcode."
        assert len(body["items"]) == 0
        assert body["total"]["estimated_calories"] == 0.0
    finally:
        from tests.conftest import _override_get_gemini_service
        app.dependency_overrides[get_gemini_service] = _override_get_gemini_service


@pytest.mark.asyncio
async def test_analyze_routes_barcode_without_calorie_estimation(client: AsyncClient) -> None:
    from app.main import app
    from app.schemas.analysis import ImageClassificationType, ImageValidationResult
    from app.services.gemini_service import GeminiService, get_gemini_service

    class BarcodeFakeGeminiService(GeminiService):
        def __init__(self) -> None:
            super().__init__(api_key="test-key", model="fake-model")

        async def validate_image(self, image_bytes: bytes, mime_type: str) -> ImageValidationResult:
            return ImageValidationResult(
                type=ImageClassificationType.BARCODE,
                confidence=0.99,
                description="product barcode",
            )

        async def extract_barcode(self, image_bytes: bytes, mime_type: str) -> str | None:
            return "737628064502"

        async def detect_foods(self, image_bytes: bytes, mime_type: str):
            raise AssertionError("detect_foods should NOT be called for barcodes!")

    app.dependency_overrides[get_gemini_service] = lambda: BarcodeFakeGeminiService()
    try:
        img = Image.new("RGB", (350, 350), color=(220, 230, 240))
        buf = io.BytesIO()
        img.save(buf, format="JPEG")
        img_bytes = buf.getvalue()
        files = {"image": ("barcode.jpg", io.BytesIO(img_bytes), "image/jpeg")}
        response = await client.post("/api/v1/analysis/analyze", files=files)

        assert response.status_code == 200
        body = response.json()
        assert body["status"] == "barcode"
        assert body["validation_type"] == "barcode"
        assert len(body["items"]) == 0
    finally:
        from tests.conftest import _override_get_gemini_service
        app.dependency_overrides[get_gemini_service] = _override_get_gemini_service

