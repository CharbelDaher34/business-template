from sqlmodel import create_engine

from app.core.config import settings

# Tables are created and changed by Alembic migrations (app/alembic), never by
# SQLModel.metadata.create_all(). Every model module is imported in
# app/models/__init__.py so relationships resolve and Alembic sees every table.
engine = create_engine(settings.SQLALCHEMY_DATABASE_URI, pool_pre_ping=True)
