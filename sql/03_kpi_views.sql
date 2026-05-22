DROP VIEW IF EXISTS vw_kpi_summary;
DROP VIEW IF EXISTS vw_backlog_by_region_site;
DROP VIEW IF EXISTS vw_po_status_by_partner;
DROP VIEW IF EXISTS vw_truck_delay_trend;
DROP VIEW IF EXISTS vw_removal_aging_distribution;
DROP VIEW IF EXISTS vw_site_exception_table;
DROP VIEW IF EXISTS vw_high_priority_material_requests;
DROP VIEW IF EXISTS vw_at_risk_inventory_by_sku;
DROP VIEW IF EXISTS vw_partner_sla_performance;
DROP VIEW IF EXISTS vw_exception_count_by_severity;
DROP VIEW IF EXISTS vw_po_tracker;
DROP VIEW IF EXISTS vw_overdue_removals;
DROP VIEW IF EXISTS vw_delayed_pos;

CREATE VIEW vw_kpi_summary AS
WITH params AS (
    SELECT value AS as_of_date FROM run_metadata WHERE key = 'as_of_date'
),
open_inventory AS (
    SELECT
        SUM(im.quantity) AS open_units,
        SUM(im.quantity * p.unit_value) AS open_value
    FROM inventory_movements im
    JOIN products p ON p.sku = im.sku
    WHERE im.status IN ('Created', 'Scheduled', 'In Transit', 'Delayed', 'Exception Hold')
),
removal_base AS (
    SELECT
        r.*,
        pa.sla_days,
        CASE
            WHEN r.removed_date IS NOT NULL THEN julianday(r.removed_date) - julianday(r.created_date)
            ELSE julianday((SELECT as_of_date FROM params)) - julianday(r.created_date)
        END AS age_days,
        CASE
            WHEN r.status <> 'Canceled'
             AND (
                (r.removed_date IS NOT NULL AND julianday(r.removed_date) - julianday(r.created_date) > pa.sla_days)
                OR (r.removed_date IS NULL AND julianday((SELECT as_of_date FROM params)) - julianday(r.created_date) > pa.sla_days)
             )
            THEN 1 ELSE 0
        END AS sla_breach
    FROM scrap_removal_requests r
    JOIN partners pa ON pa.partner_id = r.partner_id
    WHERE r.status <> 'Canceled'
),
po_cycle AS (
    SELECT AVG(julianday(approved_date) - julianday(created_date)) AS avg_cycle_days
    FROM purchase_orders
    WHERE approved_date IS NOT NULL
      AND approval_status IN ('Approved', 'Delayed')
),
truck_rates AS (
    SELECT
        100.0 * SUM(CASE WHEN actual_pickup IS NOT NULL
                           AND datetime(actual_pickup) >= datetime(scheduled_pickup)
                           AND datetime(actual_pickup) <= datetime(scheduled_pickup, '+2 hours')
                          THEN 1 ELSE 0 END)
            / NULLIF(SUM(CASE WHEN actual_pickup IS NOT NULL
                                AND truck_status <> 'Canceled'
                                AND datetime(actual_pickup) >= datetime(scheduled_pickup)
                               THEN 1 ELSE 0 END), 0) AS pickup_rate,
        100.0 * SUM(CASE WHEN actual_delivery IS NOT NULL AND datetime(actual_delivery) <= datetime(scheduled_delivery) THEN 1 ELSE 0 END)
            / NULLIF(SUM(CASE WHEN actual_delivery IS NOT NULL AND truck_status <> 'Canceled' THEN 1 ELSE 0 END), 0) AS delivery_rate
    FROM truck_schedules
),
material_cycle AS (
    SELECT AVG(julianday(fulfilled_date) - julianday(request_date)) AS avg_cycle_days
    FROM material_requests
    WHERE status = 'Fulfilled'
      AND fulfilled_date IS NOT NULL
      AND quantity > 0
),
high_priority_backlog AS (
    SELECT COUNT(*) AS request_count
    FROM material_requests
    WHERE priority IN ('Critical', 'High')
      AND status NOT IN ('Fulfilled', 'Canceled')
),
at_risk AS (
    SELECT
        SUM(im.quantity * p.unit_value) AS at_risk_value,
        SUM(im.quantity) AS at_risk_units
    FROM inventory_movements im
    JOIN products p ON p.sku = im.sku
    WHERE im.status IN ('Delayed', 'Exception Hold')
       OR (
            im.status IN ('Created', 'Scheduled', 'In Transit')
            AND julianday((SELECT as_of_date FROM params)) - julianday(im.created_date) > 21
       )
),
backlog_opp AS (
    SELECT SUM(im.quantity) AS reduction_units
    FROM inventory_movements im
    WHERE im.status IN ('Delayed', 'Exception Hold', 'Scheduled', 'Created')
      AND julianday((SELECT as_of_date FROM params)) - julianday(im.created_date) > 14
)
SELECT 'Total open inventory units' AS metric_name, ROUND(COALESCE(open_units, 0), 0) AS metric_value, 'units' AS metric_unit, (SELECT as_of_date FROM params) AS as_of_date FROM open_inventory
UNION ALL
SELECT 'Average removal aging', ROUND(AVG(age_days), 1), 'days', (SELECT as_of_date FROM params) FROM removal_base
UNION ALL
SELECT 'Scrap removal SLA breach rate', ROUND(100.0 * SUM(sla_breach) / NULLIF(COUNT(*), 0), 1), 'percent', (SELECT as_of_date FROM params) FROM removal_base
UNION ALL
SELECT 'PO approval cycle time', ROUND(avg_cycle_days, 1), 'days', (SELECT as_of_date FROM params) FROM po_cycle
UNION ALL
SELECT 'Open PO count', COUNT(*), 'POs', (SELECT as_of_date FROM params)
FROM purchase_orders
WHERE approval_status IN ('Pending', 'Delayed') OR accounting_status IN ('Disputed', 'Accrual Needed')
UNION ALL
SELECT 'Truck on-time pickup rate', ROUND(pickup_rate, 1), 'percent', (SELECT as_of_date FROM params) FROM truck_rates
UNION ALL
SELECT 'Truck on-time delivery rate', ROUND(delivery_rate, 1), 'percent', (SELECT as_of_date FROM params) FROM truck_rates
UNION ALL
SELECT 'Material request fulfillment cycle time', ROUND(avg_cycle_days, 1), 'days', (SELECT as_of_date FROM params) FROM material_cycle
UNION ALL
SELECT 'High-priority request backlog', request_count, 'requests', (SELECT as_of_date FROM params) FROM high_priority_backlog
UNION ALL
SELECT 'At-risk inventory value', ROUND(COALESCE(at_risk_value, 0), 2), 'currency', (SELECT as_of_date FROM params) FROM at_risk
UNION ALL
SELECT 'Backlog reduction opportunity', ROUND(COALESCE(reduction_units, 0), 0), 'units', (SELECT as_of_date FROM params) FROM backlog_opp;

