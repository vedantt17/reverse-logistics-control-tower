"""Synthetic data generator for the reverse logistics control tower."""

from __future__ import annotations

from dataclasses import dataclass
from typing import Any

import numpy as np
import pandas as pd

from src.config import RAW_DIR


REGIONS = ["North America", "Europe", "Asia Pacific"]


@dataclass(frozen=True)
class DateFormats:
    date_cols: tuple[str, ...] = ()
    datetime_cols: tuple[str, ...] = ()


def _random_date(rng: np.random.Generator, start: pd.Timestamp, end: pd.Timestamp) -> pd.Timestamp:
    days = max((end.normalize() - start.normalize()).days, 1)
    return start.normalize() + pd.Timedelta(days=int(rng.integers(0, days + 1)))


def _write_csv(df: pd.DataFrame, filename: str, formats: DateFormats | None = None) -> None:
    out = df.copy()
    formats = formats or DateFormats()

    for col in formats.date_cols:
        out[col] = pd.to_datetime(out[col], errors="coerce").dt.strftime("%Y-%m-%d")
    for col in formats.datetime_cols:
        out[col] = pd.to_datetime(out[col], errors="coerce").dt.strftime("%Y-%m-%d %H:%M:%S")

    out = out.replace({pd.NaT: None, np.nan: None})
    out.to_csv(RAW_DIR / filename, index=False)


def _choose_by_region(df: pd.DataFrame, region: str, rng: np.random.Generator) -> pd.Series:
    scoped = df[(df["region"] == region) | (df["region"] == "Global")]
    if scoped.empty:
        scoped = df
    return scoped.iloc[int(rng.integers(0, len(scoped)))]


def generate_sites() -> pd.DataFrame:
    sites = [
        ("S001", "Ridgeway Returns Center", "North America", "United States", "1P Returns Center", "America/Los_Angeles"),
        ("S002", "Lakemont Repair Hub", "North America", "United States", "1P Repair Hub", "America/Chicago"),
        ("S003", "Brampton Partner Sort", "North America", "Canada", "3P Processing Site", "America/Toronto"),
        ("S004", "Monterrey Recovery Node", "North America", "Mexico", "3P Processing Site", "America/Mexico_City"),
        ("S005", "Dover Scrap Yard", "North America", "United States", "Scrap Yard", "America/New_York"),
        ("S006", "Rotterdam Returns Center", "Europe", "Netherlands", "1P Returns Center", "Europe/Amsterdam"),
        ("S007", "Poznan Repair Hub", "Europe", "Poland", "1P Repair Hub", "Europe/Warsaw"),
        ("S008", "Lyon Partner Sort", "Europe", "France", "3P Processing Site", "Europe/Paris"),
        ("S009", "Birmingham Recovery Node", "Europe", "United Kingdom", "3P Processing Site", "Europe/London"),
        ("S010", "Hamburg Scrap Yard", "Europe", "Germany", "Scrap Yard", "Europe/Berlin"),
        ("S011", "Osaka Returns Center", "Asia Pacific", "Japan", "1P Returns Center", "Asia/Tokyo"),
        ("S012", "Shenzhen Repair Hub", "Asia Pacific", "China", "1P Repair Hub", "Asia/Shanghai"),
        ("S013", "Singapore Partner Sort", "Asia Pacific", "Singapore", "3P Processing Site", "Asia/Singapore"),
        ("S014", "Sydney Recovery Node", "Asia Pacific", "Australia", "3P Processing Site", "Australia/Sydney"),
        ("S015", "Incheon Scrap Yard", "Asia Pacific", "South Korea", "Scrap Yard", "Asia/Seoul"),
    ]
    return pd.DataFrame(sites, columns=["site_id", "site_name", "region", "country", "site_type", "timezone"])


def generate_partners() -> pd.DataFrame:
    partners = [
        ("P001", "Bluewater Refurbish", "3P Refurbisher", "North America", 10),
        ("P002", "Cobalt Freight Services", "Carrier", "North America", 4),
        ("P003", "Greenline Recycling", "Scrap Recycler", "North America", 14),
        ("P004", "Northstar Component Supply", "Component Supplier", "North America", 12),
        ("P005", "Canal Refurb Europe", "3P Refurbisher", "Europe", 12),
        ("P006", "Harborline Logistics EU", "Carrier", "Europe", 5),
        ("P007", "RenewLoop Materials", "Scrap Recycler", "Europe", 16),
        ("P008", "Kite Asia Repair", "3P Refurbisher", "Asia Pacific", 11),
        ("P009", "Pacific Rim Freight", "Carrier", "Asia Pacific", 6),
        ("P010", "CircuitCycle APAC", "Scrap Recycler", "Asia Pacific", 15),
        ("P011", "Atlas Service Desk", "Ops Support", "Global", 8),
    ]
    return pd.DataFrame(partners, columns=["partner_id", "partner_name", "partner_type", "region", "SLA_days"])


