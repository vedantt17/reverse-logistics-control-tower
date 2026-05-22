"""Run the end-to-end reverse logistics analytics pipeline."""

from __future__ import annotations

import argparse

from src.config import DEFAULT_AS_OF_DATE, DEFAULT_SEED, ensure_directories
from src.database import build_database
from src.excel_workbook import build_excel_workbook
from src.generate_data import generate_raw_data
from src.kpis import export_dashboard_tables
from src.validate import run_validation_report


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Generate synthetic reverse logistics data, load SQLite, validate, and export KPI tables."
    )
    parser.add_argument("--seed", type=int, default=DEFAULT_SEED, help="Random seed for reproducible data.")
    parser.add_argument(
        "--as-of-date",
        default=DEFAULT_AS_OF_DATE,
        help="Reporting date used for aging and SLA calculations, in YYYY-MM-DD format.",
    )
    parser.add_argument(
        "--skip-generation",
        action="store_true",
        help="Load existing CSVs from data/raw instead of regenerating synthetic data.",
    )
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    ensure_directories()

    if not args.skip_generation:
        counts = generate_raw_data(seed=args.seed, as_of_date=args.as_of_date)
        print("Generated raw CSVs:")
        for name, count in counts.items():
            print(f"  {name}: {count:,} rows")
    else:
        print("Skipped data generation. Loading existing CSVs from data/raw.")

    db_path = build_database(as_of_date=args.as_of_date)
    print(f"SQLite database created: {db_path}")

    validation_summary = run_validation_report()
    print("Validation report created:")
    print(f"  checks: {validation_summary['checks']}")
    print(f"  issues: {validation_summary['issues']:,}")

    export_summary = export_dashboard_tables()
    print("Dashboard-ready tables exported:")
    for name, count in export_summary.items():
        print(f"  {name}: {count:,} rows")

    workbook_path = build_excel_workbook()
    print(f"Excel operations workbook refreshed: {workbook_path}")

    print("Pipeline complete.")


if __name__ == "__main__":
    main()
