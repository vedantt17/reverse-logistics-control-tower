# KPI Snapshot

## Executive KPIs

| metric_name | metric_value | metric_unit | as_of_date |
| --- | --- | --- | --- |
| Total open inventory units | 134380.0 | units | 2026-05-22 |
| Average removal aging | 45.0 | days | 2026-05-22 |
| Scrap removal SLA breach rate | 73.9 | percent | 2026-05-22 |
| PO approval cycle time | 4.6 | days | 2026-05-22 |
| Open PO count | 277.0 | POs | 2026-05-22 |
| Truck on-time pickup rate | 14.3 | percent | 2026-05-22 |
| Truck on-time delivery rate | 10.7 | percent | 2026-05-22 |
| Material request fulfillment cycle time | 8.5 | days | 2026-05-22 |
| High-priority request backlog | 132.0 | requests | 2026-05-22 |
| At-risk inventory value | 22757237.75 | currency | 2026-05-22 |
| Backlog reduction opportunity | 87973.0 | units | 2026-05-22 |

## Top Backlog Sites

| region | site_id | site_name | site_type | open_movement_count | backlog_units | backlog_value | avg_age_days | delayed_or_hold_units |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Asia Pacific | S012 | Shenzhen Repair Hub | 1P Repair Hub | 72 | 11518 | 2170897.98 | 81.8 | 5271 |
| North America | S001 | Ridgeway Returns Center | 1P Returns Center | 93 | 10856 | 1860561.52 | 94.7 | 4814 |
| Asia Pacific | S013 | Singapore Partner Sort | 3P Processing Site | 91 | 10849 | 2147335.6 | 83.0 | 4178 |
| North America | S003 | Brampton Partner Sort | 3P Processing Site | 87 | 10830 | 1840558.37 | 94.7 | 5290 |
| North America | S005 | Dover Scrap Yard | Scrap Yard | 77 | 10381 | 2032869.63 | 82.1 | 5031 |
| North America | S002 | Lakemont Repair Hub | 1P Repair Hub | 86 | 9856 | 1879445.19 | 96.6 | 3734 |
| North America | S004 | Monterrey Recovery Node | 3P Processing Site | 76 | 9842 | 1699843.86 | 89.4 | 4122 |
| Asia Pacific | S011 | Osaka Returns Center | 1P Returns Center | 74 | 9110 | 1887406.38 | 86.0 | 4300 |
| Asia Pacific | S015 | Incheon Scrap Yard | Scrap Yard | 71 | 8872 | 1992113.87 | 86.6 | 2970 |
| Asia Pacific | S014 | Sydney Recovery Node | 3P Processing Site | 71 | 8559 | 1660886.53 | 101.0 | 2683 |

## Highest At-Risk SKUs

| sku | category | disposition_type | movement_count | at_risk_units | at_risk_value | oldest_age_days |
| --- | --- | --- | --- | --- | --- | --- |
| SKU-PHN-015 | Smartphone | Resell | 16 | 2312 | 1357028.4 | 156.0 |
| SKU-LPT-027 | Laptop | Repair | 17 | 1552 | 1276830.4 | 179.0 |
| SKU-LPT-004 | Laptop | Resell | 15 | 1234 | 996294.58 | 181.0 |
| SKU-LPT-073 | Laptop | Refurbish | 20 | 2222 | 947305.26 | 168.0 |
| SKU-PHN-075 | Smartphone | Resell | 16 | 1797 | 883207.53 | 185.0 |
| SKU-LPT-033 | Laptop | Refurbish | 13 | 1434 | 872689.38 | 184.0 |
| SKU-LPT-063 | Laptop | Refurbish | 12 | 1505 | 775210.45 | 176.0 |
| SKU-PHN-029 | Smartphone | Resell | 12 | 1267 | 752445.96 | 182.0 |
| SKU-PHN-070 | Smartphone | Refurbish | 15 | 1909 | 711121.59 | 157.0 |
| SKU-TAB-030 | Tablet | Refurbish | 14 | 1522 | 644430.02 | 170.0 |

## Sample Delayed PO Tracker

| po_id | region | partner_id | partner_name | partner_type | po_type | amount | currency | created_date | approved_date | approval_cycle_days | approval_status | accounting_status | linked_movement_id | movement_status | origin_site_name | destination_site_name |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| PO000334 | North America | P001 | Bluewater Refurbish | 3P Refurbisher | 3P Service Fee | 2593.62 | USD | 2025-11-20 | 2025-11-20 | 0.0 | Approved | Accrual Needed | MV000803 | Delivered | Ridgeway Returns Center | Brampton Partner Sort |
| PO000479 | Asia Pacific | P009 | Pacific Rim Freight | Carrier | Carrier Freight | 1444.23 | USD | 2025-11-22 | 2025-11-27 | 5.0 | Approved | Accrual Needed | MV001590 | Exception Hold | Singapore Partner Sort | Incheon Scrap Yard |
| PO000506 | Europe | P007 | RenewLoop Materials | Scrap Recycler | 3P Service Fee | 940.25 | EUR | 2025-11-24 | 2025-11-30 | 6.0 | Approved | Accrual Needed | MV000316 | Delivered | Birmingham Recovery Node | Hamburg Scrap Yard |
| PO000587 | Europe | P005 | Canal Refurb Europe | 3P Refurbisher | 3P Service Fee | 1212.59 | EUR | 2025-11-25 |  |  | Pending | Not Submitted | MV001515 | Delivered | Poznan Repair Hub | Rotterdam Returns Center |
| PO000600 | North America | P004 | Northstar Component Supply | Component Supplier | Component Procurement | 1678.59 | USD | 2025-11-25 |  |  | Delayed | Not Submitted | MV000607 | Exception Hold | Ridgeway Returns Center | Dover Scrap Yard |
| PO000595 | North America | P001 | Bluewater Refurbish | 3P Refurbisher | Carrier Freight | 6856.67 | USD | 2025-11-26 |  |  | Pending | Not Submitted | MV000439 | Canceled | Dover Scrap Yard | Monterrey Recovery Node |
| PO000302 | Asia Pacific | P009 | Pacific Rim Freight | Carrier | Component Procurement | 11544.8 | USD | 2025-11-28 |  |  | Pending | Submitted | MV000155 | Exception Hold | Incheon Scrap Yard | Shenzhen Repair Hub |
| PO000346 | North America | P003 | Greenline Recycling | Scrap Recycler | Scrap Removal | 11821.43 | USD | 2025-11-29 |  |  | Pending | Not Submitted | MV000914 | Canceled | Lakemont Repair Hub | Dover Scrap Yard |
| PO000099 | Asia Pacific | P009 | Pacific Rim Freight | Carrier | 3P Service Fee | 2197.41 | USD | 2025-12-01 | 2025-12-06 | 5.0 | Approved | Accrual Needed | MV000546 | Delivered | Shenzhen Repair Hub | Singapore Partner Sort |
| PO000048 | North America | P004 | Northstar Component Supply | Component Supplier | 3P Service Fee | 1046.21 | USD | 2025-12-02 |  |  | Pending | Not Submitted | MV001121 | Delayed | Monterrey Recovery Node | Dover Scrap Yard |
