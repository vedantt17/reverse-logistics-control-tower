"""SQLite database creation and raw-to-clean loading."""

from __future__ import annotations

import sqlite3
from pathlib import Path

import pandas as pd

from src.config import DB_PATH, RAW_DIR, RAW_TABLES, SQL_DIR


SQL_FILES = [
    "01_create_tables.sql",
    "02_load_clean_tables.sql",
    "03_kpi_views.sql",
    "04_validation_queries.sql",
    "05_reconciliation_queries.sql",
]


def execute_sql_file(conn: sqlite3.Connection, path: Path) -> None:
    sql = path.read_text(encoding="utf-8")
    conn.executescript(sql)
    conn.commit()


def load_raw_tables(conn: sqlite3.Connection) -> None:
    for filename, table_name in RAW_TABLES.items():
        csv_path = RAW_DIR / filename
        if not csv_path.exists():
            raise FileNotFoundError(f"Expected raw file not found: {csv_path}")
        df = pd.read_csv(csv_path)
        df.to_sql(table_name, conn, if_exists="append", index=False)
    conn.commit()


def build_database(as_of_date: str) -> Path:
    """Create a fresh SQLite database, stage CSVs, and build clean tables/views."""

    DB_PATH.parent.mkdir(parents=True, exist_ok=True)
    if DB_PATH.exists():
        DB_PATH.unlink()

    with sqlite3.connect(DB_PATH) as conn:
        conn.execute("PRAGMA foreign_keys = ON;")
        execute_sql_file(conn, SQL_DIR / "01_create_tables.sql")
        conn.execute(
            "INSERT INTO run_metadata (key, value) VALUES (?, ?)",
            ("as_of_date", as_of_date),
        )
        conn.commit()

        load_raw_tables(conn)
        for sql_file in SQL_FILES[1:]:
            execute_sql_file(conn, SQL_DIR / sql_file)

    return DB_PATH