def generate_products(seed: int) -> pd.DataFrame:
    rng = np.random.default_rng(seed)
    category_specs = {
        "Smartphone": ("PHN", 410, 120),
        "Tablet": ("TAB", 330, 90),
        "Laptop": ("LPT", 760, 210),
        "Wearable": ("WRB", 155, 55),
        "Audio": ("AUD", 95, 35),
        "Gaming": ("GMG", 285, 80),
        "Home Device": ("HOM", 135, 45),
        "Component": ("CMP", 48, 22),
    }
    category_weights = np.array([0.19, 0.13, 0.12, 0.13, 0.14, 0.09, 0.11, 0.09])
    disposition_types = ["Refurbish", "Repair", "Resell", "Recycle", "Scrap"]
    disposition_weights = np.array([0.31, 0.22, 0.19, 0.18, 0.10])

    records: list[dict[str, Any]] = []
    categories = list(category_specs.keys())
    for idx in range(1, 76):
        category = str(rng.choice(categories, p=category_weights))
        prefix, mean_value, sd_value = category_specs[category]
        disposition = str(rng.choice(disposition_types, p=disposition_weights))
        value_multiplier = {
            "Resell": 1.10,
            "Refurbish": 0.82,
            "Repair": 0.70,
            "Recycle": 0.22,
            "Scrap": 0.09,
        }[disposition]
        unit_value = max(5.0, rng.normal(mean_value, sd_value) * value_multiplier)
        records.append(
            {
                "sku": f"SKU-{prefix}-{idx:03d}",
                "category": category,
                "disposition_type": disposition,
                "unit_value": round(float(unit_value), 2),
            }
        )
    return pd.DataFrame(records)


