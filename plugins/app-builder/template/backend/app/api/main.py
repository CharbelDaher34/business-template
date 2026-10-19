from fastapi import APIRouter

from app.api.routes import items, login, users, utils

# Every router is mounted under /api/v1 in app/main.py.
# When you add a new routes module, include it here.
api_router = APIRouter()
api_router.include_router(login.router)
api_router.include_router(users.router)
api_router.include_router(utils.router)
api_router.include_router(items.router)
