from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    MONGO_URI: str = "mongodb://localhost:27017"
    DB_NAME: str = "sportsetu"
    JWT_SECRET: str = "your-super-secret-key-change-in-production"
    JWT_ALGORITHM: str = "HS256"
    JWT_EXPIRE_MINUTES: int = 60 * 24 * 7   # 7 days
    ADMIN_SECRET_CODE: str = "SAG_ADMIN_2024"  # code used at registration

    class Config:
        env_file = ".env"

settings = Settings()
