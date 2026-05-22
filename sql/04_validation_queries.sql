DROP VIEW IF EXISTS vw_val_po_missing_movement;
DROP VIEW IF EXISTS vw_val_truck_before_po_approval;
DROP VIEW IF EXISTS vw_val_actual_pickup_before_scheduled;
DROP VIEW IF EXISTS vw_val_removal_closed_missing_date;
DROP VIEW IF EXISTS vw_val_material_fulfilled_zero_qty;
DROP VIEW IF EXISTS vw_val_invalid_inventory_refs;
DROP VIEW IF EXISTS vw_val_duplicate_po_ids;
DROP VIEW IF EXISTS vw_val_duplicate_movement_ids;
DROP VIEW IF EXISTS vw_val_overdue_removals;

CREATE VIEW vw_val_po_missing_movement AS
SELECT
    'po_linked_to_missing_movement' AS issue_key,
    'purchase_order' AS related_entity_type,
    po_id AS related_entity_id,
    'PO linked_movement_id ' || COALESCE(linked_movement_id, '<null>') || ' does not exist in raw inventory movements.' AS issue_detail,
    'High' AS severity
FROM stg_purchase_orders
WHERE NULLIF(linked_movement_id, '') IS NOT NULL
  AND linked_movement_id NOT IN (SELECT movement_id FROM stg_inventory_movements);

CREATE VIEW vw_val_truck_before_po_approval AS
SELECT
    'truck_scheduled_before_po_approval' AS issue_key,
    'truck_schedule' AS related_entity_type,
    t.truck_id AS related_entity_id,
    'Truck scheduled pickup ' || t.scheduled_pickup || ' is before PO approval date ' || p.approved_date || ' for PO ' || p.po_id || '.' AS issue_detail,
    'Medium' AS severity
FROM stg_truck_schedules t
JOIN stg_purchase_orders p
  ON p.linked_movement_id = t.linked_movement_id
WHERE p.approval_status IN ('Approved', 'Delayed')
  AND NULLIF(p.approved_date, '') IS NOT NULL
  AND datetime(t.scheduled_pickup) < datetime(p.approved_date);

CREATE VIEW vw_val_actual_pickup_before_scheduled AS
SELECT
    'actual_pickup_before_scheduled_pickup' AS issue_key,
    'truck_schedule' AS related_entity_type,
    truck_id AS related_entity_id,
    'Actual pickup ' || actual_pickup || ' is before scheduled pickup ' || scheduled_pickup || '.' AS issue_detail,
    'Medium' AS severity
FROM stg_truck_schedules
WHERE NULLIF(actual_pickup, '') IS NOT NULL
  AND datetime(actual_pickup) < datetime(scheduled_pickup);

CREATE VIEW vw_val_removal_closed_missing_date AS
SELECT
    'removal_closed_without_removed_date' AS issue_key,
    'scrap_removal' AS related_entity_type,
    removal_id AS related_entity_id,
    'Removal is marked Removed but removed_date is blank.' AS issue_detail,
    'High' AS severity
FROM stg_scrap_removal_requests
WHERE status = 'Removed'
  AND NULLIF(removed_date, '') IS NULL;

CREATE VIEW vw_val_material_fulfilled_zero_qty AS
SELECT
    'fulfilled_material_request_with_zero_or_missing_quantity' AS issue_key,
    'material_request' AS related_entity_type,
    request_id AS related_entity_id,
    'Material request is Fulfilled with quantity ' || COALESCE(CAST(quantity AS TEXT), '<null>') || '.' AS issue_detail,
    'High' AS severity
FROM stg_material_requests
WHERE status = 'Fulfilled'
  AND (quantity IS NULL OR CAST(quantity AS INTEGER) <= 0);

CREATE VIEW vw_val_invalid_inventory_refs AS
SELECT
    'inventory_movement_with_invalid_reference' AS issue_key,
    'inventory_movement' AS related_entity_type,
    im.movement_id AS related_entity_id,
    TRIM(
        CASE WHEN p.sku IS NULL THEN ' invalid_sku=' || COALESCE(im.sku, '<null>') ELSE '' END ||
        CASE WHEN os.site_id IS NULL THEN ' invalid_origin_site=' || COALESCE(im.origin_site, '<null>') ELSE '' END ||
        CASE WHEN ds.site_id IS NULL THEN ' invalid_destination_site=' || COALESCE(im.destination_site, '<null>') ELSE '' END ||
        CASE WHEN pa.partner_id IS NULL THEN ' invalid_partner_id=' || COALESCE(im.partner_id, '<null>') ELSE '' END
    ) AS issue_detail,
    'Critical' AS severity
FROM stg_inventory_movements im
LEFT JOIN stg_products p ON p.sku = im.sku
LEFT JOIN stg_sites os ON os.site_id = im.origin_site
LEFT JOIN stg_sites ds ON ds.site_id = im.destination_site
LEFT JOIN stg_partners pa ON pa.partner_id = im.partner_id
WHERE p.sku IS NULL
   OR os.site_id IS NULL
   OR ds.site_id IS NULL
   OR pa.partner_id IS NULL;

CREATE VIEW vw_val_duplicate_po_ids AS
SELECT
    'duplicate_po_id' AS issue_key,
    'purchase_order' AS related_entity_type,
    po_id AS related_entity_id,
    'PO ID appears ' || COUNT(*) || ' times in the raw PO file.' AS issue_detail,
    'Critical' AS severity
FROM stg_purchase_orders
GROUP BY po_id
HAVING COUNT(*) > 1;

CREATE VIEW vw_val_duplicate_movement_ids AS
SELECT
    'duplicate_movement_id' AS issue_key,
    'inventory_movement' AS related_entity_type,
    movement_id AS related_entity_id,
    'Movement ID appears ' || COUNT(*) || ' times in the raw movement file.' AS issue_detail,
    'Critical' AS severity
FROM stg_inventory_movements
GROUP BY movement_id
HAVING COUNT(*) > 1;

CREATE VIEW vw_val_overdue_removals AS
WITH params AS (
    SELECT value AS as_of_date FROM run_metadata WHERE key = 'as_of_date'
)
SELECT
    'overdue_removal_older_than_sla' AS issue_key,
    'scrap_removal' AS related_entity_type,
    r.removal_id AS related_entity_id,
    'Removal age is ' || ROUND(julianday((SELECT as_of_date FROM params)) - julianday(r.created_date), 1)
        || ' days versus partner SLA of ' || p.SLA_days || ' days.' AS issue_detail,
    'High' AS severity
FROM stg_scrap_removal_requests r
JOIN stg_partners p ON p.partner_id = r.partner_id
WHERE r.status NOT IN ('Removed', 'Canceled')
  AND julianday((SELECT as_of_date FROM params)) - julianday(r.created_date) > p.SLA_days;

