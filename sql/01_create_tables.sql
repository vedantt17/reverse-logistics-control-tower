PRAGMA foreign_keys = ON;

DROP TABLE IF EXISTS data_quality_issues;
DROP TABLE IF EXISTS exceptions;
DROP TABLE IF EXISTS material_requests;
DROP TABLE IF EXISTS scrap_removal_requests;
DROP TABLE IF EXISTS truck_schedules;
DROP TABLE IF EXISTS purchase_orders;
DROP TABLE IF EXISTS inventory_movements;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS partners;
DROP TABLE IF EXISTS sites;
DROP TABLE IF EXISTS run_metadata;

DROP TABLE IF EXISTS stg_exceptions;
DROP TABLE IF EXISTS stg_material_requests;
DROP TABLE IF EXISTS stg_scrap_removal_requests;
DROP TABLE IF EXISTS stg_truck_schedules;
DROP TABLE IF EXISTS stg_purchase_orders;
DROP TABLE IF EXISTS stg_inventory_movements;
DROP TABLE IF EXISTS stg_products;
DROP TABLE IF EXISTS stg_partners;
DROP TABLE IF EXISTS stg_sites;

CREATE TABLE run_metadata (
    key TEXT PRIMARY KEY,
    value TEXT NOT NULL
);

CREATE TABLE stg_sites (
    site_id TEXT,
    site_name TEXT,
    region TEXT,
    country TEXT,
    site_type TEXT,
    timezone TEXT
);

CREATE TABLE stg_partners (
    partner_id TEXT,
    partner_name TEXT,
    partner_type TEXT,
    region TEXT,
    SLA_days INTEGER
);

CREATE TABLE stg_products (
    sku TEXT,
    category TEXT,
    disposition_type TEXT,
    unit_value REAL
);

CREATE TABLE stg_inventory_movements (
    movement_id TEXT,
    sku TEXT,
    origin_site TEXT,
    destination_site TEXT,
    partner_id TEXT,
    quantity INTEGER,
    movement_type TEXT,
    created_date TEXT,
    scheduled_ship_date TEXT,
    actual_ship_date TEXT,
    status TEXT
);

CREATE TABLE stg_purchase_orders (
    po_id TEXT,
    partner_id TEXT,
    region TEXT,
    po_type TEXT,
    amount REAL,
    currency TEXT,
    created_date TEXT,
    approved_date TEXT,
    approval_status TEXT,
    accounting_status TEXT,
    linked_movement_id TEXT
);

CREATE TABLE stg_truck_schedules (
    truck_id TEXT,
    linked_movement_id TEXT,
    carrier TEXT,
    origin_site TEXT,
    destination_site TEXT,
    scheduled_pickup TEXT,
    actual_pickup TEXT,
    scheduled_delivery TEXT,
    actual_delivery TEXT,
    truck_status TEXT
);

CREATE TABLE stg_scrap_removal_requests (
    removal_id TEXT,
    site_id TEXT,
    partner_id TEXT,
    sku TEXT,
    quantity INTEGER,
    reason_code TEXT,
    created_date TEXT,
    approved_date TEXT,
    removed_date TEXT,
    status TEXT
);

CREATE TABLE stg_material_requests (
    request_id TEXT,
    requester_team TEXT,
    site_id TEXT,
    sku TEXT,
    quantity INTEGER,
    priority TEXT,
    request_date TEXT,
    fulfilled_date TEXT,
    status TEXT
);

CREATE TABLE stg_exceptions (
    exception_id TEXT,
    related_entity_type TEXT,
    related_entity_id TEXT,
    exception_type TEXT,
    severity TEXT,
    opened_date TEXT,
    closed_date TEXT,
    owner TEXT
);

CREATE TABLE sites (
    site_id TEXT PRIMARY KEY,
    site_name TEXT NOT NULL,
    region TEXT NOT NULL,
    country TEXT NOT NULL,
    site_type TEXT NOT NULL,
    timezone TEXT NOT NULL
);

CREATE TABLE partners (
    partner_id TEXT PRIMARY KEY,
    partner_name TEXT NOT NULL,
    partner_type TEXT NOT NULL,
    region TEXT NOT NULL,
    sla_days INTEGER NOT NULL CHECK (sla_days > 0)
);

