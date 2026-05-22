PRAGMA foreign_keys = ON;

DELETE FROM data_quality_issues;
DELETE FROM exceptions;
DELETE FROM material_requests;
DELETE FROM scrap_removal_requests;
DELETE FROM truck_schedules;
DELETE FROM purchase_orders;
DELETE FROM inventory_movements;
DELETE FROM products;
DELETE FROM partners;
DELETE FROM sites;

INSERT INTO sites (site_id, site_name, region, country, site_type, timezone)
WITH ranked AS (
    SELECT
        *,
        ROW_NUMBER() OVER (PARTITION BY site_id ORDER BY rowid) AS rn
    FROM stg_sites
    WHERE site_id IS NOT NULL
)
SELECT site_id, site_name, region, country, site_type, timezone
FROM ranked
WHERE rn = 1;

INSERT INTO partners (partner_id, partner_name, partner_type, region, sla_days)
WITH ranked AS (
    SELECT
        *,
        ROW_NUMBER() OVER (PARTITION BY partner_id ORDER BY rowid) AS rn
    FROM stg_partners
    WHERE partner_id IS NOT NULL
)
SELECT partner_id, partner_name, partner_type, region, CAST(SLA_days AS INTEGER)
FROM ranked
WHERE rn = 1;

INSERT INTO products (sku, category, disposition_type, unit_value)
WITH ranked AS (
    SELECT
        *,
        ROW_NUMBER() OVER (PARTITION BY sku ORDER BY rowid) AS rn
    FROM stg_products
    WHERE sku IS NOT NULL
)
SELECT sku, category, disposition_type, CAST(unit_value AS REAL)
FROM ranked
WHERE rn = 1;

INSERT INTO inventory_movements (
    movement_id,
    sku,
    origin_site,
    destination_site,
    partner_id,
    quantity,
    movement_type,
    created_date,
    scheduled_ship_date,
    actual_ship_date,
    status
)
WITH ranked AS (
    SELECT
        *,
        ROW_NUMBER() OVER (PARTITION BY movement_id ORDER BY rowid) AS rn
    FROM stg_inventory_movements
    WHERE movement_id IS NOT NULL
)
SELECT
    r.movement_id,
    r.sku,
    r.origin_site,
    r.destination_site,
    r.partner_id,
    CAST(r.quantity AS INTEGER),
    r.movement_type,
    r.created_date,
    r.scheduled_ship_date,
    NULLIF(r.actual_ship_date, ''),
    r.status
FROM ranked r
WHERE r.rn = 1
  AND EXISTS (SELECT 1 FROM products p WHERE p.sku = r.sku)
  AND EXISTS (SELECT 1 FROM sites s WHERE s.site_id = r.origin_site)
  AND EXISTS (SELECT 1 FROM sites s WHERE s.site_id = r.destination_site)
  AND EXISTS (SELECT 1 FROM partners p WHERE p.partner_id = r.partner_id);

INSERT INTO purchase_orders (
    po_id,
    partner_id,
    region,
    po_type,
    amount,
    currency,
    created_date,
    approved_date,
    approval_status,
    accounting_status,
    linked_movement_id
)
WITH ranked AS (
    SELECT
        *,
        ROW_NUMBER() OVER (PARTITION BY po_id ORDER BY rowid) AS rn
    FROM stg_purchase_orders
    WHERE po_id IS NOT NULL
)
SELECT
    r.po_id,
    r.partner_id,
    r.region,
    r.po_type,
    CAST(r.amount AS REAL),
    r.currency,
    r.created_date,
    NULLIF(r.approved_date, ''),
    r.approval_status,
    r.accounting_status,
    NULLIF(r.linked_movement_id, '')
FROM ranked r
WHERE r.rn = 1
  AND EXISTS (SELECT 1 FROM partners p WHERE p.partner_id = r.partner_id)
  AND (
      NULLIF(r.linked_movement_id, '') IS NULL
      OR EXISTS (SELECT 1 FROM inventory_movements im WHERE im.movement_id = r.linked_movement_id)
  );

