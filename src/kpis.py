"""KPI table exports for BI tools and Excel refresh workflows."""

from __future__ import annotations

import sqlite3

import pandas as pd

from src.config import DASHBOARD_EXPORT_DIR, DB_PATH, PROCESSED_DIR, REPORTS_DIR


DASHBOARD_VIEWS = {
    "kpi_summary.csv": "vw_kpi_summary",
    "backlog_by_region_site.csv": "vw_backlog_by_region_site",
    "po_status_by_partner.csv": "vw_po_status_by_partner",
    "truck_delay_trend.csv": "vw_truck_delay_trend",
    "removal_aging_distribution.csv": "vw_removal_aging_distribution",
    "site_exception_table.csv": "vw_site_exception_table",
    "high_priority_material_requests.csv": "vw_high_priority_material_requests",
    "at_risk_inventory_by_sku.csv": "vw_at_risk_inventory_by_sku",
    "partner_sla_performance.csv": "vw_partner_sla_performance",
    "exception_count_by_severity.csv": "vw_exception_count_by_severity",
    "po_tracker.csv": "vw_po_tracker",
    "overdue_removals.csv": "vw_overdue_removals",
    "delayed_pos.csv": "vw_delayed_pos",
}


CLEAN_TABLES = [
    "sites",
    "partners",
    "products",
    "inventory_movements",
    "purchase_orders",
    "truck_schedules",
    "scrap_removal_requests",
    "material_requests",
    "exceptions",
]


def _markdown_table(df: pd.DataFrame, max_rows: int = 20) -> str:
    if df.empty:
        return "_No rows._"
    sample = df.head(max_rows).fillna("")
    headers = [str(col) for col in sample.columns]
    lines = [
        "| " + " | ".join(headers) + " |",
        "| " + " | ".join(["---"] * len(headers)) + " |",
    ]
    for _, row in sample.iterrows():
        lines.append("| " + " | ".join(str(row[col]).replace("|", "/") for col in sample.columns) + " |")
    return "\n".join(lines)


def export_dashboard_tables() -> dict[str, int]:
    DASHBOARD_EXPORT_DIR.mkdir(parents=True, exist_ok=True)
    PROCESSED_DIR.mkdir(parents=True, exist_ok=True)
    REPORTS_DIR.mkdir(parents=True, exist_ok=True)
    summary: dict[str, int] = {}

    with sqlite3.connect(DB_PATH) as conn:
        for filename, view_name in DASHBOARD_VIEWS.items():
            df = pd.read_sql_query(f"SELECT * FROM {view_name}", conn)
            df.to_csv(DASHBOARD_EXPORT_DIR / filename, index=False)
            summary[filename] = len(df)

        for table_name in CLEAN_TABLES:
            df = pd.read_sql_query(f"SELECT * FROM {table_name}", conn)
            df.to_csv(PROCESSED_DIR / f"{table_name}.csv", index=False)

        kpi = pd.read_sql_query("SELECT * FROM vw_kpi_summary", conn)
        top_backlog = pd.read_sql_query("SELECT * FROM vw_backlog_by_region_site LIMIT 10", conn)
        top_risk = pd.read_sql_query("SELECT * FROM vw_at_risk_inventory_by_sku LIMIT 10", conn)
        delayed_pos = pd.read_sql_query("SELECT * FROM vw_delayed_pos LIMIT 10", conn)

    snapshot = [
        "# KPI Snapshot",
        "",
        "## Executive KPIs",
        "",
        _markdown_table(kpi),
        "",
        "## Top Backlog Sites",
        "",
        _markdown_table(top_backlog),
        "",
        "## Highest At-Risk SKUs",
        "",
        _markdown_table(top_risk),
        "",
        "## Sample Delayed PO Tracker",
        "",
        _markdown_table(delayed_pos),
        "",
    ]
    (REPORTS_DIR / "kpi_snapshot.md").write_text("\n".join(snapshot), encoding="utf-8")

    return summary

