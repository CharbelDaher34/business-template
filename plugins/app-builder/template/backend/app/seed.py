"""Seed data: rows the app needs, inserted on every start.

Runs during prestart, right after `alembic upgrade head` (see scripts/prestart.sh).
Every function here must be idempotent: it only inserts rows that are missing,
so running it again never duplicates or overwrites anything.

Run by hand with: docker compose exec backend python -m app.seed
"""

import logging

from sqlmodel import Session, select

from app.core.config import settings
from app.core.db import engine
from app.models import Item, User, UserCreate
from app.services import user_service

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


def seed_first_admin(session: Session) -> User:
    """The first admin account, from FIRST_ADMIN_* in .env."""
    user = user_service.get_user_by_email(
        session=session, email=settings.FIRST_ADMIN_EMAIL
    ) or user_service.get_user_by_username(
        session=session, username=settings.FIRST_ADMIN_USERNAME
    )
    if user:
        return user
    logger.info("Creating the first admin: %s", settings.FIRST_ADMIN_EMAIL)
    return user_service.create_user(
        session=session,
        user_create=UserCreate(
            email=settings.FIRST_ADMIN_EMAIL,
            username=settings.FIRST_ADMIN_USERNAME,
            password=settings.FIRST_ADMIN_PASSWORD,
            is_superuser=True,
        ),
    )


DEMO_ITEMS = [
    ("Welcome item", "An example row, so the Items page isn't empty."),
    ("Second item", "Edit or delete me to try the example feature."),
    ("Third item", None),
]


def seed_demo_items(session: Session, owner: User) -> None:
    """Demo rows for the example "items" feature. Remove with that feature."""
    for title, description in DEMO_ITEMS:
        exists = session.exec(
            select(Item).where(Item.owner_id == owner.id, Item.title == title)
        ).first()
        if not exists:
            session.add(Item(title=title, description=description, owner_id=owner.id))
    session.commit()


# ---------------------------------------------------------------------------
# Add this app's own seed functions above this line (one per kind of data,
# each only inserting what's missing), then call them from run_all() below.
# ---------------------------------------------------------------------------


def run_all(session: Session) -> None:
    admin = seed_first_admin(session)
    seed_demo_items(session, owner=admin)


def main() -> None:
    with Session(engine) as session:
        run_all(session)
    logger.info("Seed data is up to date")


if __name__ == "__main__":
    main()
