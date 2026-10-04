from typing import Optional
from motor.motor_asyncio import AsyncIOMotorClient, AsyncIOMotorDatabase
from app.core.config import settings
from app.core.logging import logger
from app.database.collections import USERS_COLLECTION


class MongoDB:
    client: Optional[AsyncIOMotorClient] = None
    db: Optional[AsyncIOMotorDatabase] = None


db_instance = MongoDB()


async def connect_to_mongo() -> None:
    """Initialize MongoDB connection pool on app startup using MONGO_URI and create unique indexes."""
    mongo_uri = settings.get_mongo_uri()
    logger.info("Connecting to MongoDB...")
    db_instance.client = AsyncIOMotorClient(
        mongo_uri,
        serverSelectionTimeoutMS=5000
    )
    db_instance.db = db_instance.client[settings.MONGODB_DB_NAME]
    try:
        # Ping the server to verify connectivity
        await db_instance.client.admin.command('ping')
        logger.info("MongoDB connection successful")

        # Create unique index for users email
        await db_instance.db[USERS_COLLECTION].create_index("email", unique=True)
        logger.info(f"MongoDB unique index ensured on '{USERS_COLLECTION}.email'")
    except Exception as e:
        logger.error(f"Failed to initialize MongoDB connection or indexes: {e}")
        raise


async def close_mongo_connection() -> None:
    """Close MongoDB connection pool on app shutdown."""
    if db_instance.client is not None:
        logger.info("Closing MongoDB connection pool...")
        db_instance.client.close()
        logger.info("MongoDB connection closed.")


def get_database() -> AsyncIOMotorDatabase:
    """Get the active Motor database instance."""
    if db_instance.db is None:
        raise RuntimeError("Database connection is not initialized.")
    return db_instance.db


async def ping_database() -> bool:
    """Ping MongoDB server to check if it's responsive."""
    if db_instance.client is None:
        return False
    try:
        await db_instance.client.admin.command('ping')
        return True
    except Exception as e:
        logger.warning(f"MongoDB ping failed: {e}")
        return False
