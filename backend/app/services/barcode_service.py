"""OpenFoodFacts Barcode Lookup Service.

Fetches product nutrition, Nutri-Score, NOVA group, ingredients, and
packaging details from the Open Food Facts API v2.
"""

import logging
import re
from typing import Any

import httpx

from app.schemas.barcode import BarcodeProductRead

logger = logging.getLogger(__name__)

OPENFOODFACTS_BASE_URL = "https://world.openfoodfacts.org/api/v2/product"
USER_AGENT = "Heathify - Android/iOS/Web - Version 1.0 (https://github.com/heathify)"


class BarcodeServiceError(Exception):
    """Raised on upstream network or service communication failures."""


class BarcodeService:
    """Service for querying and normalizing packaged food barcodes."""

    def __init__(self, timeout_seconds: float = 6.0) -> None:
        self.timeout_seconds = timeout_seconds

    async def lookup_barcode(self, barcode: str) -> BarcodeProductRead | None:
        """Fetch and normalize product data for a given barcode from OpenFoodFacts."""
        clean_code = re.sub(r"[^0-9a-zA-Z]", "", barcode.strip())
        if not clean_code:
            return None

        url = f"{OPENFOODFACTS_BASE_URL}/{clean_code}.json"
        headers = {"User-Agent": USER_AGENT}

        try:
            async with httpx.AsyncClient(timeout=self.timeout_seconds) as client:
                response = await client.get(url, headers=headers)

                if response.status_code == 404:
                    return None

                if response.status_code != 200:
                    logger.warning(
                        "OpenFoodFacts returned non-200 status %d for barcode %s",
                        response.status_code,
                        clean_code,
                    )
                    return None

                data = response.json()
                return self._parse_openfoodfacts_payload(clean_code, data)
        except httpx.TimeoutException as exc:
            logger.warning("OpenFoodFacts timeout for barcode %s: %s", clean_code, exc)
            raise BarcodeServiceError("OpenFoodFacts API request timed out.") from exc
        except httpx.RequestError as exc:
            logger.warning("OpenFoodFacts network error for barcode %s: %s", clean_code, exc)
            raise BarcodeServiceError("Failed to reach OpenFoodFacts service.") from exc
        except Exception as exc:  # noqa: BLE001
            logger.exception("Unexpected error during barcode lookup for %s: %s", clean_code, exc)
            return None

    def _parse_openfoodfacts_payload(
        self, barcode: str, data: dict[str, Any]
    ) -> BarcodeProductRead | None:
        """Extract and normalize product data from OpenFoodFacts JSON response."""
        status = data.get("status")
        if status != 1:
            return None

        product = data.get("product")
        if not isinstance(product, dict):
            return None

        name = (
            product.get("product_name")
            or product.get("product_name_en")
            or product.get("generic_name")
            or "Unknown Product"
        ).strip()
        if not name:
            name = "Packaged Food"

        brand = product.get("brands") or product.get("brand_owner")
        if isinstance(brand, str):
            brand = brand.strip() or None

        nutriments = product.get("nutriments") or {}

        # 1. Calories (prefer energy-kcal_serving, then energy-kcal_100g, or convert kJ)
        calories = self._extract_nutrient(
            nutriments,
            [
                "energy-kcal_serving",
                "energy-kcal_100g",
                "energy-kcal",
                "energy-kcal_value",
            ],
        )
        if calories is None:
            # Try kJ conversion: 1 kcal = 4.184 kJ
            kj = self._extract_nutrient(nutriments, ["energy_serving", "energy_100g", "energy"])
            if kj is not None and kj > 0:
                calories = round(kj / 4.184, 1)
            else:
                calories = 0.0

        # 2. Macros
        protein = (
            self._extract_nutrient(
                nutriments, ["proteins_serving", "proteins_100g", "proteins"]
            )
            or 0.0
        )
        carbs = (
            self._extract_nutrient(
                nutriments, ["carbohydrates_serving", "carbohydrates_100g", "carbohydrates"]
            )
            or 0.0
        )
        fat = self._extract_nutrient(nutriments, ["fat_serving", "fat_100g", "fat"]) or 0.0
        fiber = self._extract_nutrient(nutriments, ["fiber_serving", "fiber_100g", "fiber"]) or 0.0
        sugars = self._extract_nutrient(nutriments, ["sugars_serving", "sugars_100g", "sugars"])
        sodium = self._extract_nutrient(nutriments, ["sodium_serving", "sodium_100g", "sodium"])

        # 3. Serving size info
        serving_size = product.get("serving_size")
        serving_qty = product.get("serving_quantity")
        serving_unit = "g"

        try:
            if serving_qty is not None and float(serving_qty) > 0:
                serving_quantity = float(serving_qty)
            else:
                serving_quantity = 100.0
        except (ValueError, TypeError):
            serving_quantity = 100.0

        # 4. Nutri-Score & NOVA
        nutriscore = product.get("nutriscore_grade")
        if isinstance(nutriscore, str) and nutriscore.strip().lower() in ("a", "b", "c", "d", "e"):
            nutriscore_grade = nutriscore.strip().lower()
        else:
            nutriscore_grade = None

        nova = product.get("nova_group")
        try:
            nova_group = int(nova) if nova in (1, 2, 3, 4) else None
        except (ValueError, TypeError):
            nova_group = None

        # 5. Images & Ingredients
        image_url = (
            product.get("image_front_url")
            or product.get("image_url")
            or product.get("image_front_small_url")
        )
        ingredients = product.get("ingredients_text") or product.get("ingredients_text_en")

        return BarcodeProductRead(
            barcode=barcode,
            name=name,
            brand=brand,
            serving_size=serving_size,
            serving_quantity=serving_quantity,
            serving_unit=serving_unit,
            calories=round(calories, 1),
            protein=round(protein, 1),
            carbohydrates=round(carbs, 1),
            fat=round(fat, 1),
            fiber=round(fiber, 1),
            sugars=round(sugars, 1) if sugars is not None else None,
            sodium=round(sodium, 3) if sodium is not None else None,
            nutriscore_grade=nutriscore_grade,
            nova_group=nova_group,
            image_url=image_url,
            ingredients=ingredients[:500] if ingredients else None,
            source="openfoodfacts",
        )

    def _extract_nutrient(self, nutriments: dict[str, Any], keys: list[str]) -> float | None:
        """Helper to extract a float nutrient value from the first matching key."""
        for k in keys:
            val = nutriments.get(k)
            if val is not None:
                try:
                    num = float(val)
                    if num >= 0:
                        return num
                except (ValueError, TypeError):
                    continue
        return None
