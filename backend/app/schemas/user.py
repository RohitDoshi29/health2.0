"""User schemas."""

import uuid
from datetime import datetime

from pydantic import BaseModel, ConfigDict, EmailStr, Field


class UserBase(BaseModel):
    name: str = Field(..., min_length=1, max_length=255)
    email: EmailStr


class UserCreate(UserBase):
    """Payload to create/register a user with a password."""

    password: str = Field(..., min_length=8, description="Password (at least 8 characters)")


class UserLogin(BaseModel):
    """Payload for user login."""

    email: EmailStr
    password: str


class UserUpdate(BaseModel):
    name: str | None = Field(default=None, min_length=1, max_length=255)
    email: EmailStr | None = None


class UserRead(UserBase):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    auth_provider: str = "email"
    avatar_url: str | None = None
    firebase_uid: str | None = None
    created_at: datetime
    updated_at: datetime
    onboarding_completed: bool = False


class GoogleAuthRequest(BaseModel):
    """Payload sent when a user signs in with Google / Firebase on mobile."""

    id_token: str = Field(..., description="Google or Firebase ID Token")
    email: EmailStr
    name: str | None = None
    avatar_url: str | None = None
    firebase_uid: str | None = None


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user: UserRead
