DROP VIEW IF EXISTS vw_reconciliation_row_counts;
DROP VIEW IF EXISTS vw_reconciliation_quantity_totals;
DROP VIEW IF EXISTS vw_reconciliation_financials;

CREATE VIEW vw_reconciliation_row_counts AS
SELECT 'sites' AS entity, (SELECT COUNT(*) FROM stg_sites) AS raw_rows, (SELECT COUNT(*) FROM sites) AS clean_rows
UNION ALL SELECT 'partners', (SELECT COUNT(*) FROM stg_partners), (SELECT COUNT(*) FROM partners)
UNION ALL SELECT 'products', (SELECT COUNT(*) FROM stg_products), (SELECT COUNT(*) FROM products)
UNION ALL SELECT 'inventory_movements', (SELECT COUNT(*) FROM stg_inventory_movements), (SELECT COUNT(*) FROM inventory_movements)
UNION ALL SELECT 'purchase_orders', (SELECT COUNT(*) FROM stg_purchase_orders), (SELECT COUNT(*) FROM purchase_orders)
UNION ALL SELECT 'truck_schedules', (SELECT COUNT(*) FROM stg_truck_schedules), (SELECT COUNT(*) FROM truck_schedules)
UNION ALL SELECT 'scrap_removal_requests', (SELECT COUNT(*) FROM stg_scrap_removal_requests), (SELECT COUNT(*) FROM scrap_removal_requests)
UNION ALL SELECT 'material_requests', (SELECT COUNT(*) FROM stg_material_requests), (SELECT COUNT(*) FROM material_requests)
UNION ALL SELECT 'exceptions', (SELECT COUNT(*) FROM stg_exceptions), (SELECT COUNT(*) FROM exceptions);

CREATE VIEW vw_reconciliation_quantity_totals AS
SELECT
    'inventory_movements' AS entity,
    (SELECT COALESCE(SUM(CAST(quantity AS INTEGER)), 0) FROM stg_inventory_movements) AS raw_quantity,
    (SELECT COALESCE(SUM(quantity), 0) FROM inventory_movements) AS clean_quantity
UNION ALL
SELECT
    'scrap_removal_requests',
    (SELECT COALESCE(SUM(CAST(quantity AS INTEGER)), 0) FROM stg_scrap_removal_requests),
    (SELECT COALESCE(SUM(quantity), 0) FROM scrap_removal_requests)
UNION ALL
SELECT
    'material_requests',
    (SELECT COALESCE(SUM(CAST(quantity AS INTEGER)), 0) FROM stg_material_requests),
    (SELECT COALESCE(SUM(COALESCE(quantity, 0)), 0) FROM material_requests);

CREATE VIEW vw_reconciliation_financials AS
SELECT
    'purchase_orders' AS entity,
    ROUND((SELECT COALESCE(SUM(CAST(amount AS REAL)), 0) FROM stg_purchase_orders), 2) AS raw_amount,
    ROUND((SELECT COALESCE(SUM(amount), 0) FROM purchase_orders), 2) AS clean_amount,
    ROUND(
        (SELECT COALESCE(SUM(CAST(amount AS REAL)), 0) FROM stg_purchase_orders)
        - (SELECT COALESCE(SUM(amount), 0) FROM purchase_orders),
        2
    ) AS excluded_amount;

