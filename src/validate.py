"""Data quality and reconciliation reporting."""

from __future__ import annotations

import sqlite3
from pathlib import Path

import pandas as pd

from src.config import DASHBOARD_EXPORT_DIR, DB_PATH, REPORTS_DIR


VALIDATION_VIEWS = [
    "vw_val_po_missing_movement",
    "vw_val_truck_before_po_approval",
    "vw_val_actual_pickup_before_scheduled",
    "vw_val_removal_closed_missing_date",
    "vw_val_material_fulfilled_zero_qty",
    "vw_val_invalid_inventory_refs",
    "vw_val_duplicate_po_ids",
    "vw_val_duplicate_movement_ids",
    "vw_val_overdue_removals",
]


def _markdown_table(df: pd.DataFrame, max_rows: int = 20) -> str:
    if df.empty:
        return "_No rows._"
    sample = df.head(max_rows).copy()
    sample = sample.fillna("")
    headers = [str(col) for col in sample.columns]
    lines = [
        "| " + " | ".join(headers) + " |",
        "| " + " | ".join(["---"] * len(headers)) + " |",
    ]
    for _, row in sample.iterrows():
        values = [str(row[col]).replace("|", "/") for col in sample.columns]
        lines.append("| " + " | ".join(values) + " |")
    return "\n".join(lines)


def _read_view(conn: sqlite3.Connection, view_name: str) -> pd.DataFrame:
    return pd.read_sql_query(f"SELECT * FROM {view_name}", conn)


def run_validation_report() -> dict[str, int]:
    """Run validation views, persist issues, and write a readable markdown report."""

    REPORTS_DIR.mkdir(parents=True, exist_ok=True)
    DASHBOARD_EXPORT_DIR.mkdir(parents=True, exist_ok=True)

    all_issues: list[pd.DataFrame] = []
    summary_records: list[dict[str, object]] = []

    with sqlite3.connect(DB_PATH) as conn:
        for view_name in VALIDATION_VIEWS:
            df = _read_view(conn, view_name)
            check_name = view_name.replace("vw_val_", "")
            summary_records.append({"check_name": check_name, "issue_count": len(df)})
            if not df.empty:
                all_issues.append(df)

        combined = (
            pd.concat(all_issues, ignore_index=True)
            if all_issues
            else pd.DataFrame(columns=["issue_key", "related_entity_type", "related_entity_id", "issue_detail", "severity"])
        )
        conn.execute("DELETE FROM data_quality_issues")
        if not combined.empty:
            combined.to_sql("data_quality_issues", conn, if_exists="append", index=False)
        conn.commit()

        row_counts = _read_view(conn, "vw_reconciliation_row_counts")
        quantity_totals = _read_view(conn, "vw_reconciliation_quantity_totals")
        financials = _read_view(conn, "vw_reconciliation_financials")
        as_of = conn.execute("SELECT value FROM run_metadata WHERE key = 'as_of_date'").fetchone()[0]

    combined.to_csv(DASHBOARD_EXPORT_DIR / "data_quality_issues.csv", index=False)
    summary = pd.DataFrame(summary_records)
    summary.to_csv(REPORTS_DIR / "validation_summary.csv", index=False)

    report_lines = [
        "# Data Quality and Reconciliation Report",
        "",
        f"Reporting date: `{as_of}`",
        "",
        "This report is intentionally non-empty. The raw synthetic files include realistic defects so the analyst workflow can demonstrate issue detection, reconciliation, and clean-table loading.",
        "",
        "## Validation Summary",
        "",
        _markdown_table(summary),
        "",
        "## Reconciliation Row Counts",
        "",
        _markdown_table(row_counts),
        "",
        "## Reconciliation Quantity Totals",
        "",
        _markdown_table(quantity_totals),
        "",
        "## Reconciliation Financials",
        "",
        _markdown_table(financials),
        "",
        "## Sample Data Quality Issues",
        "",
        _markdown_table(combined, max_rows=25),
        "",
    ]
    (REPORTS_DIR / "validation_report.md").write_text("\n".join(report_lines), encoding="utf-8")

    return {"checks": len(VALIDATION_VIEWS), "issues": int(len(combined))}

