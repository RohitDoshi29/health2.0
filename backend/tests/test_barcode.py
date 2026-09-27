"""Tests for Barcode OpenFoodFacts integration."""

import pytest
from httpx import AsyncClient, Response

from app.schemas.barcode import BarcodeProductRead
from app.services.barcode_service import BarcodeService, BarcodeServiceError

MOCK_OFF_FOUND_PAYLOAD = {
    "code": "737628064502",
    "status": 1,
    "status_verbose": "product found",
    "product": {
        "product_name": "Organic Rolled Oats",
        "brands": "Bob's Red Mill",
        "serving_size": "48 g (0.5 cup)",
        "serving_quantity": 48.0,
        "nutriments": {
            "energy-kcal_serving": 190.0,
            "energy-kcal_100g": 395.0,
            "proteins_serving": 7.0,
            "proteins_100g": 14.5,
            "carbohydrates_serving": 32.0,
            "carbohydrates_100g": 66.6,
            "fat_serving": 3.5,
            "fat_100g": 7.2,
            "fiber_serving": 5.0,
            "fiber_100g": 10.4,
            "sugars_serving": 1.0,
            "sodium_serving": 0.005,
        },
        "nutriscore_grade": "a",
        "nova_group": 1,
        "image_front_url": "https://images.openfoodfacts.org/images/products/rolled_oats.jpg",
        "ingredients_text": "Whole grain rolled oats.",
    },
}

MOCK_OFF_NOT_FOUND_PAYLOAD = {
    "code": "000000000000",
    "status": 0,
    "status_verbose": "product not found",
}


@pytest.mark.asyncio
async def test_barcode_service_success(monkeypatch: pytest.MonkeyPatch) -> None:
    service = BarcodeService()

    async def mock_get(url: str, headers: dict | None = None) -> Response:
        return Response(200, json=MOCK_OFF_FOUND_PAYLOAD)

    monkeypatch.setattr(
        "httpx.AsyncClient.get",
        lambda self, url, headers=None: mock_get(url, headers),
    )

    result = await service.lookup_barcode("737628064502")
    assert result is not None
    assert isinstance(result, BarcodeProductRead)
    assert result.barcode == "737628064502"
    assert result.name == "Organic Rolled Oats"
    assert result.brand == "Bob's Red Mill"
    assert result.calories == 190.0
    assert result.protein == 7.0
    assert result.carbohydrates == 32.0
    assert result.fat == 3.5
    assert result.fiber == 5.0
    assert result.nutriscore_grade == "a"
    assert result.nova_group == 1
    assert result.image_url == "https://images.openfoodfacts.org/images/products/rolled_oats.jpg"
    assert result.ingredients == "Whole grain rolled oats."


@pytest.mark.asyncio
async def test_barcode_service_not_found(monkeypatch: pytest.MonkeyPatch) -> None:
    service = BarcodeService()

    async def mock_get(url: str, headers: dict | None = None) -> Response:
        return Response(200, json=MOCK_OFF_NOT_FOUND_PAYLOAD)

    monkeypatch.setattr(
        "httpx.AsyncClient.get",
        lambda self, url, headers=None: mock_get(url, headers),
    )

    result = await service.lookup_barcode("000000000000")
    assert result is None


@pytest.mark.asyncio
async def test_barcode_service_404_http(monkeypatch: pytest.MonkeyPatch) -> None:
    service = BarcodeService()

    async def mock_get(url: str, headers: dict | None = None) -> Response:
        return Response(404, json={"status": 0})

    monkeypatch.setattr(
        "httpx.AsyncClient.get",
        lambda self, url, headers=None: mock_get(url, headers),
    )

    result = await service.lookup_barcode("404040404040")
    assert result is None


@pytest.mark.asyncio
async def test_barcode_service_kj_conversion(monkeypatch: pytest.MonkeyPatch) -> None:
    service = BarcodeService()

    payload = {
        "status": 1,
        "product": {
            "product_name": "Greek Yogurt",
            "nutriments": {
                "energy_serving": 418.4,  # 100 kcal
                "proteins_serving": 10.0,
                "carbohydrates_serving": 4.0,
                "fat_serving": 0.0,
            },
        },
    }

    async def mock_get(url: str, headers: dict | None = None) -> Response:
        return Response(200, json=payload)

    monkeypatch.setattr(
        "httpx.AsyncClient.get",
        lambda self, url, headers=None: mock_get(url, headers),
    )

    result = await service.lookup_barcode("123456789012")
    assert result is not None
    assert result.calories == 100.0


@pytest.mark.asyncio
async def test_barcode_api_endpoint_success(
    client: AsyncClient, monkeypatch: pytest.MonkeyPatch
) -> None:
    async def mock_lookup(self: BarcodeService, barcode: str) -> BarcodeProductRead | None:
        return BarcodeProductRead(
            barcode=barcode,
            name="Organic Rolled Oats",
            brand="Bob's Red Mill",
            serving_size="48 g",
            serving_quantity=48.0,
            serving_unit="g",
            calories=190.0,
            protein=7.0,
            carbohydrates=32.0,
            fat=3.5,
            fiber=5.0,
            nutriscore_grade="a",
            nova_group=1,
            image_url="https://images.openfoodfacts.org/images/products/rolled_oats.jpg",
            ingredients="Whole grain oats",
        )

    monkeypatch.setattr(BarcodeService, "lookup_barcode", mock_lookup)

    response = await client.get("/api/v1/nutrition/barcode/737628064502")
    assert response.status_code == 200
    data = response.json()
    assert data["barcode"] == "737628064502"
    assert data["name"] == "Organic Rolled Oats"
    assert data["calories"] == 190.0
    assert data["nutriscore_grade"] == "a"


@pytest.mark.asyncio
async def test_barcode_api_endpoint_not_found(
    client: AsyncClient, monkeypatch: pytest.MonkeyPatch
) -> None:
    async def mock_lookup(self: BarcodeService, barcode: str) -> BarcodeProductRead | None:
        return None

    monkeypatch.setattr(BarcodeService, "lookup_barcode", mock_lookup)

    response = await client.get("/api/v1/nutrition/barcode/000000000000")
    assert response.status_code == 404
    assert "not found" in response.json()["detail"].lower()


@pytest.mark.asyncio
async def test_barcode_api_endpoint_upstream_error(
    client: AsyncClient, monkeypatch: pytest.MonkeyPatch
) -> None:
    async def mock_lookup(self: BarcodeService, barcode: str) -> BarcodeProductRead | None:
        raise BarcodeServiceError("OpenFoodFacts request timed out.")

    monkeypatch.setattr(BarcodeService, "lookup_barcode", mock_lookup)

    response = await client.get("/api/v1/nutrition/barcode/999999999999")
    assert response.status_code == 502
    assert "Failed to lookup barcode" in response.json()["detail"]
