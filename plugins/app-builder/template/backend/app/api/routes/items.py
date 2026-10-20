# Reference feature: copy this file's shape for new features.
# Routes stay thin: parse input, call a service, return a schema.
# Business rules and database queries live in app/services/item_service.py.
import uuid
from typing import Any

from fastapi import APIRouter

from app.api.deps import CurrentUser, SessionDep
from app.models import ItemCreate, ItemPublic, ItemsPublic, ItemUpdate, Message
from app.services import item_service

router = APIRouter(prefix="/items", tags=["items"])


@router.get("/", response_model=ItemsPublic)
def read_items(session: SessionDep, current_user: CurrentUser) -> Any:
    """
    Retrieve items.
    """
    items = item_service.list_items(session=session, user=current_user)
    return ItemsPublic(
        data=[ItemPublic.model_validate(item) for item in items], count=len(items)
    )


@router.get("/{id}", response_model=ItemPublic)
def read_item(session: SessionDep, current_user: CurrentUser, id: uuid.UUID) -> Any:
    """
    Get item by ID.
    """
    return item_service.get_item(session=session, user=current_user, item_id=id)


@router.post("/", response_model=ItemPublic)
def create_item(
    *, session: SessionDep, current_user: CurrentUser, item_in: ItemCreate
) -> Any:
    """
    Create new item.
    """
    return item_service.create_item(session=session, user=current_user, item_in=item_in)


@router.put("/{id}", response_model=ItemPublic)
def update_item(
    *,
    session: SessionDep,
    current_user: CurrentUser,
    id: uuid.UUID,
    item_in: ItemUpdate,
) -> Any:
    """
    Update an item.
    """
    return item_service.update_item(
        session=session, user=current_user, item_id=id, item_in=item_in
    )


@router.delete("/{id}")
def delete_item(
    session: SessionDep, current_user: CurrentUser, id: uuid.UUID
) -> Message:
    """
    Delete an item.
    """
    item_service.delete_item(session=session, user=current_user, item_id=id)
    return Message(message="Item deleted successfully")