CREATE VIEW vw_backlog_by_region_site AS
WITH params AS (
    SELECT value AS as_of_date FROM run_metadata WHERE key = 'as_of_date'
)
SELECT
    s.region,
    s.site_id,
    s.site_name,
    s.site_type,
    COUNT(DISTINCT im.movement_id) AS open_movement_count,
    SUM(im.quantity) AS backlog_units,
    ROUND(SUM(im.quantity * p.unit_value), 2) AS backlog_value,
    ROUND(AVG(julianday((SELECT as_of_date FROM params)) - julianday(im.created_date)), 1) AS avg_age_days,
    SUM(CASE WHEN im.status IN ('Delayed', 'Exception Hold') THEN im.quantity ELSE 0 END) AS delayed_or_hold_units
FROM inventory_movements im
JOIN sites s ON s.site_id = im.origin_site
JOIN products p ON p.sku = im.sku
WHERE im.status IN ('Created', 'Scheduled', 'In Transit', 'Delayed', 'Exception Hold')
GROUP BY s.region, s.site_id, s.site_name, s.site_type
ORDER BY backlog_units DESC;

CREATE VIEW vw_po_status_by_partner AS
SELECT
    po.region,
    po.partner_id,
    pa.partner_name,
    pa.partner_type,
    po.approval_status,
    po.accounting_status,
    COUNT(*) AS po_count,
    ROUND(SUM(po.amount), 2) AS total_amount,
    ROUND(AVG(CASE WHEN po.approved_date IS NOT NULL THEN julianday(po.approved_date) - julianday(po.created_date) END), 1) AS avg_approval_cycle_days
FROM purchase_orders po
JOIN partners pa ON pa.partner_id = po.partner_id
GROUP BY po.region, po.partner_id, pa.partner_name, pa.partner_type, po.approval_status, po.accounting_status
ORDER BY po.region, po_count DESC;