def generate_inventory_movements(
    sites: pd.DataFrame,
    partners: pd.DataFrame,
    products: pd.DataFrame,
    seed: int,
    as_of_date: str,
    n: int = 2250,
) -> pd.DataFrame:
    rng = np.random.default_rng(seed + 10)
    as_of = pd.Timestamp(as_of_date)
    start = as_of - pd.Timedelta(days=185)

    movement_types = [
        "Return Transfer",
        "Refurbishment Transfer",
        "Repair Dispatch",
        "Disposal Transfer",
        "Inter-site Rebalance",
    ]
    movement_weights = np.array([0.31, 0.24, 0.18, 0.17, 0.10])
    status_values = ["Created", "Scheduled", "In Transit", "Delivered", "Delayed", "Canceled", "Exception Hold"]
    status_weights_base = np.array([0.06, 0.13, 0.15, 0.45, 0.13, 0.04, 0.04])
    status_weights_spike = np.array([0.08, 0.14, 0.16, 0.27, 0.22, 0.04, 0.09])

    records: list[dict[str, Any]] = []
    site_ids = sites["site_id"].to_numpy()
    skus = products["sku"].to_numpy()
    site_by_id = sites.set_index("site_id")

    for idx in range(1, n + 1):
        origin_id = str(rng.choice(site_ids))
        origin = site_by_id.loc[origin_id]
        region = origin["region"]
        possible_destinations = sites[sites["site_id"] != origin_id]
        movement_type = str(rng.choice(movement_types, p=movement_weights))

        if movement_type == "Disposal Transfer":
            scoped_destinations = possible_destinations[
                (possible_destinations["region"] == region) & possible_destinations["site_type"].str.contains("Scrap")
            ]
            if scoped_destinations.empty:
                scoped_destinations = possible_destinations[possible_destinations["site_type"].str.contains("Scrap")]
        elif movement_type in {"Refurbishment Transfer", "Repair Dispatch"}:
            scoped_destinations = possible_destinations[
                (possible_destinations["region"] == region) & possible_destinations["site_type"].str.contains("Repair|Processing", regex=True)
            ]
            if scoped_destinations.empty:
                scoped_destinations = possible_destinations
        else:
            scoped_destinations = possible_destinations[possible_destinations["region"] == region]
            if scoped_destinations.empty:
                scoped_destinations = possible_destinations

        destination_id = str(scoped_destinations.iloc[int(rng.integers(0, len(scoped_destinations)))]["site_id"])
        partner = _choose_by_region(partners, region, rng)
        sku = str(rng.choice(skus))
        created_date = _random_date(rng, start, as_of - pd.Timedelta(days=1))
        scheduled_ship_date = created_date + pd.Timedelta(days=int(rng.integers(1, 10)))

        spike_window = created_date >= as_of - pd.Timedelta(days=70)
        spike_region = region in {"North America", "Asia Pacific"}
        status_weights = status_weights_spike if spike_window and spike_region and rng.random() < 0.55 else status_weights_base
        status = str(rng.choice(status_values, p=status_weights))

        base_quantity = int(rng.integers(5, 180))
        if spike_window and spike_region:
            base_quantity = int(base_quantity * rng.uniform(1.35, 2.7))

        actual_ship_date: pd.Timestamp | None
        if status == "Delivered":
            actual_ship_date = scheduled_ship_date + pd.Timedelta(days=int(rng.integers(-1, 5)))
        elif status == "In Transit":
            actual_ship_date = scheduled_ship_date + pd.Timedelta(days=int(rng.integers(-1, 3)))
        elif status == "Delayed":
            actual_ship_date = (
                scheduled_ship_date + pd.Timedelta(days=int(rng.integers(4, 18))) if rng.random() < 0.47 else None
            )
        elif status == "Exception Hold":
            actual_ship_date = scheduled_ship_date + pd.Timedelta(days=int(rng.integers(2, 14))) if rng.random() < 0.25 else None
        else:
            actual_ship_date = None

        records.append(
            {
                "movement_id": f"MV{idx:06d}",
                "sku": sku,
                "origin_site": origin_id,
                "destination_site": destination_id,
                "partner_id": partner["partner_id"],
                "quantity": base_quantity,
                "movement_type": movement_type,
                "created_date": created_date,
                "scheduled_ship_date": scheduled_ship_date,
                "actual_ship_date": actual_ship_date,
                "status": status,
            }
        )

    df = pd.DataFrame(records)

    bad_indices = rng.choice(df.index.to_numpy(), size=26, replace=False)
    df.loc[bad_indices[:7], "origin_site"] = "S999"
    df.loc[bad_indices[7:14], "destination_site"] = "S998"
    df.loc[bad_indices[14:21], "partner_id"] = "P999"
    df.loc[bad_indices[21:], "sku"] = "SKU-MISSING"

    duplicate_rows = df.sample(14, random_state=seed + 15).copy()
    duplicate_rows["quantity"] = duplicate_rows["quantity"].astype(int) + rng.integers(3, 25, size=len(duplicate_rows))
    duplicate_rows["status"] = "Exception Hold"
    df = pd.concat([df, duplicate_rows], ignore_index=True)
    return df


