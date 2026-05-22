# Business Requirements

## Business Problem

Reverse logistics operations teams often coordinate returned inventory across internal sites, 3P processing partners, carriers, material planners, finance teams, and scrap/removal vendors. Leadership needs a repeatable way to identify backlog, delayed PO approval, overdue removals, truck scheduling misses, partner SLA performance, and material request bottlenecks.

This project simulates that environment using fictional synthetic data and a reproducible analytics pipeline.

## Stakeholders

| Stakeholder | Requirement |
| --- | --- |
| Regional Operations | Monitor backlog units, aging, delayed movements, and site bottlenecks. |
| Materials Planning | Track high-priority material requests and fulfillment cycle time. |
| Finance Operations | Monitor PO approval status, accounting status, and disputed accruals. |
| Transportation | Monitor truck on-time pickup, delivery, cancellations, and delay trends. |
| Partner Management | Compare partner SLA performance and escalate overdue work. |
| Leadership | Receive concise weekly KPI summaries and ad-hoc operational cuts. |

## Functional Requirements

- Generate synthetic reverse logistics data without proprietary names or internal data.
- Load raw CSVs into staging tables for auditability.
- Load clean normalized SQLite tables with primary keys and foreign keys.
- Detect operational and data quality issues through reusable SQL validation views.
- Export dashboard-ready CSV tables for Power BI, Tableau, and Excel.
- Provide an Excel workbook and VBA modules for refresh, filtering, weekly summary generation, flagging, and report export.
- Document weekly, ad-hoc, and escalation workflows.

## KPI Requirements

- Total open inventory units.
- Backlog units by region and site.
- Average removal aging.
- Scrap removal SLA breach rate.
- PO approval cycle time.
- Open PO count by region and partner.
- Truck on-time pickup rate.
- Truck on-time delivery rate.
- Material request fulfillment cycle time.
- High-priority request backlog.
- Partner SLA performance.
- Exception count by severity.
- At-risk inventory value.
- Backlog reduction opportunity.

## Assumptions

- The data is synthetic and fictional.
- `as_of_date` controls aging, overdue, and backlog calculations.
- Partner SLA is stored at partner level and applied to removals and movement performance.
- A movement is considered open when status is `Created`, `Scheduled`, `In Transit`, `Delayed`, or `Exception Hold`.
- A removal is overdue when it is not removed or canceled and age exceeds partner SLA.
- PO approval cycle time uses `approved_date - created_date` for approved or delayed-and-approved POs.
- Clean tables exclude records that fail key referential integrity checks.

## Success Metrics

- Pipeline runs from documented commands.
- Raw CSVs are generated with required record volumes.
- SQLite database is created with normalized tables and views.
- Validation report identifies expected defects.
- Dashboard-ready exports are refreshed successfully.
- Excel workbook and VBA modules support the operations workflow.
- Reports and exports are clearly labeled and structured for stakeholder review.

## Limitations

- The project does not use real company data.
- Financial amounts are synthetic and should not be interpreted as benchmark costs.
- The workbook is delivered as `.xlsx` plus importable VBA modules. Users can save as `.xlsm` after importing macros.
- BI dashboards are specified through CSV exports and a dashboard specification rather than a packaged Power BI or Tableau file.

