"""Seed existing user accounts into database idempotently."""

import asyncio
import logging

from sqlalchemy import select

from app.core.database import AsyncSessionLocal
from app.models.goal import Goal
from app.models.user import User

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

USERS_TO_SEED = [
    {
        "name": "rohit",
        "email": "rohitdoshilevel@gmail.com",
        "hashed_password": "$2b$12$cmHUbeXIce3awoRhcAPgv.qd3xa9FSPmNEQD0JH8aw.DtLaeYOi.K",
        "auth_provider": "email",
    },
    {
        "name": "rohit",
        "email": "rohit.doshi2007@gmail.com",
        "hashed_password": "$2b$12$oeh7oWgEbjvZ9yung02bk.r/mQoJxPA7a8f/0pNeELW4sIvd2LS7S",
        "auth_provider": "email",
    },
]


async def seed_users() -> None:
    async with AsyncSessionLocal() as db:
        for u_data in USERS_TO_SEED:
            res = await db.execute(select(User).where(User.email == u_data["email"]))
            existing = res.scalar_one_or_none()
            if existing is None:
                user = User(
                    name=u_data["name"],
                    email=u_data["email"],
                    hashed_password=u_data["hashed_password"],
                    auth_provider=u_data["auth_provider"],
                )
                db.add(user)
                await db.commit()
                await db.refresh(user)

                goal = Goal(
                    user_id=user.id,
                    calorie_target=2000.0,
                    protein_target=120.0,
                    carbohydrates_target=250.0,
                    fat_target=65.0,
                    fiber_target=30.0,
                )
                db.add(goal)
                await db.commit()
                logger.info("Seeded user: %s", u_data["email"])
            else:
                logger.info("User already exists: %s", u_data["email"])


if __name__ == "__main__":
    asyncio.run(seed_users())
