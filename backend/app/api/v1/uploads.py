"""Direct image upload endpoint for food and meal photos."""

from fastapi import APIRouter, File, HTTPException, UploadFile, status
from pydantic import BaseModel, Field

from app.utils.image import (
    ImageTooLargeError,
    InvalidImageError,
    resize_if_needed,
    save_image_bytes,
    validate_and_read_image,
)

router = APIRouter(prefix="/uploads", tags=["uploads"])


class UploadResponse(BaseModel):
    image_url: str = Field(..., description="Relative URL of the uploaded image")
    content_type: str = Field(..., description="Detected MIME type")
    size_bytes: int = Field(..., description="Processed image size in bytes")


@router.post("", response_model=UploadResponse, status_code=status.HTTP_201_CREATED)
async def upload_image(
    image: UploadFile = File(..., description="Image file (JPEG/PNG/WEBP)"),
) -> UploadResponse:
    """Upload and optimize a meal or food photo."""
    try:
        validated = await validate_and_read_image(image)
        optimized = resize_if_needed(validated)
        url = save_image_bytes(optimized.content, optimized.content_type)
        return UploadResponse(
            image_url=url,
            content_type=optimized.content_type,
            size_bytes=optimized.size_bytes,
        )
    except InvalidImageError as exc:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST, detail=str(exc)
        ) from exc
    except ImageTooLargeError as exc:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST, detail=str(exc)
        ) from exc
    except Exception as exc:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to save uploaded image.",
        ) from exc

