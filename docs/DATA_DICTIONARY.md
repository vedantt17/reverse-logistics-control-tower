# Data Dictionary

## Table Layers

| Layer | Location | Purpose |
| --- | --- | --- |
| Raw CSV | `data/raw` | Synthetic source files with intentional operational defects. |
| Staging tables | `stg_*` in SQLite | One-to-one load of raw CSVs for audit and validation. |
| Clean tables | normalized SQLite tables | Referentially valid records used for KPI views and BI exports. |
| Dashboard exports | `outputs/dashboard_exports` | BI-ready summary and detail tables. |
| Processed CSV | `data/processed` | Clean normalized tables exported for optional BI modeling. |

## `sites` / `stg_sites`

| Field | Type | Definition |
| --- | --- | --- |
| `site_id` | text | Unique fictional site key. Primary key in clean table. |
| `site_name` | text | Fictional site name. |
| `region` | text | Operating region: North America, Europe, or Asia Pacific. |
| `country` | text | Country where the site operates. |
| `site_type` | text | Operating model, such as 1P Returns Center, 3P Processing Site, Repair Hub, or Scrap Yard. |
| `timezone` | text | Local IANA timezone used for scheduling context. |

## `partners` / `stg_partners`

| Field | Type | Definition |
| --- | --- | --- |
| `partner_id` | text | Unique fictional partner key. Primary key in clean table. |
| `partner_name` | text | Fictional partner name. |
| `partner_type` | text | Carrier, 3P Refurbisher, Scrap Recycler, Component Supplier, or Ops Support. |
| `region` | text | Primary operating region or Global. |
| `SLA_days` / `sla_days` | integer | Partner service level agreement in calendar days. Staging keeps source case; clean table uses lowercase. |

## `products` / `stg_products`

| Field | Type | Definition |
| --- | --- | --- |
| `sku` | text | Unique fictional SKU/component key. Primary key in clean table. |
| `category` | text | Product category, such as Smartphone, Laptop, Audio, or Component. |
| `disposition_type` | text | Expected disposition: Resell, Refurbish, Repair, Recycle, or Scrap. |
| `unit_value` | real | Synthetic estimated unit value used for at-risk inventory calculations. |

## `inventory_movements` / `stg_inventory_movements`

| Field | Type | Definition |
| --- | --- | --- |
| `movement_id` | text | Unique inventory movement key. Primary key in clean table. |
| `sku` | text | SKU being moved. Foreign key to `products` in clean table. |
| `origin_site` | text | Source site. Foreign key to `sites` in clean table. |
| `destination_site` | text | Destination site. Foreign key to `sites` in clean table. |
| `partner_id` | text | Partner supporting the movement. Foreign key to `partners` in clean table. |
| `quantity` | integer | Units in the movement. |
| `movement_type` | text | Return Transfer, Refurbishment Transfer, Repair Dispatch, Disposal Transfer, or Inter-site Rebalance. |
| `created_date` | date text | Date the movement was created. |
| `scheduled_ship_date` | date text | Planned ship date. |
| `actual_ship_date` | date text | Actual ship date when available. Blank for many open or canceled movements. |
| `status` | text | Created, Scheduled, In Transit, Delivered, Delayed, Canceled, or Exception Hold. |

## `purchase_orders` / `stg_purchase_orders`

| Field | Type | Definition |
| --- | --- | --- |
| `po_id` | text | Unique PO key. Primary key in clean table. |
| `partner_id` | text | Partner receiving the PO. Foreign key to `partners` in clean table. |
| `region` | text | Region associated with the PO. |
| `po_type` | text | 3P Service Fee, Carrier Freight, Refurbishment Labor, Scrap Removal, or Component Procurement. |
| `amount` | real | Synthetic PO amount. |
| `currency` | text | Currency code, generally USD or EUR in this simulation. |
| `created_date` | date text | PO creation date. |
| `approved_date` | date text | PO approval date when applicable. |
| `approval_status` | text | Approved, Pending, Delayed, Rejected, or Canceled. |
| `accounting_status` | text | Not Submitted, Submitted, Cleared, Accrual Needed, or Disputed. |
| `linked_movement_id` | text | Inventory movement linked to the PO. Foreign key to `inventory_movements` in clean table when present. |

## `truck_schedules` / `stg_truck_schedules`

| Field | Type | Definition |
| --- | --- | --- |
| `truck_id` | text | Unique truck schedule key. Primary key in clean table. |
| `linked_movement_id` | text | Movement carried by the truck. Foreign key to `inventory_movements` in clean table when present. |
| `carrier` | text | Fictional carrier name. |
| `origin_site` | text | Pickup site. Foreign key to `sites` in clean table. |
| `destination_site` | text | Delivery site. Foreign key to `sites` in clean table. |
| `scheduled_pickup` | datetime text | Planned pickup timestamp. |
| `actual_pickup` | datetime text | Actual pickup timestamp when known. |
| `scheduled_delivery` | datetime text | Planned delivery timestamp. |
| `actual_delivery` | datetime text | Actual delivery timestamp when known. |
| `truck_status` | text | Completed, In Transit, Delayed, Scheduled, or Canceled. |

## `scrap_removal_requests` / `stg_scrap_removal_requests`

