# Import every model module here. This registers all tables on SQLModel.metadata,
# which Alembic autogenerate (app/alembic/env.py) and relationships rely on.
# When you add a new model file, add its import below.
from sqlmodel import SQLModel

from app.models.common import Message, Token, TokenPayload
from app.models.item import Item, ItemCreate, ItemPublic, ItemsPublic, ItemUpdate
from app.models.user import (
    UpdatePassword,
    User,
    UserCreate,
    UserPublic,
    UserRegister,
    UsersPublic,
    UserUpdate,
    UserUpdateMe,
)

__all__ = [
    "Item",
    "ItemCreate",
    "ItemPublic",
    "ItemUpdate",
    "ItemsPublic",
    "Message",
    "SQLModel",
    "Token",
    "TokenPayload",
    "UpdatePassword",
    "User",
    "UserCreate",
    "UserPublic",
    "UserRegister",
    "UserUpdate",
    "UserUpdateMe",
    "UsersPublic",
]