def generate_purchase_orders(
    sites: pd.DataFrame,
    partners: pd.DataFrame,
    products: pd.DataFrame,
    movements: pd.DataFrame,
    seed: int,
    as_of_date: str,
    n: int = 640,
) -> pd.DataFrame:
    rng = np.random.default_rng(seed + 20)
    as_of = pd.Timestamp(as_of_date)
    products_by_sku = products.set_index("sku")
    sites_by_id = sites.set_index("site_id")
    valid_movements = movements[
        movements["origin_site"].isin(sites["site_id"])
        & movements["destination_site"].isin(sites["site_id"])
        & movements["partner_id"].isin(partners["partner_id"])
        & movements["sku"].isin(products["sku"])
    ].drop_duplicates("movement_id")
    movement_rows = valid_movements.to_dict("records")
    currency_by_region = {"North America": "USD", "Europe": "EUR", "Asia Pacific": "USD"}
    po_types = ["3P Service Fee", "Carrier Freight", "Refurbishment Labor", "Scrap Removal", "Component Procurement"]
    approval_statuses = ["Approved", "Pending", "Delayed", "Rejected", "Canceled"]
    approval_weights = np.array([0.68, 0.13, 0.10, 0.05, 0.04])

    records: list[dict[str, Any]] = []
    for idx in range(1, n + 1):
        linked_movement = movement_rows[int(rng.integers(0, len(movement_rows)))] if rng.random() < 0.88 else None
        if linked_movement:
            partner_id = linked_movement["partner_id"]
            origin = sites_by_id.loc[linked_movement["origin_site"]]
            region = origin["region"]
            quantity = float(linked_movement["quantity"])
            unit_value = float(products_by_sku.loc[linked_movement["sku"], "unit_value"])
            amount = quantity * unit_value * rng.uniform(0.06, 0.28) + rng.uniform(175, 2400)
            created_date = pd.Timestamp(linked_movement["created_date"]) + pd.Timedelta(days=int(rng.integers(-2, 5)))
            linked_movement_id = linked_movement["movement_id"]
        else:
            partner = partners.iloc[int(rng.integers(0, len(partners)))]
            partner_id = partner["partner_id"]
            region = partner["region"] if partner["region"] != "Global" else str(rng.choice(REGIONS))
            amount = rng.uniform(900, 42000)
            created_date = _random_date(rng, as_of - pd.Timedelta(days=180), as_of - pd.Timedelta(days=1))
            linked_movement_id = None

        created_date = max(created_date, as_of - pd.Timedelta(days=185))
        approval_status = str(rng.choice(approval_statuses, p=approval_weights))
        if approval_status == "Approved":
            approved_date = created_date + pd.Timedelta(days=int(rng.integers(0, 9)))
        elif approval_status == "Delayed" and rng.random() < 0.35:
            approved_date = created_date + pd.Timedelta(days=int(rng.integers(10, 24)))
        else:
            approved_date = None

        if approval_status in {"Approved", "Delayed"} and approved_date is not None:
            accounting_status = str(rng.choice(["Submitted", "Cleared", "Accrual Needed", "Disputed"], p=[0.28, 0.45, 0.19, 0.08]))
        else:
            accounting_status = str(rng.choice(["Not Submitted", "Submitted", "Disputed"], p=[0.72, 0.20, 0.08]))

        records.append(
            {
                "po_id": f"PO{idx:06d}",
                "partner_id": partner_id,
                "region": region,
                "po_type": str(rng.choice(po_types)),
                "amount": round(float(amount), 2),
                "currency": currency_by_region[region],
                "created_date": created_date,
                "approved_date": approved_date,
                "approval_status": approval_status,
                "accounting_status": accounting_status,
                "linked_movement_id": linked_movement_id,
            }
        )

    df = pd.DataFrame(records)

    missing_indices = rng.choice(df.index.to_numpy(), size=18, replace=False)
    for offset, idx in enumerate(missing_indices, start=1):
        df.loc[idx, "linked_movement_id"] = f"MV-MISSING-{offset:03d}"
        df.loc[idx, "approval_status"] = "Delayed"

    duplicate_rows = df.sample(9, random_state=seed + 21).copy()
    duplicate_rows["amount"] = (duplicate_rows["amount"].astype(float) * rng.uniform(0.92, 1.13, size=len(duplicate_rows))).round(2)
    duplicate_rows["accounting_status"] = "Disputed"
    df = pd.concat([df, duplicate_rows], ignore_index=True)
    return df


