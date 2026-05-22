"""Project paths and shared configuration."""

from __future__ import annotations

from pathlib import Path


PROJECT_ROOT = Path(__file__).resolve().parents[1]
DATA_DIR = PROJECT_ROOT / "data"
RAW_DIR = DATA_DIR / "raw"
PROCESSED_DIR = DATA_DIR / "processed"
DB_DIR = PROJECT_ROOT / "db"
SQL_DIR = PROJECT_ROOT / "sql"
REPORTS_DIR = PROJECT_ROOT / "reports"
OUTPUTS_DIR = PROJECT_ROOT / "outputs"
DASHBOARD_EXPORT_DIR = OUTPUTS_DIR / "dashboard_exports"
EXCEL_OUTPUT_DIR = OUTPUTS_DIR / "excel"

DB_PATH = DB_DIR / "reverse_logistics_control_tower.sqlite"

DEFAULT_AS_OF_DATE = "2026-05-22"
DEFAULT_SEED = 423


RAW_TABLES = {
    "sites.csv": "stg_sites",
    "partners.csv": "stg_partners",
    "products.csv": "stg_products",
    "inventory_movements.csv": "stg_inventory_movements",
    "purchase_orders.csv": "stg_purchase_orders",
    "truck_schedules.csv": "stg_truck_schedules",
    "scrap_removal_requests.csv": "stg_scrap_removal_requests",
    "material_requests.csv": "stg_material_requests",
    "exceptions.csv": "stg_exceptions",
}


def ensure_directories() -> None:
    """Create runtime folders used by the pipeline."""

    for path in [
        RAW_DIR,
        PROCESSED_DIR,
        DB_DIR,
        REPORTS_DIR,
        DASHBOARD_EXPORT_DIR,
        EXCEL_OUTPUT_DIR,
    ]:
        path.mkdir(parents=True, exist_ok=True)

