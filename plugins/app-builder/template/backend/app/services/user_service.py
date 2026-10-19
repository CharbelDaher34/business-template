import uuid

from sqlmodel import Session, col, func, select

from app.core.security import get_password_hash, verify_password
from app.models import User, UserCreate, UserRegister, UserUpdate, UserUpdateMe
from app.services.errors import (
    ConflictError,
    DomainError,
    NotFoundError,
    PermissionDeniedError,
)

# Dummy hash to use for timing attack prevention when user is not found
# This is an Argon2 hash of a random password, used to ensure constant-time comparison
DUMMY_HASH = "$argon2id$v=19$m=65536,t=3,p=4$MjQyZWE1MzBjYjJlZTI0Yw$YTU4NGM5ZTZmYjE2NzZlZjY0ZWY3ZGRkY2U2OWFjNjk"


def normalize_username(username: str) -> str:
    # Usernames are stored lowercase so "Maya" and "maya" are the same login.
    return username.strip().lower()


def get_user_by_email(*, session: Session, email: str) -> User | None:
    return session.exec(select(User).where(User.email == email)).first()


def get_user_by_username(*, session: Session, username: str) -> User | None:
    statement = select(User).where(User.username == normalize_username(username))
    return session.exec(statement).first()


def get_user_by_login(*, session: Session, login: str) -> User | None:
    """Find a user by email or username (usernames can't contain "@")."""
    if "@" in login:
        return get_user_by_email(session=session, email=login)
    return get_user_by_username(session=session, username=login)


def get_user(*, session: Session, user_id: uuid.UUID) -> User:
    user = session.get(User, user_id)
    if not user:
        raise NotFoundError("User not found")
    return user


def list_users(
    *, session: Session, skip: int = 0, limit: int = 100
) -> tuple[list[User], int]:
    count = session.exec(select(func.count()).select_from(User)).one()
    statement = (
        select(User).order_by(col(User.created_at).desc()).offset(skip).limit(limit)
    )
    return list(session.exec(statement).all()), count


def _ensure_unique(
    *,
    session: Session,
    email: str | None,
    username: str | None,
    exclude_id: uuid.UUID | None = None,
) -> None:
    if email:
        existing = get_user_by_email(session=session, email=email)
        if existing and existing.id != exclude_id:
            raise ConflictError("A user with this email already exists")
    if username:
        existing = get_user_by_username(session=session, username=username)
        if existing and existing.id != exclude_id:
            raise ConflictError("A user with this username already exists")


def create_user(*, session: Session, user_create: UserCreate) -> User:
    _ensure_unique(
        session=session, email=user_create.email, username=user_create.username
    )
    db_obj = User.model_validate(
        user_create,
        update={
            "username": normalize_username(user_create.username),
            "hashed_password": get_password_hash(user_create.password),
        },
    )
    session.add(db_obj)
    session.commit()
    session.refresh(db_obj)
    return db_obj


def register_user(*, session: Session, user_in: UserRegister) -> User:
    """Self sign-up: always creates a normal (non-admin) user."""
    return create_user(session=session, user_create=UserCreate.model_validate(user_in))


def update_user(
    *, session: Session, db_user: User, user_in: UserUpdate | UserUpdateMe
) -> User:
    _ensure_unique(
        session=session,
        email=user_in.email,
        username=user_in.username,
        exclude_id=db_user.id,
    )
    user_data = user_in.model_dump(exclude_unset=True)
    extra_data = {}
    if user_data.get("username"):
        user_data["username"] = normalize_username(user_data["username"])
    if "password" in user_data:
        password = user_data.pop("password")
        if password:
            extra_data["hashed_password"] = get_password_hash(password)
    db_user.sqlmodel_update(user_data, update=extra_data)
    session.add(db_user)
    session.commit()
    session.refresh(db_user)
    return db_user


def change_password(
    *, session: Session, user: User, current_password: str, new_password: str
) -> None:
    verified, _ = verify_password(current_password, user.hashed_password)
    if not verified:
        raise DomainError("Incorrect password")
    if current_password == new_password:
        raise DomainError("New password cannot be the same as the current one")
    user.hashed_password = get_password_hash(new_password)
    session.add(user)
    session.commit()


def delete_own_account(*, session: Session, user: User) -> None:
    if user.is_superuser:
        raise PermissionDeniedError("Admins are not allowed to delete themselves")
    session.delete(user)
    session.commit()


def delete_user(*, session: Session, user_id: uuid.UUID, acting_user: User) -> None:
    user = get_user(session=session, user_id=user_id)
    if user.id == acting_user.id:
        raise PermissionDeniedError("Admins are not allowed to delete themselves")
    # The user's items are deleted too (cascade on the relationship).
    session.delete(user)
    session.commit()


def authenticate(*, session: Session, login: str, password: str) -> User | None:
    """Return the user if the email/username and password match, else None."""
    db_user = get_user_by_login(session=session, login=login)
    if not db_user:
        # Prevent timing attacks by running password verification even when user doesn't exist
        # This ensures the response time is similar whether or not the user exists
        verify_password(password, DUMMY_HASH)
        return None
    verified, updated_password_hash = verify_password(password, db_user.hashed_password)
    if not verified:
        return None
    if updated_password_hash:
        db_user.hashed_password = updated_password_hash
        session.add(db_user)
        session.commit()
        session.refresh(db_user)
    return db_user