| Field | Type | Definition |
| --- | --- | --- |
| `removal_id` | text | Unique removal request key. Primary key in clean table. |
| `site_id` | text | Site requesting removal. Foreign key to `sites` in clean table. |
| `partner_id` | text | Removal or refurbishing partner. Foreign key to `partners` in clean table. |
| `sku` | text | SKU/component being removed. Foreign key to `products` in clean table. |
| `quantity` | integer | Units requested for removal. |
| `reason_code` | text | Damaged Beyond Repair, Battery Swell, Obsolete Component, Compliance Hold, Return Fraud, or Liquidation Lot. |
| `created_date` | date text | Removal request creation date. |
| `approved_date` | date text | Approval date when applicable. |
| `removed_date` | date text | Completed removal date when applicable. |
| `status` | text | Requested, Approved, Removed, Overdue, Canceled, or Hold. |

## `material_requests` / `stg_material_requests`

| Field | Type | Definition |
| --- | --- | --- |
| `request_id` | text | Unique material request key. Primary key in clean table. |
| `requester_team` | text | Team requesting material or component action. |
| `site_id` | text | Requesting site. Foreign key to `sites` in clean table. |
| `sku` | text | Requested SKU/component. Foreign key to `products` in clean table. |
| `quantity` | integer | Requested units. Some raw fulfilled records intentionally contain zero or missing quantity for validation. |
| `priority` | text | Critical, High, Medium, or Low. |
| `request_date` | date text | Request creation date. |
| `fulfilled_date` | date text | Fulfillment date when applicable. |
| `status` | text | Open, In Progress, Fulfilled, Backordered, or Canceled. |

## `exceptions` / `stg_exceptions`

| Field | Type | Definition |
| --- | --- | --- |
| `exception_id` | text | Unique exception key. Primary key in clean table. |
| `related_entity_type` | text | Entity type: inventory_movement, purchase_order, truck_schedule, scrap_removal, or material_request. |
| `related_entity_id` | text | ID of the related entity. |
| `exception_type` | text | Operational exception category, such as Carrier No Show, PO Approval Delay, or Site Congestion. |
| `severity` | text | Critical, High, Medium, or Low. |
| `opened_date` | date text | Date the exception was opened. |
| `closed_date` | date text | Date the exception was closed. Blank means open. |
| `owner` | text | Owning team. |

## `run_metadata`

| Field | Type | Definition |
| --- | --- | --- |
| `key` | text | Metadata key. |
| `value` | text | Metadata value. The pipeline stores `as_of_date` here. |

## `data_quality_issues`

| Field | Type | Definition |
| --- | --- | --- |
| `issue_key` | text | Validation issue type. |
| `related_entity_type` | text | Entity type associated with the issue. |
| `related_entity_id` | text | Entity ID associated with the issue. |
| `issue_detail` | text | Human-readable issue detail. |
| `severity` | text | Critical, High, Medium, or Low. |
| `detected_at` | datetime text | SQLite timestamp when issue was written. |

## Validation Views

| View | Definition |
| --- | --- |
| `vw_val_po_missing_movement` | PO references a movement ID missing from raw inventory movements. |
| `vw_val_truck_before_po_approval` | Truck pickup was scheduled before linked PO approval. |
| `vw_val_actual_pickup_before_scheduled` | Actual pickup is earlier than scheduled pickup. |
| `vw_val_removal_closed_missing_date` | Removal is marked Removed without `removed_date`. |
| `vw_val_material_fulfilled_zero_qty` | Fulfilled material request has zero or missing quantity. |
| `vw_val_invalid_inventory_refs` | Movement references invalid site, partner, or SKU. |
| `vw_val_duplicate_po_ids` | Raw PO file has duplicate PO IDs. |
| `vw_val_duplicate_movement_ids` | Raw movement file has duplicate movement IDs. |
| `vw_val_overdue_removals` | Open removal request age exceeds partner SLA. |

## Dashboard Export Tables

| File | Source View | Purpose |
| --- | --- | --- |
| `kpi_summary.csv` | `vw_kpi_summary` | Executive KPI cards. |
| `backlog_by_region_site.csv` | `vw_backlog_by_region_site` | Backlog and aging by region/site. |
| `po_status_by_partner.csv` | `vw_po_status_by_partner` | PO counts, amounts, and cycle time by partner/status. |
| `po_tracker.csv` | `vw_po_tracker` | Detail-level PO tracker. |
| `truck_delay_trend.csv` | `vw_truck_delay_trend` | Weekly pickup and delivery delay trend. |
| `removal_aging_distribution.csv` | `vw_removal_aging_distribution` | Removal age distribution by region. |
| `site_exception_table.csv` | `vw_site_exception_table` | Site-level exception summary. |
| `high_priority_material_requests.csv` | `vw_high_priority_material_requests` | Critical and high-priority request backlog. |
| `at_risk_inventory_by_sku.csv` | `vw_at_risk_inventory_by_sku` | At-risk unit and value exposure by SKU. |
| `partner_sla_performance.csv` | `vw_partner_sla_performance` | Movement and removal SLA rates by partner. |
| `exception_count_by_severity.csv` | `vw_exception_count_by_severity` | Exception count by severity. |
| `overdue_removals.csv` | `vw_overdue_removals` | Detail-level overdue removal queue. |
| `delayed_pos.csv` | `vw_delayed_pos` | Detail-level delayed, pending, disputed, or accrual-needed PO queue. |
| `data_quality_issues.csv` | `data_quality_issues` | Consolidated validation output. |

