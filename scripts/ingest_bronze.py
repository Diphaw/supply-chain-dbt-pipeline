import logging
import os
import time
from datetime import datetime, timezone
from pathlib import Path
from dotenv import load_dotenv
import pandas as pd
from sqlalchemy import create_engine, text

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    handlers=[logging.StreamHandler()]
)

load_dotenv()

DB_USER = os.getenv("DB_USER")
DB_PASSWORD = os.getenv("DB_PASSWORD")
DB_HOST = os.getenv("DB_HOST", "localhost")
DB_PORT = os.getenv("DB_PORT", "5432")
DB_NAME = os.getenv("DB_NAME")

# DATABASE_URL = f"postgresql://{DB_USER}:{DB_PASSWORD}@{DB_HOST}:{DB_PORT}/{DB_NAME}"
DATABASE_URL = f"postgresql+psycopg2://{DB_USER}:{DB_PASSWORD}@{DB_HOST}:{DB_PORT}/{DB_NAME}"

CSV_PATH = Path("raw_data/DataCoSupplyChainDataset.csv")
TARGET_SCHEMA = "bronze"
TARGET_TABLE = "raw_supply_chain"


def sanitize_column_names(columns: pd.Index) -> list[str]:
    """Convert column headers to SQL-friendly snake_case."""
    return (
        columns.str.strip()
        .str.lower()
        .str.replace(r"[^\w\s]", "", regex=True)
        .str.replace(r"\s+", "_", regex=True)
        .tolist()
    )


def ingest_bronze():
    start_time = time.time()

    if not CSV_PATH.exists():
        logging.error(f"Source file not found at: {CSV_PATH}")
        raise FileNotFoundError(f"Missing source file: {CSV_PATH}")

    logging.info(f"Loading raw file: {CSV_PATH}")
    df = pd.read_csv(CSV_PATH, encoding="latin1")
    logging.info(f"Loaded {len(df):,} records with {len(df.columns)} columns.")

    # Sanitize schema headers
    df.columns = sanitize_column_names(df.columns)

    # Ingestion metadata
    df["_ingested_at"] = datetime.now(timezone.utc)

    engine = create_engine(DATABASE_URL)

    try:
        with engine.begin() as conn:
            conn.execute(text(f"CREATE SCHEMA IF NOT EXISTS {TARGET_SCHEMA};"))
            logging.info(f"Target schema '{TARGET_SCHEMA}' ready.")

        logging.info(f"Ingesting into {TARGET_SCHEMA}.{TARGET_TABLE}...")
        df.to_sql(
            name=TARGET_TABLE,
            con=engine,
            schema=TARGET_SCHEMA,
            if_exists="replace",
            index=False,
            chunksize=5000,
            method="multi"
        )

        duration = round(time.time() - start_time, 2)
        logging.info(f"Ingestion completed in {duration} seconds.")

    except Exception as exc:
        logging.error(f"Ingestion pipeline failed: {exc}", exc_info=True)
        raise exc
    finally:
        engine.dispose()
        logging.info("Database connection closed.")


if __name__ == "__main__":
    ingest_bronze()