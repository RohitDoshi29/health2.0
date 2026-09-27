"""Shared pytest fixtures.

Tests run against an in-memory SQLite database (via aiosqlite) rather
than Postgres, and never call the real Gemini API — GeminiService is
overridden with a small fake. This keeps `pytest` runnable with zero
external services and no API key.
"""

from collections.abc import AsyncGenerator

import pytest
import pytest_asyncio
from httpx import ASGITransport, AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine
from sqlalchemy.pool import StaticPool

from app.core.database import Base, get_db
from app.core.security import create_access_token, hash_password
from app.main import app
from app.models.user import User
from app.schemas.analysis import BoundingBox, FoodDetection, GeminiAnalysisResult, QuantityUnit
from app.services.gemini_service import GeminiService, get_gemini_service

# NOTE: requires `aiosqlite` only for tests. If it's not installed,
# `pip install aiosqlite` (dev-only dependency, not needed to run the app).
TEST_DATABASE_URL = "sqlite+aiosqlite:///:memory:"

test_engine = create_async_engine(
    TEST_DATABASE_URL,
    connect_args={"check_same_thread": False},
    poolclass=StaticPool,
)
TestSessionLocal = async_sessionmaker(bind=test_engine, expire_on_commit=False)


class FakeGeminiService(GeminiService):
    """Returns a fixed, valid detection result without any network call."""

    def __init__(self) -> None:
        super().__init__(api_key="test-key", model="fake-model")

    async def detect_foods(self, image_bytes: bytes, mime_type: str) -> GeminiAnalysisResult:
        return GeminiAnalysisResult(
            foods=[
                FoodDetection(
                    name="cooked white rice",
                    estimated_quantity=180,
                    unit=QuantityUnit.G,
                    confidence=0.9,
                    bounding_box=BoundingBox(
                        ymin=0.15,
                        xmin=0.20,
                        ymax=0.85,
                        xmax=0.80,
                    ),
                )
            ]
        )


async def _override_get_db() -> AsyncGenerator[AsyncSession, None]:
    async with TestSessionLocal() as session:
        yield session


def _override_get_gemini_service() -> GeminiService:
    return FakeGeminiService()


@pytest_asyncio.fixture(autouse=True)
async def _setup_database() -> AsyncGenerator[None, None]:
    async with test_engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    yield
    async with test_engine.begin() as conn:
        await conn.run_sync(Base.metadata.drop_all)


@pytest.fixture(autouse=True)
def _apply_overrides():
    app.dependency_overrides[get_db] = _override_get_db
    app.dependency_overrides[get_gemini_service] = _override_get_gemini_service
    yield
    app.dependency_overrides.clear()


@pytest_asyncio.fixture
async def client() -> AsyncGenerator[AsyncClient, None]:
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        yield ac


@pytest_asyncio.fixture
async def db_session() -> AsyncGenerator[AsyncSession, None]:
    async with TestSessionLocal() as session:
        yield session


@pytest_asyncio.fixture
async def test_user(db_session: AsyncSession) -> User:
    user = User(
        name="Test User",
        email="test@example.com",
        hashed_password=hash_password("password123"),
    )
    db_session.add(user)
    await db_session.commit()
    await db_session.refresh(user)
    return user


@pytest_asyncio.fixture
async def auth_headers(test_user: User) -> dict[str, str]:
    token = create_access_token(data={"sub": str(test_user.id), "email": test_user.email})
    return {"Authorization": f"Bearer {token}"}