CREATE VIEW vw_truck_delay_trend AS
SELECT
    strftime('%Y-W%W', scheduled_pickup) AS pickup_week,
    COUNT(*) AS truck_count,
    SUM(CASE WHEN truck_status = 'Canceled' THEN 1 ELSE 0 END) AS canceled_trucks,
    SUM(CASE WHEN actual_pickup IS NULL AND truck_status IN ('Scheduled', 'Delayed') THEN 1 ELSE 0 END) AS missing_pickups,
    SUM(CASE WHEN actual_pickup IS NOT NULL AND datetime(actual_pickup) < datetime(scheduled_pickup) THEN 1 ELSE 0 END) AS early_pickup_dq_count,
    ROUND(AVG(CASE WHEN actual_pickup IS NOT NULL AND datetime(actual_pickup) >= datetime(scheduled_pickup) THEN (julianday(actual_pickup) - julianday(scheduled_pickup)) * 24 END), 1) AS avg_pickup_delay_hours,
    ROUND(AVG(CASE WHEN actual_delivery IS NOT NULL THEN (julianday(actual_delivery) - julianday(scheduled_delivery)) * 24 END), 1) AS avg_delivery_delay_hours
FROM truck_schedules
GROUP BY strftime('%Y-W%W', scheduled_pickup)
ORDER BY pickup_week;

CREATE VIEW vw_removal_aging_distribution AS
WITH params AS (
    SELECT value AS as_of_date FROM run_metadata WHERE key = 'as_of_date'
),
aged AS (
    SELECT
        s.region,
        r.status,
        CASE
            WHEN r.removed_date IS NOT NULL THEN julianday(r.removed_date) - julianday(r.created_date)
            ELSE julianday((SELECT as_of_date FROM params)) - julianday(r.created_date)
        END AS age_days,
        r.quantity
    FROM scrap_removal_requests r
    JOIN sites s ON s.site_id = r.site_id
    WHERE r.status <> 'Canceled'
)
SELECT
    region,
    CASE
        WHEN age_days <= 7 THEN '00-07 days'
        WHEN age_days <= 14 THEN '08-14 days'
        WHEN age_days <= 30 THEN '15-30 days'
        WHEN age_days <= 60 THEN '31-60 days'
        ELSE '61+ days'
    END AS age_bucket,
    COUNT(*) AS removal_count,
    SUM(quantity) AS removal_units,
    ROUND(AVG(age_days), 1) AS avg_age_days
FROM aged
GROUP BY region, age_bucket
ORDER BY region, age_bucket;

CREATE VIEW vw_site_exception_table AS
WITH stg_movement_dedup AS (
    SELECT *
    FROM (
        SELECT
            sim.*,
            ROW_NUMBER() OVER (PARTITION BY sim.movement_id ORDER BY sim.rowid) AS rn
        FROM stg_inventory_movements sim
    )
    WHERE rn = 1
),
stg_po_dedup AS (
    SELECT *
    FROM (
        SELECT
            spo.*,
            ROW_NUMBER() OVER (PARTITION BY spo.po_id ORDER BY spo.rowid) AS rn
        FROM stg_purchase_orders spo
    )
    WHERE rn = 1
),
stg_truck_dedup AS (
    SELECT *
    FROM (
        SELECT
            st.*,
            ROW_NUMBER() OVER (PARTITION BY st.truck_id ORDER BY st.rowid) AS rn
        FROM stg_truck_schedules st
    )
    WHERE rn = 1
),
mapped AS (
    SELECT
        e.*,
        COALESCE(im.origin_site, sim.origin_site) AS site_id,
        NULL AS fallback_region
    FROM exceptions e
    LEFT JOIN inventory_movements im
      ON e.related_entity_type = 'inventory_movement'
     AND e.related_entity_id = im.movement_id
    LEFT JOIN stg_movement_dedup sim
      ON e.related_entity_type = 'inventory_movement'
     AND e.related_entity_id = sim.movement_id
    WHERE e.related_entity_type = 'inventory_movement'
    UNION ALL
    SELECT
        e.*,
        COALESCE(im.origin_site, sim.origin_site) AS site_id,
        COALESCE(po.region, spo.region) AS fallback_region
    FROM exceptions e
    LEFT JOIN purchase_orders po
      ON e.related_entity_type = 'purchase_order'
     AND e.related_entity_id = po.po_id
    LEFT JOIN stg_po_dedup spo
      ON e.related_entity_type = 'purchase_order'
     AND e.related_entity_id = spo.po_id
    LEFT JOIN inventory_movements im
      ON im.movement_id = COALESCE(po.linked_movement_id, spo.linked_movement_id)
    LEFT JOIN stg_movement_dedup sim
      ON sim.movement_id = COALESCE(po.linked_movement_id, spo.linked_movement_id)
    WHERE e.related_entity_type = 'purchase_order'
    UNION ALL
    SELECT
        e.*,
        COALESCE(t.origin_site, st.origin_site) AS site_id,
        NULL AS fallback_region
    FROM exceptions e
    LEFT JOIN truck_schedules t
      ON e.related_entity_type = 'truck_schedule'
     AND e.related_entity_id = t.truck_id
    LEFT JOIN stg_truck_dedup st
      ON e.related_entity_type = 'truck_schedule'
     AND e.related_entity_id = st.truck_id
    WHERE e.related_entity_type = 'truck_schedule'
    UNION ALL
    SELECT
        e.*,
        r.site_id,
        NULL AS fallback_region
    FROM exceptions e
    JOIN scrap_removal_requests r
      ON e.related_entity_type = 'scrap_removal'
     AND e.related_entity_id = r.removal_id
    UNION ALL
    SELECT
        e.*,
        mr.site_id,
        NULL AS fallback_region
    FROM exceptions e
    JOIN material_requests mr
      ON e.related_entity_type = 'material_request'
     AND e.related_entity_id = mr.request_id
)
SELECT
    COALESCE(s.region, mapped.fallback_region, 'Unmapped') AS region,
    COALESCE(s.site_id, 'UNMAPPED') AS site_id,
    COALESCE(s.site_name, 'Unmapped / Unknown Site') AS site_name,
    COUNT(*) AS exception_count,
    SUM(CASE WHEN mapped.closed_date IS NULL THEN 1 ELSE 0 END) AS open_exception_count,
    SUM(CASE WHEN mapped.severity = 'Critical' THEN 1 ELSE 0 END) AS critical_count,
    SUM(CASE WHEN mapped.severity = 'High' THEN 1 ELSE 0 END) AS high_count,
    SUM(CASE WHEN mapped.severity = 'Medium' THEN 1 ELSE 0 END) AS medium_count,
    SUM(CASE WHEN mapped.severity = 'Low' THEN 1 ELSE 0 END) AS low_count
