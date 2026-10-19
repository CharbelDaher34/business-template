import uuid

from sqlmodel import Session, col, func, select

from app.models import Item, ItemCreate, ItemUpdate, User
from app.services.errors import NotFoundError, PermissionDeniedError


def list_items(
    *, session: Session, user: User, skip: int = 0, limit: int = 100
) -> tuple[list[Item], int]:
    """Admins see every item; everyone else sees only their own."""
    count_statement = select(func.count()).select_from(Item)
    statement = select(Item)
    if not user.is_superuser:
        count_statement = count_statement.where(Item.owner_id == user.id)
        statement = statement.where(Item.owner_id == user.id)
    count = session.exec(count_statement).one()
    statement = (
        statement.order_by(col(Item.created_at).desc()).offset(skip).limit(limit)
    )
    return list(session.exec(statement).all()), count


def get_item(*, session: Session, user: User, item_id: uuid.UUID) -> Item:
    item = session.get(Item, item_id)
    if not item:
        raise NotFoundError("Item not found")
    if not user.is_superuser and item.owner_id != user.id:
        raise PermissionDeniedError("Not enough permissions")
    return item


def create_item(*, session: Session, user: User, item_in: ItemCreate) -> Item:
    item = Item.model_validate(item_in, update={"owner_id": user.id})
    session.add(item)
    session.commit()
    session.refresh(item)
    return item


def update_item(
    *, session: Session, user: User, item_id: uuid.UUID, item_in: ItemUpdate
) -> Item:
    item = get_item(session=session, user=user, item_id=item_id)
    item.sqlmodel_update(item_in.model_dump(exclude_unset=True))
    session.add(item)
    session.commit()
    session.refresh(item)
    return item


def delete_item(*, session: Session, user: User, item_id: uuid.UUID) -> None:
    item = get_item(session=session, user=user, item_id=item_id)
    session.delete(item)
    session.commit()
