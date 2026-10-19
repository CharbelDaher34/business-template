class DomainError(Exception):
    """A business rule was broken. Services raise these, never HTTPException.

    app/main.py turns every DomainError into an HTTP response with the class's
    status_code and {"detail": message}, so routes don't need try/except.
    """

    status_code = 400

    def __init__(self, message: str) -> None:
        super().__init__(message)
        self.message = message


class NotFoundError(DomainError):
    status_code = 404


class PermissionDeniedError(DomainError):
    status_code = 403


class ConflictError(DomainError):
    status_code = 409
