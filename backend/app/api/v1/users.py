"""User endpoints: registration, read, and onboarding profile."""

import uuid

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.core.security import get_current_user, hash_password
from app.models.goal import Goal
from app.models.user import User
from app.models.user_profile import UserProfile
from app.schemas.goal import GoalRead
from app.schemas.profile import (
    UserProfileBase,
    UserProfileCreate,
    UserProfilePreviewRequest,
    UserProfilePreviewResponse,
    UserProfileRead,
    UserProfileResponse,
)
from app.schemas.user import UserCreate, UserRead
from app.services.profile_service import ProfileService

router = APIRouter(prefix="/users", tags=["users"])


@router.post("", response_model=UserRead, status_code=status.HTTP_201_CREATED)
async def create_user(payload: UserCreate, db: AsyncSession = Depends(get_db)) -> UserRead:
    user = User(
        name=payload.name,
        email=payload.email,
        hashed_password=hash_password(payload.password),
    )

    db.add(user)
    try:
        await db.commit()
    except IntegrityError as exc:
        await db.rollback()
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST, detail="Email already registered."
        ) from exc
    await db.refresh(user)
    return UserRead.model_validate(user)


# Profile endpoints must be declared before /{user_id} so "me" is not parsed as a UUID.
@router.post("/me/profile/preview", response_model=UserProfilePreviewResponse)
async def preview_profile(
    payload: UserProfilePreviewRequest,
    current_user: User = Depends(get_current_user),
) -> UserProfilePreviewResponse:
    """Calculate BMR, TDEE, and recommended nutrition goals without saving."""
    targets = ProfileService.calculate_targets(payload)
    return UserProfilePreviewResponse(
        bmr=targets.bmr,
        tdee=targets.tdee,
        calorie_target=targets.calorie_target,
        protein_target=targets.protein_target,
        carbohydrates_target=targets.carbohydrates_target,
        fat_target=targets.fat_target,
        fiber_target=targets.fiber_target,
        water_target_ml=targets.water_target_ml,
    )


@router.post("/me/profile", response_model=UserProfileResponse)
async def save_profile(
    payload: UserProfileCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> UserProfileResponse:
    """Save user onboarding profile, calculate, write/update daily Goal targets, and return both."""
    targets = ProfileService.calculate_targets(payload)

    # Upsert UserProfile
    result = await db.execute(select(UserProfile).where(UserProfile.user_id == current_user.id))
    profile = result.scalar_one_or_none()
    if profile is None:
        profile = UserProfile(
            user_id=current_user.id,
            age=payload.age,
            sex=payload.sex,
            height_cm=payload.height_cm,
            weight_kg=payload.weight_kg,
            activity_level=payload.activity_level,
            goal=payload.goal,
            onboarding_completed=True,
        )
        db.add(profile)
    else:
        profile.age = payload.age
        profile.sex = payload.sex
        profile.height_cm = payload.height_cm
        profile.weight_kg = payload.weight_kg
        profile.activity_level = payload.activity_level
        profile.goal = payload.goal
        profile.onboarding_completed = True

    current_user.onboarding_completed = True

    # Upsert Goal targets
    goal_res = await db.execute(select(Goal).where(Goal.user_id == current_user.id))
    goal = goal_res.scalar_one_or_none()
    if goal is None:
        goal = Goal(
            user_id=current_user.id,
            calorie_target=targets.calorie_target,
            protein_target=targets.protein_target,
            carbohydrates_target=targets.carbohydrates_target,
            fat_target=targets.fat_target,
            fiber_target=targets.fiber_target,
            water_target_ml=targets.water_target_ml,
        )
        db.add(goal)
    else:
        goal.calorie_target = targets.calorie_target
        goal.protein_target = targets.protein_target
        goal.carbohydrates_target = targets.carbohydrates_target
        goal.fat_target = targets.fat_target
        goal.fiber_target = targets.fiber_target
        goal.water_target_ml = targets.water_target_ml

    await db.commit()
    await db.refresh(profile)
    await db.refresh(goal)

    profile_read = UserProfileRead(
        id=profile.id,
        user_id=profile.user_id,
        age=profile.age,
        sex=profile.sex,
        height_cm=profile.height_cm,
        weight_kg=profile.weight_kg,
        activity_level=profile.activity_level,
        goal=profile.goal,
        onboarding_completed=profile.onboarding_completed,
        bmr=targets.bmr,
        tdee=targets.tdee,
        created_at=profile.created_at,
        updated_at=profile.updated_at,
    )

    return UserProfileResponse(
        profile=profile_read,
        goal=GoalRead.model_validate(goal),
        bmr=targets.bmr,
        tdee=targets.tdee,
    )


@router.get("/me/profile", response_model=UserProfileResponse)
async def get_my_profile(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> UserProfileResponse:
    """Retrieve the current user's biometric profile and computed goals."""
    result = await db.execute(select(UserProfile).where(UserProfile.user_id == current_user.id))
    profile = result.scalar_one_or_none()
    if profile is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User profile not found. Please complete onboarding.",
        )

    targets = ProfileService.calculate_targets(
        UserProfileBase(
            age=profile.age,
            sex=profile.sex,  # type: ignore
            height_cm=profile.height_cm,
            weight_kg=profile.weight_kg,
            activity_level=profile.activity_level,  # type: ignore
            goal=profile.goal,  # type: ignore
        )
    )

    goal_res = await db.execute(select(Goal).where(Goal.user_id == current_user.id))
    goal = goal_res.scalar_one_or_none()
    if goal is None:
        goal = Goal(
            user_id=current_user.id,
            calorie_target=targets.calorie_target,
            protein_target=targets.protein_target,
            carbohydrates_target=targets.carbohydrates_target,
            fat_target=targets.fat_target,
            fiber_target=targets.fiber_target,
            water_target_ml=targets.water_target_ml,
        )
        db.add(goal)
        await db.commit()
        await db.refresh(goal)

    profile_read = UserProfileRead(
        id=profile.id,
        user_id=profile.user_id,
        age=profile.age,
        sex=profile.sex,
        height_cm=profile.height_cm,
        weight_kg=profile.weight_kg,
        activity_level=profile.activity_level,
        goal=profile.goal,
        onboarding_completed=profile.onboarding_completed,
        bmr=targets.bmr,
        tdee=targets.tdee,
        created_at=profile.created_at,
        updated_at=profile.updated_at,
    )

    return UserProfileResponse(
        profile=profile_read,
        goal=GoalRead.model_validate(goal),
        bmr=targets.bmr,
        tdee=targets.tdee,
    )


@router.get("/{user_id}", response_model=UserRead)
async def get_user(user_id: uuid.UUID, db: AsyncSession = Depends(get_db)) -> UserRead:
    result = await db.execute(select(User).where(User.id == user_id))
    user = result.scalar_one_or_none()
    if user is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found.")
    return UserRead.model_validate(user)
