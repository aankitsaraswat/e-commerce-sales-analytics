# E-Commerce Sales & Customer Analytics (SQL Portfolio Project)

## Business Context
An Indian e-commerce retailer wants to understand why **revenue and customer
satisfaction dropped sharply in Q3 2024**, and which customers/products to
prioritize for the recovery. This project uses SQL to investigate the drop,
diagnose the root cause, and recommend where to focus retention efforts.

## Dataset
Synthetic but realistic relational dataset, 6 tables, ~21K total rows:

| Table         | Rows  | Description                                   |
|---------------|-------|------------------------------------------------|
| customers     | 1,600 | Customer profile, city, signup date, segment  |
| products      | 240   | Product catalog across 8 categories           |
| orders        | 4,200 | Order-level status and date                   |
| order_items   | 8,000 | Line-item detail (qty, price, discount)       |
| payments      | 4,200 | Payment method and value per order            |
| reviews       | 2,979 | Review score + delivery timing per order      |

Schema: [`schema.sql`](schema.sql) · Data generator: [`generate_data.py`](generate_data.py)
Full database: [`ecommerce.db`](ecommerce.db) (SQLite, ready to query)

## Tools Used
SQL (SQLite dialect — window functions, CTEs), Python (data generation only)

## Approach
1. **Trend check** — monthly revenue and order volume (Query 1–2)
2. **Root-cause investigation** — segmented review scores by delivery delay bucket (Query 3)
3. **Product & customer deep dive** — top products per category, RFM segmentation, cohort retention (Query 4–6)
4. **Operational diagnostics** — payment mix, return rates by category, city-level efficiency (Query 7, 9–10)

## Key Findings

**1. Revenue and order volume fell ~45–50% in Jul–Sep 2024** compared to the
prior six-month average (Query 1, 2).

**2. Root cause: delivery delays.** Orders delivered on time or early
averaged a **4.4/5** review score. Orders with a major delay (4+ days late)
averaged just **1.8/5** (Query 3). The Q3 2024 dip directly coincides with a
spike in major delays — this is a logistics/fulfillment issue, not a demand
or pricing issue.

**3. Returns are concentrated in specific categories.** Grocery, Sports &
Fitness, and Toys & Baby have the highest return rates (~16%), well above
Electronics and Books — worth a category-level quality/packaging review
(Query 9).

**4. A small segment of "Champion" customers (high recency, frequency, and
spend) drives disproportionate revenue** (Query 5) — retention offers should
target this group first, since they're the most sensitive to service
failures like the Q3 delays.

**5. Cohort retention drops off sharply after month 1** for every signup
cohort (Query 6), suggesting onboarding/second-purchase incentives could
meaningfully improve lifetime value.

## Recommendation
Prioritize a logistics SLA fix for Q3-style delay spikes — the data shows a
direct, quantifiable link between delivery delay and both review score and
order volume. Pair this with a targeted win-back offer for "At Risk" RFM
customers whose last order fell in the delay window.

## Files in this repo
- `schema.sql` — table definitions
- `generate_data.py` — synthetic data generator (documents assumptions/logic)
- `customers.csv`, `products.csv`, `orders.csv`, `order_items.csv`, `payments.csv`, `reviews.csv`
- `ecommerce.db` — SQLite database, pre-loaded, ready to query
- `analysis_queries.sql` — all 10 analysis queries, tested and commented
- `README.md` — this file

## How to reproduce
```bash
sqlite3 ecommerce.db < schema.sql   # rebuild schema if needed
sqlite3 ecommerce.db
.read analysis_queries.sql
```