FROM mapped
LEFT JOIN sites s ON s.site_id = mapped.site_id
GROUP BY
    COALESCE(s.region, mapped.fallback_region, 'Unmapped'),
    COALESCE(s.site_id, 'UNMAPPED'),
    COALESCE(s.site_name, 'Unmapped / Unknown Site')
ORDER BY open_exception_count DESC, critical_count DESC;

CREATE VIEW vw_high_priority_material_requests AS
WITH params AS (
    SELECT value AS as_of_date FROM run_metadata WHERE key = 'as_of_date'
)
SELECT
    mr.request_id,
    mr.priority,
    mr.status,
    mr.requester_team,
    s.region,
    s.site_id,
    s.site_name,
    mr.sku,
    p.category,
    mr.quantity,
    mr.request_date,
    ROUND(julianday((SELECT as_of_date FROM params)) - julianday(mr.request_date), 1) AS age_days
FROM material_requests mr
JOIN sites s ON s.site_id = mr.site_id
JOIN products p ON p.sku = mr.sku
WHERE mr.priority IN ('Critical', 'High')
  AND mr.status NOT IN ('Fulfilled', 'Canceled')
ORDER BY
    CASE mr.priority WHEN 'Critical' THEN 1 WHEN 'High' THEN 2 ELSE 3 END,
    age_days DESC;

CREATE VIEW vw_at_risk_inventory_by_sku AS
WITH params AS (
    SELECT value AS as_of_date FROM run_metadata WHERE key = 'as_of_date'
)
SELECT
    p.sku,
    p.category,
    p.disposition_type,
    COUNT(DISTINCT im.movement_id) AS movement_count,
    SUM(im.quantity) AS at_risk_units,
    ROUND(SUM(im.quantity * p.unit_value), 2) AS at_risk_value,
    ROUND(MAX(julianday((SELECT as_of_date FROM params)) - julianday(im.created_date)), 1) AS oldest_age_days
FROM inventory_movements im
JOIN products p ON p.sku = im.sku
WHERE im.status IN ('Delayed', 'Exception Hold')
   OR (
        im.status IN ('Created', 'Scheduled', 'In Transit')
        AND julianday((SELECT as_of_date FROM params)) - julianday(im.created_date) > 21
   )
GROUP BY p.sku, p.category, p.disposition_type
ORDER BY at_risk_value DESC;