CREATE TABLE products (
    sku TEXT PRIMARY KEY,
    category TEXT NOT NULL,
    disposition_type TEXT NOT NULL,
    unit_value REAL NOT NULL CHECK (unit_value >= 0)
);

CREATE TABLE inventory_movements (
    movement_id TEXT PRIMARY KEY,
    sku TEXT NOT NULL,
    origin_site TEXT NOT NULL,
    destination_site TEXT NOT NULL,
    partner_id TEXT NOT NULL,
    quantity INTEGER NOT NULL CHECK (quantity >= 0),
    movement_type TEXT NOT NULL,
    created_date TEXT NOT NULL,
    scheduled_ship_date TEXT,
    actual_ship_date TEXT,
    status TEXT NOT NULL,
    FOREIGN KEY (sku) REFERENCES products(sku),
    FOREIGN KEY (origin_site) REFERENCES sites(site_id),
    FOREIGN KEY (destination_site) REFERENCES sites(site_id),
    FOREIGN KEY (partner_id) REFERENCES partners(partner_id)
);

CREATE TABLE purchase_orders (
    po_id TEXT PRIMARY KEY,
    partner_id TEXT NOT NULL,
    region TEXT NOT NULL,
    po_type TEXT NOT NULL,
    amount REAL NOT NULL CHECK (amount >= 0),
    currency TEXT NOT NULL,
    created_date TEXT NOT NULL,
    approved_date TEXT,
    approval_status TEXT NOT NULL,
    accounting_status TEXT NOT NULL,
    linked_movement_id TEXT,
    FOREIGN KEY (partner_id) REFERENCES partners(partner_id),
    FOREIGN KEY (linked_movement_id) REFERENCES inventory_movements(movement_id)
);

CREATE TABLE truck_schedules (
    truck_id TEXT PRIMARY KEY,
    linked_movement_id TEXT,
    carrier TEXT NOT NULL,
    origin_site TEXT NOT NULL,
    destination_site TEXT NOT NULL,
    scheduled_pickup TEXT NOT NULL,
    actual_pickup TEXT,
    scheduled_delivery TEXT NOT NULL,
    actual_delivery TEXT,
    truck_status TEXT NOT NULL,
    FOREIGN KEY (linked_movement_id) REFERENCES inventory_movements(movement_id),
    FOREIGN KEY (origin_site) REFERENCES sites(site_id),
    FOREIGN KEY (destination_site) REFERENCES sites(site_id)
);

CREATE TABLE scrap_removal_requests (
    removal_id TEXT PRIMARY KEY,
    site_id TEXT NOT NULL,
    partner_id TEXT NOT NULL,
    sku TEXT NOT NULL,
    quantity INTEGER NOT NULL CHECK (quantity >= 0),
    reason_code TEXT NOT NULL,
    created_date TEXT NOT NULL,
    approved_date TEXT,
    removed_date TEXT,
    status TEXT NOT NULL,
    FOREIGN KEY (site_id) REFERENCES sites(site_id),
    FOREIGN KEY (partner_id) REFERENCES partners(partner_id),
    FOREIGN KEY (sku) REFERENCES products(sku)
);

CREATE TABLE material_requests (
    request_id TEXT PRIMARY KEY,
    requester_team TEXT NOT NULL,
    site_id TEXT NOT NULL,
    sku TEXT NOT NULL,
    quantity INTEGER,
    priority TEXT NOT NULL,
    request_date TEXT NOT NULL,
    fulfilled_date TEXT,
    status TEXT NOT NULL,
    FOREIGN KEY (site_id) REFERENCES sites(site_id),
    FOREIGN KEY (sku) REFERENCES products(sku)
);

CREATE TABLE exceptions (
    exception_id TEXT PRIMARY KEY,
    related_entity_type TEXT NOT NULL,
    related_entity_id TEXT NOT NULL,
    exception_type TEXT NOT NULL,
    severity TEXT NOT NULL,
    opened_date TEXT NOT NULL,
    closed_date TEXT,
    owner TEXT NOT NULL
);

CREATE TABLE data_quality_issues (
    issue_key TEXT,
    related_entity_type TEXT,
    related_entity_id TEXT,
    issue_detail TEXT,
    severity TEXT,
    detected_at TEXT DEFAULT CURRENT_TIMESTAMP
);