def generate_truck_schedules(
    sites: pd.DataFrame,
    movements: pd.DataFrame,
    purchase_orders: pd.DataFrame,
    seed: int,
    n: int = 930,
) -> pd.DataFrame:
    rng = np.random.default_rng(seed + 30)
    valid_movements = movements[
        movements["origin_site"].isin(sites["site_id"]) & movements["destination_site"].isin(sites["site_id"])
    ].drop_duplicates("movement_id")
    movement_rows = valid_movements.to_dict("records")
    carriers = ["Cobalt Freight Services", "Harborline Logistics", "Pacific Rim Freight", "Delta Route", "Summit Carrier"]
    statuses = ["Completed", "In Transit", "Delayed", "Scheduled", "Canceled"]
    status_weights = np.array([0.52, 0.15, 0.18, 0.09, 0.06])
    records: list[dict[str, Any]] = []

    for idx in range(1, n + 1):
        movement = movement_rows[int(rng.integers(0, len(movement_rows)))]
        scheduled_pickup = (
            pd.Timestamp(movement["scheduled_ship_date"])
            + pd.Timedelta(hours=int(rng.integers(6, 19)))
            + pd.Timedelta(days=int(rng.integers(-1, 2)))
        )
        transit_days = int(rng.integers(1, 7))
        scheduled_delivery = scheduled_pickup + pd.Timedelta(days=transit_days, hours=int(rng.integers(2, 14)))
        truck_status = str(rng.choice(statuses, p=status_weights))

        if truck_status == "Completed":
            actual_pickup = scheduled_pickup + pd.Timedelta(hours=int(rng.integers(-2, 18)))
            actual_delivery = scheduled_delivery + pd.Timedelta(hours=int(rng.integers(-4, 36)))
        elif truck_status == "In Transit":
            actual_pickup = scheduled_pickup + pd.Timedelta(hours=int(rng.integers(-2, 28)))
            actual_delivery = None
        elif truck_status == "Delayed":
            actual_pickup = (
                scheduled_pickup + pd.Timedelta(hours=int(rng.integers(8, 72))) if rng.random() < 0.72 else None
            )
            actual_delivery = (
                scheduled_delivery + pd.Timedelta(hours=int(rng.integers(12, 96))) if rng.random() < 0.28 else None
            )
        else:
            actual_pickup = None
            actual_delivery = None

        records.append(
            {
                "truck_id": f"TRK{idx:06d}",
                "linked_movement_id": movement["movement_id"],
                "carrier": str(rng.choice(carriers)),
                "origin_site": movement["origin_site"],
                "destination_site": movement["destination_site"],
                "scheduled_pickup": scheduled_pickup,
                "actual_pickup": actual_pickup,
                "scheduled_delivery": scheduled_delivery,
                "actual_delivery": actual_delivery,
                "truck_status": truck_status,
            }
        )

    df = pd.DataFrame(records)

    anomaly_indices = df[df["actual_pickup"].notna()].sample(18, random_state=seed + 31).index
    df.loc[anomaly_indices, "actual_pickup"] = df.loc[anomaly_indices, "scheduled_pickup"] - pd.to_timedelta(
        rng.integers(2, 13, size=len(anomaly_indices)), unit="h"
    )

    approved_pos = purchase_orders[purchase_orders["approved_date"].notna() & purchase_orders["linked_movement_id"].notna()]
    po_by_movement = approved_pos.drop_duplicates("linked_movement_id").set_index("linked_movement_id")
    candidate_rows = df[df["linked_movement_id"].isin(po_by_movement.index)].sample(22, random_state=seed + 32).index
    for idx in candidate_rows:
        approved_date = pd.Timestamp(po_by_movement.loc[df.loc[idx, "linked_movement_id"], "approved_date"])
        df.loc[idx, "scheduled_pickup"] = approved_date - pd.Timedelta(days=int(rng.integers(1, 4)))
        df.loc[idx, "scheduled_delivery"] = df.loc[idx, "scheduled_pickup"] + pd.Timedelta(days=int(rng.integers(1, 5)))
        if pd.notna(df.loc[idx, "actual_pickup"]):
            df.loc[idx, "actual_pickup"] = df.loc[idx, "scheduled_pickup"] + pd.Timedelta(hours=int(rng.integers(1, 18)))

    return df


