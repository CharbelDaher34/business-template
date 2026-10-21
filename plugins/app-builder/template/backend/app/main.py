import logging

from fastapi import FastAPI, Request
from fastapi.exception_handlers import request_validation_exception_handler
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse
from fastapi.routing import APIRoute

from app.api.main import api_router
from app.core.config import settings
from app.services.errors import DomainError

# The app's own log lines (every logger named "app.*") go to the backend's output,
# next to uvicorn's one line per request: `docker compose logs backend`.
# Other libraries keep their defaults (warnings and errors only), to stay readable.
_app_logger = logging.getLogger("app")
_app_logger.setLevel(logging.INFO)
_handler = logging.StreamHandler()
_handler.setFormatter(
    logging.Formatter("%(asctime)s %(levelname)s %(name)s: %(message)s")
)
_app_logger.addHandler(_handler)
logger = logging.getLogger(__name__)


def custom_generate_unique_id(route: APIRoute) -> str:
    return f"{route.tags[0]}-{route.name}"


# Everything lives under /api so the frontend dev server can forward it here:
# the API at /api/v1, the interactive API docs at /api/docs.
app = FastAPI(
    title=settings.APP_NAME,
    openapi_url=f"{settings.API_V1_STR}/openapi.json",
    docs_url="/api/docs",
    redoc_url=None,
    generate_unique_id_function=custom_generate_unique_id,
)


@app.exception_handler(DomainError)
async def domain_error_handler(request: Request, exc: DomainError) -> JSONResponse:
    # Services raise DomainError subclasses; each one carries its HTTP status code.
    # Logged, because the request log line only shows the status code, not why.
    logger.info(
        "%s %s refused for %s (%s): %s",
        request.method,
        request.url.path,
        getattr(request.state, "username", "anonymous"),
        exc.status_code,
        exc.message,
    )
    return JSONResponse(status_code=exc.status_code, content={"detail": exc.message})


@app.exception_handler(RequestValidationError)
async def validation_error_handler(
    request: Request, exc: RequestValidationError
) -> JSONResponse:
    # Which fields were invalid and why, never the submitted values (they can
    # contain passwords).
    problems = "; ".join(
        f"{'.'.join(str(part) for part in error['loc'])}: {error['msg']}"
        for error in exc.errors()
    )
    logger.info("%s %s invalid input: %s", request.method, request.url.path, problems)
    return await request_validation_exception_handler(request, exc)


app.include_router(api_router, prefix=settings.API_V1_STR)