CREATE VIEW vw_partner_sla_performance AS
WITH movement_perf AS (
    SELECT
        pa.partner_id,
        COUNT(*) AS movement_count,
        SUM(CASE WHEN im.actual_ship_date IS NOT NULL
                  AND julianday(im.actual_ship_date) - julianday(im.scheduled_ship_date) <= pa.sla_days
                 THEN 1 ELSE 0 END) AS movement_on_sla
    FROM inventory_movements im
    JOIN partners pa ON pa.partner_id = im.partner_id
    WHERE im.status IN ('Delivered', 'In Transit', 'Delayed', 'Exception Hold')
    GROUP BY pa.partner_id
),
removal_perf AS (
    SELECT
        pa.partner_id,
        COUNT(*) AS removal_count,
        SUM(CASE WHEN r.removed_date IS NOT NULL
                  AND julianday(r.removed_date) - julianday(r.created_date) <= pa.sla_days
                 THEN 1 ELSE 0 END) AS removal_on_sla
    FROM scrap_removal_requests r
    JOIN partners pa ON pa.partner_id = r.partner_id
    WHERE r.status <> 'Canceled'
    GROUP BY pa.partner_id
)
SELECT
    pa.region,
    pa.partner_id,
    pa.partner_name,
    pa.partner_type,
    pa.sla_days,
    COALESCE(mp.movement_count, 0) AS movement_count,
    ROUND(100.0 * COALESCE(mp.movement_on_sla, 0) / NULLIF(mp.movement_count, 0), 1) AS movement_sla_rate,
    COALESCE(rp.removal_count, 0) AS removal_count,
    ROUND(100.0 * COALESCE(rp.removal_on_sla, 0) / NULLIF(rp.removal_count, 0), 1) AS removal_sla_rate
FROM partners pa
LEFT JOIN movement_perf mp ON mp.partner_id = pa.partner_id
LEFT JOIN removal_perf rp ON rp.partner_id = pa.partner_id
ORDER BY pa.region, pa.partner_name;

CREATE VIEW vw_exception_count_by_severity AS
SELECT
    severity,
    COUNT(*) AS exception_count,
    SUM(CASE WHEN closed_date IS NULL THEN 1 ELSE 0 END) AS open_exception_count
FROM exceptions
GROUP BY severity
ORDER BY
    CASE severity WHEN 'Critical' THEN 1 WHEN 'High' THEN 2 WHEN 'Medium' THEN 3 WHEN 'Low' THEN 4 ELSE 5 END;

CREATE VIEW vw_po_tracker AS
SELECT
    po.po_id,
    po.region,
    po.partner_id,
    pa.partner_name,
    pa.partner_type,
    po.po_type,
    po.amount,
    po.currency,
    po.created_date,
    po.approved_date,
    ROUND(CASE WHEN po.approved_date IS NOT NULL THEN julianday(po.approved_date) - julianday(po.created_date) END, 1) AS approval_cycle_days,
    po.approval_status,
    po.accounting_status,
    po.linked_movement_id,
    im.status AS movement_status,
    os.site_name AS origin_site_name,
    ds.site_name AS destination_site_name
FROM purchase_orders po
JOIN partners pa ON pa.partner_id = po.partner_id
LEFT JOIN inventory_movements im ON im.movement_id = po.linked_movement_id
LEFT JOIN sites os ON os.site_id = im.origin_site
LEFT JOIN sites ds ON ds.site_id = im.destination_site
ORDER BY po.created_date DESC;

CREATE VIEW vw_overdue_removals AS
WITH params AS (
    SELECT value AS as_of_date FROM run_metadata WHERE key = 'as_of_date'
)
SELECT
    r.removal_id,
    s.region,
    s.site_id,
    s.site_name,
    pa.partner_name,
    r.sku,
    p.category,
    r.quantity,
    r.reason_code,
    r.created_date,
    r.approved_date,
    r.status,
    pa.sla_days,
    ROUND(julianday((SELECT as_of_date FROM params)) - julianday(r.created_date), 1) AS age_days,
    ROUND(julianday((SELECT as_of_date FROM params)) - julianday(r.created_date) - pa.sla_days, 1) AS days_past_sla
FROM scrap_removal_requests r
JOIN sites s ON s.site_id = r.site_id
JOIN partners pa ON pa.partner_id = r.partner_id
JOIN products p ON p.sku = r.sku
WHERE r.status NOT IN ('Removed', 'Canceled')
  AND julianday((SELECT as_of_date FROM params)) - julianday(r.created_date) > pa.sla_days
ORDER BY days_past_sla DESC;

CREATE VIEW vw_delayed_pos AS
SELECT *
FROM vw_po_tracker
WHERE approval_status IN ('Pending', 'Delayed')
   OR accounting_status IN ('Disputed', 'Accrual Needed')
ORDER BY created_date;