def generate_scrap_removal_requests(
    sites: pd.DataFrame,
    partners: pd.DataFrame,
    products: pd.DataFrame,
    seed: int,
    as_of_date: str,
    n: int = 840,
) -> pd.DataFrame:
    rng = np.random.default_rng(seed + 40)
    as_of = pd.Timestamp(as_of_date)
    scrap_partners = partners[partners["partner_type"].isin(["Scrap Recycler", "3P Refurbisher"])].copy()
    reason_codes = ["Damaged Beyond Repair", "Battery Swell", "Obsolete Component", "Compliance Hold", "Return Fraud", "Liquidation Lot"]
    statuses = ["Requested", "Approved", "Removed", "Overdue", "Canceled", "Hold"]
    status_weights = np.array([0.12, 0.18, 0.45, 0.14, 0.05, 0.06])
    records: list[dict[str, Any]] = []

    for idx in range(1, n + 1):
        site = sites.iloc[int(rng.integers(0, len(sites)))]
        partner = _choose_by_region(scrap_partners, site["region"], rng)
        created_date = _random_date(rng, as_of - pd.Timedelta(days=180), as_of - pd.Timedelta(days=1))
        status = str(rng.choice(statuses, p=status_weights))
        if status == "Overdue":
            created_date = as_of - pd.Timedelta(days=int(partner["SLA_days"]) + int(rng.integers(5, 55)))

        approved_date = None
        removed_date = None
        if status in {"Approved", "Removed", "Overdue", "Hold"}:
            approved_date = created_date + pd.Timedelta(days=int(rng.integers(0, 6)))
        if status == "Removed":
            cycle_days = int(rng.integers(2, int(partner["SLA_days"]) + 10))
            removed_date = approved_date + pd.Timedelta(days=cycle_days) if approved_date is not None else created_date + pd.Timedelta(days=cycle_days)

        records.append(
            {
                "removal_id": f"REM{idx:06d}",
                "site_id": site["site_id"],
                "partner_id": partner["partner_id"],
                "sku": str(rng.choice(products["sku"].to_numpy())),
                "quantity": int(rng.integers(2, 260)),
                "reason_code": str(rng.choice(reason_codes)),
                "created_date": created_date,
                "approved_date": approved_date,
                "removed_date": removed_date,
                "status": status,
            }
        )

    df = pd.DataFrame(records)
    closed_missing = df[df["status"] == "Removed"].sample(16, random_state=seed + 41).index
    df.loc[closed_missing, "removed_date"] = None
    return df


def generate_material_requests(
    sites: pd.DataFrame,
    products: pd.DataFrame,
    seed: int,
    as_of_date: str,
    n: int = 720,
) -> pd.DataFrame:
    rng = np.random.default_rng(seed + 50)
    as_of = pd.Timestamp(as_of_date)
    requester_teams = ["Returns Ops", "Materials Planning", "Repair Engineering", "3P Partner Desk", "Finance Ops", "Inventory Control"]
    priorities = ["Critical", "High", "Medium", "Low"]
    priority_weights = np.array([0.10, 0.27, 0.43, 0.20])
    statuses = ["Open", "In Progress", "Fulfilled", "Backordered", "Canceled"]
    status_weights = np.array([0.16, 0.18, 0.49, 0.11, 0.06])
    records: list[dict[str, Any]] = []

    for idx in range(1, n + 1):
        site = sites.iloc[int(rng.integers(0, len(sites)))]
        request_date = _random_date(rng, as_of - pd.Timedelta(days=175), as_of - pd.Timedelta(days=1))
        priority = str(rng.choice(priorities, p=priority_weights))
        status = str(rng.choice(statuses, p=status_weights))

        if priority in {"Critical", "High"} and request_date > as_of - pd.Timedelta(days=75) and rng.random() < 0.28:
            status = str(rng.choice(["Open", "Backordered", "In Progress"], p=[0.45, 0.35, 0.20]))

        fulfilled_date = None
        if status == "Fulfilled":
            base_days = {"Critical": 3, "High": 5, "Medium": 9, "Low": 14}[priority]
            fulfilled_date = request_date + pd.Timedelta(days=int(rng.integers(1, base_days + 8)))

        records.append(
            {
                "request_id": f"REQ{idx:06d}",
                "requester_team": str(rng.choice(requester_teams)),
                "site_id": site["site_id"],
                "sku": str(rng.choice(products["sku"].to_numpy())),
                "quantity": int(rng.integers(1, 170)),
                "priority": priority,
                "request_date": request_date,
                "fulfilled_date": fulfilled_date,
                "status": status,
            }
        )

    df = pd.DataFrame(records)
    bad_qty_idx = df[df["status"] == "Fulfilled"].sample(13, random_state=seed + 51).index
    half = len(bad_qty_idx) // 2
    df.loc[bad_qty_idx[:half], "quantity"] = 0
    df.loc[bad_qty_idx[half:], "quantity"] = None
    return df


