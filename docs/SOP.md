# Standard Operating Procedures

## Purpose

This SOP describes recurring and ad-hoc analytics workflows for the fictional Reverse Logistics PO and Inventory Removal Control Tower. The workflows are designed for a Business Analyst, Operations and Materials role supporting returned consumer electronics across internal sites, 3P partners, truck scheduling, PO tracking, material requests, and scrap removal.

## Weekly Reporting Workflow

1. Pull or regenerate the current reporting dataset.

   ```bash
   python run_pipeline.py --as-of-date 2026-05-22
   ```

2. Review `reports/validation_report.md`.

   Confirm the expected synthetic defects are detected, including invalid movement references, duplicate IDs, overdue removals, delayed POs, and truck timing anomalies.

3. Review `reports/kpi_snapshot.md`.

   Capture the executive KPI values, top backlog sites, highest at-risk SKUs, and delayed PO examples.

4. Open `outputs/excel/Reverse_Logistics_Control_Tower.xlsx`.

   If macros are needed, save a copy as `.xlsm`, import `vba_modules/ControlTowerOps.bas`, and run `RefreshAllData`.

5. Run `GenerateWeeklyOpsSummary`.

   Use the generated `Weekly Summary` worksheet as the working view for leadership review.

6. Run `ExportLeadershipReport`.

   Save the PDF to `reports/weekly_leadership_report_YYYYMMDD.pdf`.

7. Send the weekly summary to stakeholders with three required callouts:

   - Top 3 backlog sites by units and age.
   - Overdue removals beyond partner SLA.
   - PO or truck blockers requiring owner action.

## Ad-Hoc PO Report Workflow

1. Refresh the pipeline and workbook.
2. Open the `PO Tracker` worksheet or `outputs/dashboard_exports/po_tracker.csv`.
3. Filter by region, partner, approval status, accounting status, or movement status.
4. Prioritize records where:

   - `approval_status` is `Pending` or `Delayed`.
   - `accounting_status` is `Disputed` or `Accrual Needed`.
   - `linked_movement_id` maps to a delayed or exception-held movement.

5. Share the filtered view with Finance Ops, Partner Management, and Transportation as needed.

## Overdue Scrap Removal Escalation Workflow

1. Review `outputs/dashboard_exports/overdue_removals.csv`.
2. Sort by `days_past_sla` descending.
3. Confirm the site, partner, SKU, reason code, and removal quantity.
4. Escalate by severity:

   - 30+ days past SLA: regional operations leader and partner manager.
   - 15-30 days past SLA: site operations manager and partner manager.
   - 1-14 days past SLA: site inventory control owner.

5. Track owner response in the weekly operations notes.
6. Re-run the report after removal completion to confirm backlog reduction.

## Material Request Triage Workflow

1. Review `outputs/dashboard_exports/high_priority_material_requests.csv`.
2. Prioritize `Critical` before `High`, then sort by `age_days` descending.
3. Check whether the SKU is also present in `at_risk_inventory_by_sku.csv`.
4. For high-value or constrained components, validate whether an open PO exists in `po_tracker.csv`.
5. Route unresolved records:

   - Component availability: Materials Planning.
   - Site execution delay: Inventory Control.
   - Partner blocker: Partner Management.
   - Missing or invalid request quantity: Data Quality queue.

## Data Quality Handling

The raw synthetic data intentionally includes defects. Do not delete raw defects. Use them to demonstrate the control tower reconciliation workflow:

1. Keep raw CSVs unchanged for auditability.
2. Load clean normalized tables only after validation.
3. Use `data_quality_issues.csv` as the exception queue.
4. Use reconciliation views to explain why raw and clean counts differ.

