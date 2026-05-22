# Data Quality and Reconciliation Report

Reporting date: `2026-05-22`

This report is intentionally non-empty. The raw synthetic files include realistic defects so the analyst workflow can demonstrate issue detection, reconciliation, and clean-table loading.

## Validation Summary

| check_name | issue_count |
| --- | --- |
| po_missing_movement | 19 |
| truck_before_po_approval | 94 |
| actual_pickup_before_scheduled | 64 |
| removal_closed_missing_date | 16 |
| material_fulfilled_zero_qty | 13 |
| invalid_inventory_refs | 26 |
| duplicate_po_ids | 9 |
| duplicate_movement_ids | 14 |
| overdue_removals | 364 |

## Reconciliation Row Counts

| entity | raw_rows | clean_rows |
| --- | --- | --- |
| sites | 15 | 15 |
| partners | 11 | 11 |
| products | 75 | 75 |
| inventory_movements | 2264 | 2224 |
| purchase_orders | 649 | 622 |
| truck_schedules | 930 | 924 |
| scrap_removal_requests | 840 | 840 |
| material_requests | 720 | 720 |
| exceptions | 430 | 430 |

## Reconciliation Quantity Totals

| entity | raw_quantity | clean_quantity |
| --- | --- | --- |
| inventory_movements | 258897 | 254035 |
| scrap_removal_requests | 111906 | 111906 |
| material_requests | 59378 | 59378 |

## Reconciliation Financials

| entity | raw_amount | clean_amount | excluded_amount |
| --- | --- | --- | --- |
| purchase_orders | 4663440.77 | 4471337.29 | 192103.48 |

## Sample Data Quality Issues

| issue_key | related_entity_type | related_entity_id | issue_detail | severity |
| --- | --- | --- | --- | --- |
| po_linked_to_missing_movement | purchase_order | PO000085 | PO linked_movement_id MV-MISSING-017 does not exist in raw inventory movements. | High |
| po_linked_to_missing_movement | purchase_order | PO000092 | PO linked_movement_id MV-MISSING-010 does not exist in raw inventory movements. | High |
| po_linked_to_missing_movement | purchase_order | PO000110 | PO linked_movement_id MV-MISSING-016 does not exist in raw inventory movements. | High |
| po_linked_to_missing_movement | purchase_order | PO000114 | PO linked_movement_id MV-MISSING-006 does not exist in raw inventory movements. | High |
| po_linked_to_missing_movement | purchase_order | PO000139 | PO linked_movement_id MV-MISSING-008 does not exist in raw inventory movements. | High |
| po_linked_to_missing_movement | purchase_order | PO000141 | PO linked_movement_id MV-MISSING-013 does not exist in raw inventory movements. | High |
| po_linked_to_missing_movement | purchase_order | PO000152 | PO linked_movement_id MV-MISSING-007 does not exist in raw inventory movements. | High |
| po_linked_to_missing_movement | purchase_order | PO000216 | PO linked_movement_id MV-MISSING-018 does not exist in raw inventory movements. | High |
| po_linked_to_missing_movement | purchase_order | PO000257 | PO linked_movement_id MV-MISSING-009 does not exist in raw inventory movements. | High |
| po_linked_to_missing_movement | purchase_order | PO000286 | PO linked_movement_id MV-MISSING-001 does not exist in raw inventory movements. | High |
| po_linked_to_missing_movement | purchase_order | PO000288 | PO linked_movement_id MV-MISSING-015 does not exist in raw inventory movements. | High |
| po_linked_to_missing_movement | purchase_order | PO000317 | PO linked_movement_id MV-MISSING-002 does not exist in raw inventory movements. | High |
| po_linked_to_missing_movement | purchase_order | PO000350 | PO linked_movement_id MV-MISSING-014 does not exist in raw inventory movements. | High |
| po_linked_to_missing_movement | purchase_order | PO000365 | PO linked_movement_id MV-MISSING-011 does not exist in raw inventory movements. | High |
| po_linked_to_missing_movement | purchase_order | PO000450 | PO linked_movement_id MV-MISSING-012 does not exist in raw inventory movements. | High |
| po_linked_to_missing_movement | purchase_order | PO000453 | PO linked_movement_id MV-MISSING-003 does not exist in raw inventory movements. | High |
| po_linked_to_missing_movement | purchase_order | PO000604 | PO linked_movement_id MV-MISSING-004 does not exist in raw inventory movements. | High |
| po_linked_to_missing_movement | purchase_order | PO000616 | PO linked_movement_id MV-MISSING-005 does not exist in raw inventory movements. | High |
| po_linked_to_missing_movement | purchase_order | PO000139 | PO linked_movement_id MV-MISSING-008 does not exist in raw inventory movements. | High |
| truck_scheduled_before_po_approval | truck_schedule | TRK000432 | Truck scheduled pickup 2026-01-16 00:00:00 is before PO approval date 2026-01-19 for PO PO000009. | Medium |
| truck_scheduled_before_po_approval | truck_schedule | TRK000515 | Truck scheduled pickup 2025-11-24 00:00:00 is before PO approval date 2025-11-25 for PO PO000012. | Medium |
| truck_scheduled_before_po_approval | truck_schedule | TRK000538 | Truck scheduled pickup 2026-04-20 00:00:00 is before PO approval date 2026-04-22 for PO PO000025. | Medium |
| truck_scheduled_before_po_approval | truck_schedule | TRK000744 | Truck scheduled pickup 2026-01-12 00:00:00 is before PO approval date 2026-01-15 for PO PO000026. | Medium |
| truck_scheduled_before_po_approval | truck_schedule | TRK000884 | Truck scheduled pickup 2026-04-12 11:00:00 is before PO approval date 2026-04-14 for PO PO000035. | Medium |
| truck_scheduled_before_po_approval | truck_schedule | TRK000051 | Truck scheduled pickup 2026-04-11 07:00:00 is before PO approval date 2026-04-14 for PO PO000043. | Medium |
