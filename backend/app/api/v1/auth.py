"""Authentication endpoints — signup, login, profile."""

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.core.security import (
    create_access_token,
    get_current_user,
    hash_password,
    verify_password,
)
from app.models.goal import Goal
from app.models.user import User
from app.schemas.user import GoogleAuthRequest, TokenResponse, UserCreate, UserLogin, UserRead

router = APIRouter(prefix="/auth", tags=["auth"])


@router.post("/signup", response_model=TokenResponse, status_code=status.HTTP_201_CREATED)
async def signup(payload: UserCreate, db: AsyncSession = Depends(get_db)) -> TokenResponse:
    """Register a new user account with hashed password and return an access token."""
    # Check if user already exists
    existing = await db.execute(select(User).where(User.email == payload.email))
    if existing.scalar_one_or_none() is not None:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Email is already registered.",
        )

    user = User(
        name=payload.name,
        email=payload.email,
        hashed_password=hash_password(payload.password),
        auth_provider="email",
    )
    db.add(user)
    try:
        await db.commit()
    except IntegrityError as exc:
        await db.rollback()
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Email is already registered.",
        ) from exc

    await db.refresh(user)

    # Initialize default daily goals for new user
    default_goal = Goal(
        user_id=user.id,
        calorie_target=2000.0,
        protein_target=120.0,
        carbohydrates_target=250.0,
        fat_target=65.0,
        fiber_target=30.0,
    )
    db.add(default_goal)
    await db.commit()

    access_token = create_access_token(data={"sub": str(user.id), "email": user.email})
    return TokenResponse(
        access_token=access_token,
        token_type="bearer",
        user=UserRead.model_validate(user),
    )


@router.post("/login", response_model=TokenResponse)
async def login(payload: UserLogin, db: AsyncSession = Depends(get_db)) -> TokenResponse:
    """Authenticate user with email and password, returning an access token."""
    result = await db.execute(select(User).where(User.email == payload.email))
    user = result.scalar_one_or_none()

    if (
        user is None
        or user.hashed_password is None
        or not verify_password(payload.password, user.hashed_password)
    ):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid email or password.",
            headers={"WWW-Authenticate": "Bearer"},
        )

    access_token = create_access_token(data={"sub": str(user.id), "email": user.email})
    return TokenResponse(
        access_token=access_token,
        token_type="bearer",
        user=UserRead.model_validate(user),
    )


@router.post("/google", response_model=TokenResponse)
@router.post("/firebase", response_model=TokenResponse)
async def google_or_firebase_auth(
    payload: GoogleAuthRequest,
    db: AsyncSession = Depends(get_db),
) -> TokenResponse:
    """Authenticate or register user via Google / Firebase OAuth token exchange."""
    if not payload.id_token or not payload.id_token.strip():
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Valid ID Token is required.",
        )

    # Check for existing user by email
    result = await db.execute(select(User).where(User.email == payload.email))
    user = result.scalar_one_or_none()

    if user is None:
        # Create new user
        user_name = (
            payload.name.strip()
            if payload.name and payload.name.strip()
            else payload.email.split("@")[0]
        )
        user = User(
            name=user_name,
            email=payload.email,
            auth_provider="google",
            avatar_url=payload.avatar_url,
            firebase_uid=payload.firebase_uid,
        )
        db.add(user)
        await db.commit()
        await db.refresh(user)

        # Initialize default daily goals
        default_goal = Goal(
            user_id=user.id,
            calorie_target=2000.0,
            protein_target=120.0,
            carbohydrates_target=250.0,
            fat_target=65.0,
            fiber_target=30.0,
        )
        db.add(default_goal)
        await db.commit()
    else:
        # Update profile avatar / uid if provided
        updated = False
        if payload.avatar_url and user.avatar_url != payload.avatar_url:
            user.avatar_url = payload.avatar_url
            updated = True
        if payload.firebase_uid and user.firebase_uid != payload.firebase_uid:
            user.firebase_uid = payload.firebase_uid
            updated = True
        if updated:
            await db.commit()
            await db.refresh(user)

    access_token = create_access_token(data={"sub": str(user.id), "email": user.email})
    return TokenResponse(
        access_token=access_token,
        token_type="bearer",
        user=UserRead.model_validate(user),
    )


@router.get("/me", response_model=UserRead)
async def get_me(current_user: User = Depends(get_current_user)) -> UserRead:
    """Return the profile of the currently authenticated user."""
    return UserRead.model_validate(current_user)

