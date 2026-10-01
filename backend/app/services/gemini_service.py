"""Gemini food-recognition service.

Responsibility boundary (important — see task spec section 8):

    IMAGE -> FOOD IDENTIFICATION -> PORTION ESTIMATION -> CONFIDENCE

Gemini is NOT the source of truth for calories/macros. It only identifies
food items and estimates portions; NutritionService takes it from there.
"""

import json
import logging

from app.core.config import settings
from app.schemas.analysis import (
    BoundingBox,
    FoodDetection,
    GeminiAnalysisResult,
    QuantityUnit,
)

logger = logging.getLogger(__name__)

# Kept as a plain module-level constant so it's easy to find and tweak
# without digging through service logic.
FOOD_RECOGNITION_PROMPT = """\
You are a food recognition assistant for a nutrition tracking application.

Analyze the provided food image.

Identify visible food items with careful attention to composite dishes:
1. Always identify the PRIMARY DISH first (e.g., "Paneer Pizza", "Veggie Pizza", "Chicken Biryani", "Cheeseburger", "Pasta").
2. If the food is a composite dish (like a pizza, sandwich, burger, curry, bowl, or thali), identify the entire dish as the main food item.
3. Do not break down a single composite dish into independent full-portion ingredients unless they are served as separate side dishes.
4. If notable visible toppings or components are present (e.g. paneer cubes or pepper on a pizza), ensure the primary dish is identified.

For each item provide:
- canonical food name
- estimated quantity
- quantity unit
- confidence score
- box_2d: 2D bounding box [ymin, xmin, ymax, xmax] normalized between 0 and 1000
  (or 0.0 and 1.0) indicating where the item is located in the image.

Do not invent ingredients that cannot reasonably be inferred.
If an item is ambiguous, choose the most likely food and use an
appropriately lower confidence score.

Do not calculate calories or macronutrients.

Return only structured JSON matching this schema, with no extra
commentary or markdown formatting:

{
  "foods": [
    {
      "name": "string, canonical food name",
      "estimated_quantity": "number, positive",
      "unit": "one of: g, ml, piece, cup, tbsp, tsp, slice, bowl",
      "confidence": "number between 0.0 and 1.0",
      "box_2d": [ymin, xmin, ymax, xmax]
    }
  ]
}
"""

BARCODE_OCR_PROMPT = """\
You are an expert OCR and product packaging barcode assistant.
Analyze the provided product image or barcode photo.
Look closely for any visible barcode (UPC-A, EAN-13, EAN-8, Code 128, etc.) or the printed numeric barcode digits under or above the barcode stripes.
Return only a JSON object in this exact format with no extra text or markdown:
{"barcode": "<digits only without spaces or hyphens, e.g. 737628064502>"}
If no barcode or barcode digits are visible in the image, return:
{"barcode": null}
"""


class GeminiServiceError(Exception):
    """Raised when the Gemini API call fails outright (network, auth, etc.)."""


class GeminiResponseParsingError(Exception):
    """Raised when Gemini responds, but the payload doesn't match our schema."""


