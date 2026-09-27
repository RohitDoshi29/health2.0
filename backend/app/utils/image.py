"""Image validation and preprocessing utilities."""

import io
from dataclasses import dataclass

from fastapi import UploadFile
from PIL import Image, ImageOps

from app.core.config import settings

ALLOWED_CONTENT_TYPES: dict[str, bytes] = {
    "image/jpeg": b"\xff\xd8\xff",
    "image/png": b"\x89PNG\r\n\x1a\n",
    "image/webp": b"RIFF",  # followed by size + "WEBP", checked separately below
}


class InvalidImageError(ValueError):
    """Raised when an uploaded file fails image validation."""


class ImageTooLargeError(ValueError):
    """Raised when an uploaded file exceeds the configured size limit."""


@dataclass
class ValidatedImage:
    content: bytes
    content_type: str
    size_bytes: int


def sniff_image_type(content: bytes) -> str | None:
    """Sniff image format from binary magic bytes."""
    if content.startswith(b"\xff\xd8\xff"):
        return "image/jpeg"
    if content.startswith(b"\x89PNG\r\n\x1a\n"):
        return "image/png"
    if content[:4] == b"RIFF" and len(content) >= 12 and content[8:12] == b"WEBP":
        return "image/webp"
    return None


def _looks_like_declared_type(content: bytes, content_type: str) -> bool:
    """Best-effort magic-byte sniff so we don't trust the client Content-Type alone."""
    sniffed = sniff_image_type(content)
    if sniffed is not None and sniffed == content_type:
        return True
    signature = ALLOWED_CONTENT_TYPES.get(content_type)
    if signature is None:
        return False
    if content_type == "image/webp":
        return content[:4] == b"RIFF" and len(content) >= 12 and content[8:12] == b"WEBP"
    return content.startswith(signature)


async def validate_and_read_image(upload: UploadFile) -> ValidatedImage:
    """Validate MIME type, magic bytes, and size; return the raw bytes.

    Raises InvalidImageError / ImageTooLargeError on failure — the API
    layer is responsible for translating these into HTTP error responses.
    """
    if upload is None:
        raise InvalidImageError("No image was uploaded.")

    content = await upload.read()
    size_bytes = len(content)

    if size_bytes == 0:
        raise InvalidImageError("Uploaded image is empty.")

    if size_bytes > settings.max_upload_size_bytes:
        raise ImageTooLargeError(
            f"Image exceeds the {settings.MAX_UPLOAD_SIZE_MB} MB upload limit."
        )

    declared_type = (upload.content_type or "").lower().strip()
    sniffed_type = sniff_image_type(content)

    # If client sends generic / octet-stream / empty content type, use sniffed image type
    if declared_type in ("application/octet-stream", "", "binary/octet-stream"):
        if sniffed_type in ALLOWED_CONTENT_TYPES:
            declared_type = sniffed_type

    if declared_type not in ALLOWED_CONTENT_TYPES:
        # Check if sniffed bytes are valid
        if sniffed_type in ALLOWED_CONTENT_TYPES:
            declared_type = sniffed_type
        else:
            raise InvalidImageError(
                f"Unsupported content type '{declared_type}'. "
                f"Allowed types: {', '.join(sorted(ALLOWED_CONTENT_TYPES))}."
            )

    if not _looks_like_declared_type(content, declared_type):
        raise InvalidImageError(
            "File contents do not match the declared image type. "
            "The upload may be corrupted or mislabeled."
        )

    return ValidatedImage(content=content, content_type=declared_type, size_bytes=size_bytes)


def resize_if_needed(
    image: ValidatedImage, max_dimension_px: int = 1600, quality: int = 85
) -> ValidatedImage:
    """Downscale images exceeding max_dimension_px and compress JPEG/WEBP/PNG output.

    Also automatically adjusts EXIF rotation to ensure proper orientation.
    """
    try:
        with Image.open(io.BytesIO(image.content)) as pil_img:
            # Handle orientation from EXIF tags
            pil_img = ImageOps.exif_transpose(pil_img)

            width, height = pil_img.size
            needs_downscale = width > max_dimension_px or height > max_dimension_px

            if needs_downscale:
                pil_img.thumbnail(
                    (max_dimension_px, max_dimension_px), Image.Resampling.LANCZOS
                )

            out_io = io.BytesIO()
            mime = image.content_type.lower()

            if mime == "image/png":
                pil_img.save(out_io, format="PNG", optimize=True)
            elif mime == "image/webp":
                pil_img.save(out_io, format="WEBP", quality=quality)
            else:
                if pil_img.mode in ("RGBA", "P"):
                    pil_img = pil_img.convert("RGB")
                pil_img.save(out_io, format="JPEG", quality=quality, optimize=True)

            compressed_bytes = out_io.getvalue()

            # Return optimized version if smaller or if dimensions/orientation were changed
            if len(compressed_bytes) < image.size_bytes or needs_downscale:
                return ValidatedImage(
                    content=compressed_bytes,
                    content_type=mime,
                    size_bytes=len(compressed_bytes),
                )
    except Exception:
        # Fallback safely to original bytes if Pillow encounters an issue
        pass

    return image


def save_image_bytes(content: bytes, content_type: str) -> str:
    """Save raw image bytes to configured upload directory and return relative URL."""
    import uuid
    from pathlib import Path

    ext = ".jpg"
    if content_type == "image/png":
        ext = ".png"
    elif content_type == "image/webp":
        ext = ".webp"

    filename = f"meal_{uuid.uuid4().hex}{ext}"
    upload_path = Path(settings.UPLOAD_DIR)
    upload_path.mkdir(parents=True, exist_ok=True)
    file_dest = upload_path / filename

    with open(file_dest, "wb") as f:
        f.write(content)

    return f"/uploads/{filename}"
