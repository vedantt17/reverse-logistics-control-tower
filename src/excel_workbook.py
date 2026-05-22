"""Build the Excel operations workbook from dashboard CSV exports."""

from __future__ import annotations

from pathlib import Path

import pandas as pd

from src.config import DASHBOARD_EXPORT_DIR, EXCEL_OUTPUT_DIR


WORKBOOK_PATH = EXCEL_OUTPUT_DIR / "Reverse_Logistics_Control_Tower.xlsx"

WORKSHEETS = [
    ("Dashboard", "kpi_summary.csv"),
    ("Backlog", "backlog_by_region_site.csv"),
    ("PO Tracker", "po_tracker.csv"),
    ("PO Status", "po_status_by_partner.csv"),
    ("Truck Trend", "truck_delay_trend.csv"),
    ("Removal Aging", "removal_aging_distribution.csv"),
    ("Exceptions", "site_exception_table.csv"),
    ("Requests", "high_priority_material_requests.csv"),
    ("At Risk SKU", "at_risk_inventory_by_sku.csv"),
    ("Partner SLA", "partner_sla_performance.csv"),
    ("DQ Issues", "data_quality_issues.csv"),
]


def _column_widths(df: pd.DataFrame) -> list[int]:
    widths: list[int] = []
    for column in df.columns:
        header_width = len(str(column)) + 2
        if df.empty:
            widths.append(min(max(header_width, 12), 34))
            continue
        sample_width = int(df[column].astype(str).str.len().head(500).max()) + 2
        widths.append(min(max(header_width, sample_width, 10), 42))
    return widths


def _format_sheet(writer: pd.ExcelWriter, sheet_name: str, df: pd.DataFrame) -> None:
    workbook = writer.book
    worksheet = writer.sheets[sheet_name]
    header_format = workbook.add_format(
        {
            "bold": True,
            "font_color": "white",
            "bg_color": "#1F4E79",
            "border": 1,
        }
    )
    body_format = workbook.add_format({"border": 0})

    worksheet.freeze_panes(1, 0)
    if len(df.columns) > 0:
        worksheet.autofilter(0, 0, max(len(df), 1), len(df.columns) - 1)
        for col_idx, column in enumerate(df.columns):
            worksheet.write(0, col_idx, column, header_format)
        for col_idx, width in enumerate(_column_widths(df)):
            worksheet.set_column(col_idx, col_idx, width, body_format)


def build_excel_workbook() -> Path:
    """Create a formatted .xlsx workbook from the latest dashboard exports."""

    EXCEL_OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    with pd.ExcelWriter(WORKBOOK_PATH, engine="xlsxwriter") as writer:
        for sheet_name, filename in WORKSHEETS:
            csv_path = DASHBOARD_EXPORT_DIR / filename
            if not csv_path.exists():
                raise FileNotFoundError(f"Expected dashboard export not found: {csv_path}")
            df = pd.read_csv(csv_path)
            df.to_excel(writer, sheet_name=sheet_name, index=False)
            _format_sheet(writer, sheet_name, df)

        instructions = writer.book.add_worksheet("Instructions")
        title_format = writer.book.add_format({"bold": True, "font_size": 14, "font_color": "#1F4E79"})
        label_format = writer.book.add_format({"bold": True})
        instructions.write("A1", "Reverse Logistics PO & Inventory Removal Control Tower", title_format)
        instructions.write("A3", "Workbook purpose", label_format)
        instructions.write(
            "B3",
            "Operations workbook for refreshing dashboard CSV outputs, filtering by region/site/partner, and generating weekly leadership summaries.",
        )
        instructions.write("A4", "Refresh source", label_format)
        instructions.write("B4", "outputs/dashboard_exports")
        instructions.write("A5", "Macro setup", label_format)
        instructions.write("B5", "Import vba_modules/ControlTowerOps.bas, save as .xlsm, then run RefreshAllData.")
        instructions.write("A6", "Primary tabs", label_format)
        instructions.write("B6", "Dashboard, Backlog, PO Tracker, DQ Issues, Requests, At Risk SKU")
        instructions.set_column("A:A", 20)
        instructions.set_column("B:B", 120)

    return WORKBOOK_PATH

