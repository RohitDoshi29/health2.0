"""Schemas for Barcode product lookups (OpenFoodFacts integration)."""

from pydantic import BaseModel, Field


class BarcodeProductRead(BaseModel):
    """Normalized nutritional and packaging information for a scanned barcode product."""

    barcode: str = Field(min_length=1, description="EAN/UPC barcode number")
    name: str = Field(min_length=1, description="Product or brand name")
    brand: str | None = Field(default=None, description="Brand or manufacturer")
    serving_size: str | None = Field(
        default=None, description="Serving size text (e.g. '30 g', '1 cup')"
    )
    serving_quantity: float = Field(default=100.0, gt=0, description="Serving size in grams or ml")
    serving_unit: str = Field(default="g", description="Unit for serving quantity")
    calories: float = Field(ge=0, description="Estimated calories per serving (kcal)")
    protein: float = Field(default=0.0, ge=0, description="Protein in grams")
    carbohydrates: float = Field(default=0.0, ge=0, description="Carbohydrates in grams")
    fat: float = Field(default=0.0, ge=0, description="Fat in grams")
    fiber: float = Field(default=0.0, ge=0, description="Dietary fiber in grams")
    sugars: float | None = Field(default=None, ge=0, description="Sugars in grams")
    sodium: float | None = Field(default=None, ge=0, description="Sodium in grams")
    nutriscore_grade: str | None = Field(
        default=None, description="Nutri-Score grade (a, b, c, d, e)"
    )
    nova_group: int | None = Field(
        default=None, ge=1, le=4, description="NOVA food processing group (1-4)"
    )
    image_url: str | None = Field(default=None, description="Product image URL")
    ingredients: str | None = Field(default=None, description="Ingredients list text")
    source: str = "openfoodfacts"
