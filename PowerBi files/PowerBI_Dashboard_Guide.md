# Power BI Dashboard — Build Guide
## E-Commerce Q3 2024 Revenue & Satisfaction Dip Analysis

This turns the SQL insight ("delivery delays caused the Q3 2024 revenue and
satisfaction drop") into a Power BI dashboard. Import `ecommerce_powerbi_model.xlsx`
— it has 4 sheets, already structured as a star schema.

---

## 1. Import & Data Model

**File → Get Data → Excel Workbook →** select `ecommerce_powerbi_model.xlsx` →
check all 4 tables → Load.

### Star schema — set these relationships in Model view

```
                dim_customers
                      |
                      | customer_id (1 → *)
                      |
dim_products ---- fact_order_items ---- dim_date
 product_id (1→*)        |          order_date (1→*)
                          |
                    (order_date on fact
                     matches date on dim_date)
```

| From | To | Cardinality | Cross-filter |
|---|---|---|---|
| `dim_customers[customer_id]` | `fact_order_items[customer_id]` | 1 → Many | Single |
| `dim_products[product_id]` | `fact_order_items[product_id]` | 1 → Many | Single |
| `dim_date[date]` | `fact_order_items[order_date]` | 1 → Many | Single |

**Important:** in `dim_date`, mark it as a **Date Table** (Table tools → Mark as
Date Table → pick the `date` column) so time intelligence functions work correctly.

**Table roles:**
- `fact_order_items` — one row per product line item (8,000 rows) — your measures live here
- `dim_customers` — one row per customer, includes **pre-built RFM segment** (`customer_segment`)
- `dim_products` — product catalog with category
- `dim_date` — calendar table for clean month/quarter slicing

---

## 2. DAX Measures to Create

Create a new **Measures table** (Model view → New Table → name it `_Measures`,
formula `= {BLANK()}` just to hold them) so they don't clutter `fact_order_items`.

```dax
Total Revenue =
SUM(fact_order_items[line_revenue])

Total Orders =
DISTINCTCOUNT(fact_order_items[order_id])

Avg Order Value =
DIVIDE([Total Revenue], [Total Orders])

Avg Review Score =
AVERAGE(fact_order_items[review_score])

Delayed Orders % =
DIVIDE(
    CALCULATE(DISTINCTCOUNT(fact_order_items[order_id]), fact_order_items[delay_days] > 3),
    [Total Orders]
)

MoM Revenue Growth % =
VAR CurrMonth = [Total Revenue]
VAR PrevMonth =
    CALCULATE(
        [Total Revenue],
        DATEADD(dim_date[date], -1, MONTH)
    )
RETURN
    DIVIDE(CurrMonth - PrevMonth, PrevMonth)

Champions Count =
CALCULATE(
    DISTINCTCOUNT(dim_customers[customer_id]),
    dim_customers[customer_segment] = "Champions"
)

At Risk Count =
CALCULATE(
    DISTINCTCOUNT(dim_customers[customer_id]),
    dim_customers[customer_segment] = "At Risk (was loyal)"
)
```

---

## 3. Suggested Dashboard Pages

### Page 1 — Executive Overview
- **KPI cards (top row):** `Total Revenue`, `Total Orders`, `Avg Review Score`, `MoM Revenue Growth %`
- **Line chart:** `Total Revenue` by `dim_date[year_month]` — this is the visual that shows the Q3 2024 cliff at a glance
- **Slicer:** `dim_date[quarter]` and `dim_products[category]`

### Page 2 — Root Cause: Delivery Delay Impact
- **Clustered bar chart:** `Avg Review Score` by delay bucket (create a calculated column in `fact_order_items`: `delay_bucket = IF([delay_days]<=0, "On Time", IF([delay_days]<=3, "Slight Delay", "Major Delay"))`, then chart Avg Review Score by this)
- **Line chart:** `Delayed Orders %` by `year_month` — should spike visibly in Jul–Sep 2024
- **Scatter plot:** `delay_days` (x-axis) vs `review_score` (y-axis) — shows the correlation directly, point per order

### Page 3 — Product/Category Recovery Priority
- **Bar chart:** `Total Revenue` by `category`, split by `quarter` (Q2 2024 vs Q3 2024 side by side) — surfaces Electronics as the hardest-hit category
- **Table:** category, Q2 revenue, Q3 revenue, % change (use two measures with `CALCULATE` + date filters, or just build this with a matrix visual and quarter as columns)

### Page 4 — Customer Recovery Targets
- **Donut chart:** customer count by `customer_segment` (Champions / At Risk / Lost / New / Regular)
- **Table:** filtered to `customer_segment = "At Risk (was loyal)"`, sorted by `monetary` descending — this is your actionable win-back list
- **Card:** `At Risk Count` and sum of their `monetary` value (revenue at risk of churn)

---

## 4. Formatting tips
- Use a consistent color: red/orange for "Major Delay" and "At Risk", green for "On Time" and "Champions" — makes the story readable without reading labels
- Add a text box on Page 1: *"Q3 2024 delivery delays drove review scores from 4.4★ to 1.8★, cutting revenue ~50%"* — recruiters and reviewers often screenshot just this one line
- Pin Page 1 as the report's default landing page (File → Options → Report settings)

---

## Files in this package
- `ecommerce_powerbi_model.xlsx` — 4-sheet workbook, ready to import (fact + 3 dims)
- `fact_order_items.csv`, `dim_customers.csv`, `dim_products.csv`, `dim_date.csv` — same data as standalone CSVs, in case you prefer separate imports
- `PowerBI_Dashboard_Guide.md` — this file