INSERT INTO truck_schedules (
    truck_id,
    linked_movement_id,
    carrier,
    origin_site,
    destination_site,
    scheduled_pickup,
    actual_pickup,
    scheduled_delivery,
    actual_delivery,
    truck_status
)
WITH ranked AS (
    SELECT
        *,
        ROW_NUMBER() OVER (PARTITION BY truck_id ORDER BY rowid) AS rn
    FROM stg_truck_schedules
    WHERE truck_id IS NOT NULL
)
SELECT
    r.truck_id,
    NULLIF(r.linked_movement_id, ''),
    r.carrier,
    r.origin_site,
    r.destination_site,
    r.scheduled_pickup,
    NULLIF(r.actual_pickup, ''),
    r.scheduled_delivery,
    NULLIF(r.actual_delivery, ''),
    r.truck_status
FROM ranked r
WHERE r.rn = 1
  AND EXISTS (SELECT 1 FROM sites s WHERE s.site_id = r.origin_site)
  AND EXISTS (SELECT 1 FROM sites s WHERE s.site_id = r.destination_site)
  AND (
      NULLIF(r.linked_movement_id, '') IS NULL
      OR EXISTS (SELECT 1 FROM inventory_movements im WHERE im.movement_id = r.linked_movement_id)
  );

INSERT INTO scrap_removal_requests (
    removal_id,
    site_id,
    partner_id,
    sku,
    quantity,
    reason_code,
    created_date,
    approved_date,
    removed_date,
    status
)
WITH ranked AS (
    SELECT
        *,
        ROW_NUMBER() OVER (PARTITION BY removal_id ORDER BY rowid) AS rn
    FROM stg_scrap_removal_requests
    WHERE removal_id IS NOT NULL
)
SELECT
    r.removal_id,
    r.site_id,
    r.partner_id,
    r.sku,
    CAST(r.quantity AS INTEGER),
    r.reason_code,
    r.created_date,
    NULLIF(r.approved_date, ''),
    NULLIF(r.removed_date, ''),
    r.status
FROM ranked r
WHERE r.rn = 1
  AND EXISTS (SELECT 1 FROM sites s WHERE s.site_id = r.site_id)
  AND EXISTS (SELECT 1 FROM partners p WHERE p.partner_id = r.partner_id)
  AND EXISTS (SELECT 1 FROM products p WHERE p.sku = r.sku);

INSERT INTO material_requests (
    request_id,
    requester_team,
    site_id,
    sku,
    quantity,
    priority,
    request_date,
    fulfilled_date,
    status
)
WITH ranked AS (
    SELECT
        *,
        ROW_NUMBER() OVER (PARTITION BY request_id ORDER BY rowid) AS rn
    FROM stg_material_requests
    WHERE request_id IS NOT NULL
)
SELECT
    r.request_id,
    r.requester_team,
    r.site_id,
    r.sku,
    CAST(r.quantity AS INTEGER),
    r.priority,
    r.request_date,
    NULLIF(r.fulfilled_date, ''),
    r.status
FROM ranked r
WHERE r.rn = 1
  AND EXISTS (SELECT 1 FROM sites s WHERE s.site_id = r.site_id)
  AND EXISTS (SELECT 1 FROM products p WHERE p.sku = r.sku);

INSERT INTO exceptions (
    exception_id,
    related_entity_type,
    related_entity_id,
    exception_type,
    severity,
    opened_date,
    closed_date,
    owner
)
WITH ranked AS (
    SELECT
        *,
        ROW_NUMBER() OVER (PARTITION BY exception_id ORDER BY rowid) AS rn
    FROM stg_exceptions
    WHERE exception_id IS NOT NULL
)
SELECT
    exception_id,
    related_entity_type,
    related_entity_id,
    exception_type,
    severity,
    opened_date,
    NULLIF(closed_date, ''),
    owner
FROM ranked
WHERE rn = 1;

