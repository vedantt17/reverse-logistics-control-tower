# Dashboard Specification

## BI Tool Options

The exported CSVs under `outputs/dashboard_exports` are ready for Power BI, Tableau, Excel Power Query, or any BI tool that can ingest flat files. Use `kpi_summary.csv` as the executive metric source and join detailed tables only where interactive drill-through is needed.

## Recommended Pages

### 1. Executive Overview

Data sources:

- `kpi_summary.csv`
- `backlog_by_region_site.csv`
- `exception_count_by_severity.csv`

Visuals:

- KPI cards for open inventory units, removal aging, SLA breach rate, open PO count, truck on-time rates, at-risk inventory value, and backlog reduction opportunity.
- Bar chart: backlog units by region.
- Table: top backlog sites by units and average age.
- Donut or stacked bar: exception count by severity.

Filters:

- Region
- Site
- Partner
- Status

### 2. PO and Partner Performance

Data sources:

- `po_status_by_partner.csv`
- `po_tracker.csv`
- `partner_sla_performance.csv`
- `delayed_pos.csv`

Visuals:

- Stacked bar: PO approval status by partner.
- Table: delayed or disputed POs.
- Scatter or matrix: partner SLA performance by partner type.
- KPI card: average PO approval cycle time.

### 3. Transportation and Movement Risk

Data sources:

- `truck_delay_trend.csv`
- `backlog_by_region_site.csv`
- `at_risk_inventory_by_sku.csv`

Visuals:

- Line chart: average pickup delay hours by week.
- Line chart: average delivery delay hours by week.
- Bar chart: at-risk inventory value by category.
- Table: highest at-risk SKU/component records.

### 4. Scrap Removal and Materials

Data sources:

- `removal_aging_distribution.csv`
- `overdue_removals.csv`
- `high_priority_material_requests.csv`

Visuals:

- Histogram or stacked bar: removal aging distribution.
- Table: overdue removals with days past SLA.
- Table: high-priority material request backlog.
- KPI card: high-priority request count.

### 5. Data Quality and Exceptions

Data sources:

- `data_quality_issues.csv`
- `site_exception_table.csv`
- `validation_summary.csv`

Visuals:

- Bar chart: issue count by validation type.
- Table: site-level open exception count.
- Table: critical data quality issues.

## Suggested Data Model

Import these files as independent fact/summary tables for a lightweight BI model:

- `kpi_summary.csv`
- `backlog_by_region_site.csv`
- `po_tracker.csv`
- `truck_delay_trend.csv`
- `removal_aging_distribution.csv`
- `high_priority_material_requests.csv`
- `at_risk_inventory_by_sku.csv`
- `partner_sla_performance.csv`
- `data_quality_issues.csv`

For a normalized BI model, use the clean CSVs under `data/processed`:

- Dimensions: `sites.csv`, `partners.csv`, `products.csv`
- Facts: `inventory_movements.csv`, `purchase_orders.csv`, `truck_schedules.csv`, `scrap_removal_requests.csv`, `material_requests.csv`, `exceptions.csv`

## Refresh Cadence

- Weekly leadership view: Monday morning.
- PO tracker and overdue removals: daily during backlog spikes.
- Transportation trend: weekly, with ad-hoc pulls for carrier escalations.
- Data quality report: every pipeline run.