class GeminiService:
    """Thin wrapper around the Gemini API for food detection.

    Kept as a class (rather than free functions) so it can be swapped for
    a fake/mock implementation in tests via dependency injection.
    """

    def __init__(self, api_key: str | None = None, model: str | None = None) -> None:
        self.api_key = api_key if api_key is not None else settings.GEMINI_API_KEY
        self.model = model if model is not None else settings.GEMINI_MODEL

    async def detect_foods(self, image_bytes: bytes, mime_type: str) -> GeminiAnalysisResult:
        """Send an image to Gemini and return validated food detections.

        Raises:
            GeminiServiceError: on API/network failure.
            GeminiResponseParsingError: if the response can't be parsed
                into the expected schema.
        """
        if not self.api_key:
            raise GeminiServiceError(
                "GEMINI_API_KEY is not configured. Set it in your environment "
                "before calling the analysis endpoint."
            )

        raw_text = await self._call_gemini(image_bytes, mime_type)
        return self._parse_response(raw_text)

    async def extract_barcode(self, image_bytes: bytes, mime_type: str) -> str | None:
        """Attempt to extract numeric barcode digits from a photo using Gemini Vision."""
        if not self.api_key:
            return None
        import re

        from google import genai
        from google.genai import types

        client = genai.Client(api_key=self.api_key)
        try:
            response = await client.aio.models.generate_content(
                model=self.model,
                contents=[
                    types.Part.from_bytes(data=image_bytes, mime_type=mime_type),
                    BARCODE_OCR_PROMPT,
                ],
                config=types.GenerateContentConfig(
                    response_mime_type="application/json",
                ),
            )
            raw = (response.text or "").strip()
            if raw.startswith("```"):
                raw = raw.strip("`")
                if raw.lower().startswith("json"):
                    raw = raw[4:]
                raw = raw.strip()
            data = json.loads(raw)
            code = data.get("barcode")
            if code and isinstance(code, str):
                cleaned = re.sub(r"[^0-9]", "", code.strip())
                return cleaned if len(cleaned) >= 6 else None
            return None
        except Exception as exc:  # noqa: BLE001
            logger.warning("Failed to extract barcode from image with Gemini: %s", exc)
            return None

    async def _call_gemini(self, image_bytes: bytes, mime_type: str) -> str:
        """Make the actual API call using async Google GenAI client with retry."""
        import asyncio

        from google import genai
        from google.genai import types

        client = genai.Client(api_key=self.api_key)
        last_exc: Exception | None = None

        for attempt in range(2):
            try:
                response = await client.aio.models.generate_content(
                    model=self.model,
                    contents=[
                        types.Part.from_bytes(data=image_bytes, mime_type=mime_type),
                        FOOD_RECOGNITION_PROMPT,
                    ],
                    config=types.GenerateContentConfig(
                        response_mime_type="application/json",
                    ),
                )
                return response.text or ""
            except Exception as exc:  # noqa: BLE001
                last_exc = exc
                logger.warning(
                    "Gemini API attempt %d failed: %s (%s)",
                    attempt + 1,
                    type(exc).__name__,
                    exc,
                )
                if attempt == 0:
                    await asyncio.sleep(1.0)

        logger.exception("Gemini API call failed after retries: %s", last_exc)
        raise GeminiServiceError(f"Failed to reach the Gemini API: {last_exc}") from last_exc

    def _parse_bounding_box(self, raw_box: object) -> BoundingBox | None:
        """Helper to extract and normalize bounding box coordinates to [0.0, 1.0]."""
        if not raw_box:
            return None

        try:
            ymin, xmin, ymax, xmax = 0.0, 0.0, 0.0, 0.0
            if isinstance(raw_box, list | tuple) and len(raw_box) == 4:
                ymin, xmin, ymax, xmax = (float(v) for v in raw_box)
            elif isinstance(raw_box, dict):
                ymin = float(raw_box.get("ymin", raw_box.get("top", 0.0)))
                xmin = float(raw_box.get("xmin", raw_box.get("left", 0.0)))
                ymax = float(raw_box.get("ymax", raw_box.get("bottom", 0.0)))
                xmax = float(raw_box.get("xmax", raw_box.get("right", 0.0)))
            else:
                return None

            # If coordinates are 0-1000 scale, normalize to 0.0-1.0
            if max(ymin, xmin, ymax, xmax) > 1.0:
                ymin /= 1000.0
                xmin /= 1000.0
                ymax /= 1000.0
                xmax /= 1000.0

            ymin = max(0.0, min(1.0, ymin))
            xmin = max(0.0, min(1.0, xmin))
            ymax = max(0.0, min(1.0, ymax))
            xmax = max(0.0, min(1.0, xmax))

            if ymax <= ymin or xmax <= xmin:
                return None

            return BoundingBox(ymin=ymin, xmin=xmin, ymax=ymax, xmax=xmax)
        except Exception:
            return None

    def _parse_response(self, raw_text: str) -> GeminiAnalysisResult:
        """Parse + validate Gemini's JSON text into GeminiAnalysisResult.

        Any malformed item (bad unit, non-positive quantity, out-of-range
        confidence, etc.) results in a clean GeminiResponseParsingError
        rather than a partially-trusted result.
        """
        cleaned = raw_text.strip()
        # Defensive: strip accidental markdown fences if the model adds them.
        if cleaned.startswith("```"):
            cleaned = cleaned.strip("`")
            if cleaned.lower().startswith("json"):
                cleaned = cleaned[4:]
            cleaned = cleaned.strip()

        try:
            payload = json.loads(cleaned)
        except json.JSONDecodeError as exc:
            raise GeminiResponseParsingError("Gemini did not return valid JSON.") from exc

        if not isinstance(payload, dict) or "foods" not in payload:
            raise GeminiResponseParsingError("Gemini response missing 'foods' key.")

        detections: list[FoodDetection] = []
        for item in payload.get("foods", []):
            try:
                raw_box = item.get("box_2d") or item.get("bounding_box")
                bbox = self._parse_bounding_box(raw_box)

                detections.append(
                    FoodDetection(
                        name=item["name"],
                        estimated_quantity=item["estimated_quantity"],
                        unit=QuantityUnit(item["unit"]),
                        confidence=item["confidence"],
                        bounding_box=bbox,
                    )
                )
            except (KeyError, ValueError, TypeError) as exc:
                # Skip individual malformed items rather than failing the
                # whole request — but log for visibility.
                logger.warning("Skipping malformed Gemini food item: %s", exc)
                continue

        if not detections and payload.get("foods"):
            # Every item was malformed — treat this as a hard parsing failure.
            raise GeminiResponseParsingError("None of the items in Gemini's response were valid.")

        return GeminiAnalysisResult(foods=detections)


def get_gemini_service() -> GeminiService:
    """FastAPI dependency factory."""
    return GeminiService()