def generate_exceptions(
    movements: pd.DataFrame,
    purchase_orders: pd.DataFrame,
    trucks: pd.DataFrame,
    removals: pd.DataFrame,
    material_requests: pd.DataFrame,
    seed: int,
    as_of_date: str,
    n: int = 430,
) -> pd.DataFrame:
    rng = np.random.default_rng(seed + 60)
    as_of = pd.Timestamp(as_of_date)
    entity_sources = {
        "inventory_movement": movements["movement_id"].drop_duplicates().to_numpy(),
        "purchase_order": purchase_orders["po_id"].drop_duplicates().to_numpy(),
        "truck_schedule": trucks["truck_id"].drop_duplicates().to_numpy(),
        "scrap_removal": removals["removal_id"].drop_duplicates().to_numpy(),
        "material_request": material_requests["request_id"].drop_duplicates().to_numpy(),
    }
    entity_types = list(entity_sources.keys())
    entity_weights = np.array([0.32, 0.19, 0.18, 0.18, 0.13])
    exception_types = [
        "PO Approval Delay",
        "Carrier No Show",
        "Missing Scan",
        "Inventory Mismatch",
        "Partner Capacity",
        "Regulatory Hold",
        "Overdue Removal",
        "Data Quality Defect",
        "Site Congestion",
    ]
    severities = ["Critical", "High", "Medium", "Low"]
    severity_weights = np.array([0.08, 0.26, 0.43, 0.23])
    owners = ["Regional Ops", "Partner Management", "Transportation", "Finance Ops", "Inventory Control", "Materials Desk"]

    records: list[dict[str, Any]] = []
    for idx in range(1, n + 1):
        entity_type = str(rng.choice(entity_types, p=entity_weights))
        related_id = str(rng.choice(entity_sources[entity_type]))
        opened_date = _random_date(rng, as_of - pd.Timedelta(days=160), as_of - pd.Timedelta(days=1))
        severity = str(rng.choice(severities, p=severity_weights))

        close_probability = {"Critical": 0.50, "High": 0.58, "Medium": 0.67, "Low": 0.75}[severity]
        closed_date = None
        if rng.random() < close_probability:
            closed_date = opened_date + pd.Timedelta(days=int(rng.integers(1, 24)))
            if closed_date > as_of:
                closed_date = None

        records.append(
            {
                "exception_id": f"EXC{idx:06d}",
                "related_entity_type": entity_type,
                "related_entity_id": related_id,
                "exception_type": str(rng.choice(exception_types)),
                "severity": severity,
                "opened_date": opened_date,
                "closed_date": closed_date,
                "owner": str(rng.choice(owners)),
            }
        )
    return pd.DataFrame(records)


def generate_raw_data(seed: int, as_of_date: str) -> dict[str, int]:
    """Generate all raw CSVs and return row counts."""

    RAW_DIR.mkdir(parents=True, exist_ok=True)

    sites = generate_sites()
    partners = generate_partners()
    products = generate_products(seed)
    movements = generate_inventory_movements(sites, partners, products, seed, as_of_date)
    purchase_orders = generate_purchase_orders(sites, partners, products, movements, seed, as_of_date)
    trucks = generate_truck_schedules(sites, movements, purchase_orders, seed)
    removals = generate_scrap_removal_requests(sites, partners, products, seed, as_of_date)
    material_requests = generate_material_requests(sites, products, seed, as_of_date)
    exceptions = generate_exceptions(movements, purchase_orders, trucks, removals, material_requests, seed, as_of_date)

    _write_csv(sites, "sites.csv")
    _write_csv(partners, "partners.csv")
    _write_csv(products, "products.csv")
    _write_csv(
        movements,
        "inventory_movements.csv",
        DateFormats(date_cols=("created_date", "scheduled_ship_date", "actual_ship_date")),
    )
    _write_csv(
        purchase_orders,
        "purchase_orders.csv",
        DateFormats(date_cols=("created_date", "approved_date")),
    )
    _write_csv(
        trucks,
        "truck_schedules.csv",
        DateFormats(datetime_cols=("scheduled_pickup", "actual_pickup", "scheduled_delivery", "actual_delivery")),
    )
    _write_csv(
        removals,
        "scrap_removal_requests.csv",
        DateFormats(date_cols=("created_date", "approved_date", "removed_date")),
    )
    _write_csv(
        material_requests,
        "material_requests.csv",
        DateFormats(date_cols=("request_date", "fulfilled_date")),
    )
    _write_csv(
        exceptions,
        "exceptions.csv",
        DateFormats(date_cols=("opened_date", "closed_date")),
    )

    return {
        "sites": len(sites),
        "partners": len(partners),
        "products": len(products),
        "inventory_movements": len(movements),
        "purchase_orders": len(purchase_orders),
        "truck_schedules": len(trucks),
        "scrap_removal_requests": len(removals),
        "material_requests": len(material_requests),
        "exceptions": len(exceptions),
    }

