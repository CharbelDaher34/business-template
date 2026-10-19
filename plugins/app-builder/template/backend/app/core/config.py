from typing import Self

from pydantic import EmailStr, computed_field, model_validator
from pydantic_settings import BaseSettings, SettingsConfigDict
from sqlalchemy.engine import URL


class Settings(BaseSettings):
    # Values come from the environment. Docker Compose passes the project's .env in.
    model_config = SettingsConfigDict(env_ignore_empty=True, extra="ignore")

    APP_NAME: str = "My App"
    API_V1_STR: str = "/api/v1"
    SECRET_KEY: str
    # 60 minutes * 24 hours * 8 days = 8 days
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24 * 8

    POSTGRES_HOST: str = "db"
    POSTGRES_PORT: int = 5432
    POSTGRES_USER: str
    POSTGRES_PASSWORD: str
    POSTGRES_DB: str

    @computed_field  # type: ignore[prop-decorator]
    @property
    def SQLALCHEMY_DATABASE_URI(self) -> URL:
        return URL.create(
            drivername="postgresql+psycopg",
            username=self.POSTGRES_USER,
            password=self.POSTGRES_PASSWORD,
            host=self.POSTGRES_HOST,
            port=self.POSTGRES_PORT,
            database=self.POSTGRES_DB,
        )

    FIRST_ADMIN_EMAIL: EmailStr
    FIRST_ADMIN_USERNAME: str
    FIRST_ADMIN_PASSWORD: str

    def _check_default_secret(self, var_name: str, value: str) -> None:
        if value == "changethis":
            raise ValueError(
                f'{var_name} in .env is still "changethis". '
                "Set a real value (for example: openssl rand -hex 32)."
            )

    @model_validator(mode="after")
    def _enforce_non_default_secrets(self) -> Self:
        self._check_default_secret("SECRET_KEY", self.SECRET_KEY)
        self._check_default_secret("POSTGRES_PASSWORD", self.POSTGRES_PASSWORD)
        self._check_default_secret("FIRST_ADMIN_PASSWORD", self.FIRST_ADMIN_PASSWORD)
        return self


settings = Settings()  # type: ignore[call-arg]
