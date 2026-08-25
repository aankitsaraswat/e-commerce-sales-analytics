# E-Commerce Sales & Customer Analytics (SQL Portfolio Project)

## Business Context

An Indian e-commerce retailer wants to understand why **revenue and
customer satisfaction dropped sharply in Q3 2024**, and which
customers/products to prioritize for recovery.

This project uses SQL to investigate the decline, diagnose the root
cause, and recommend where to focus retention and operational
improvement efforts.

## Dataset

Synthetic but realistic relational dataset containing 6 tables and
approximately 21K total rows:

  ------------------------------------------------------------------------
  Table                                         Rows Description
  --------------------- ---------------------------- ---------------------
  customers                                    1,600 Customer profile,
                                                     city, signup date,
                                                     segment

  products                                       240 Product catalog
                                                     across 8 categories

  orders                                       4,200 Order-level status
                                                     and date

  order_items                                  8,000 Line-item detail
                                                     including quantity,
                                                     price, and discount

  payments                                     4,200 Payment method and
                                                     value per order

  reviews                                      2,979 Review score and
                                                     delivery timing per
                                                     order
  ------------------------------------------------------------------------

-   Database schema: [`sql/schema.sql`](sql/schema.sql)
-   SQL analysis:
    [`sql/ecommerce_sales_analysis.sql`](sql/ecommerce_sales_analysis.sql)
-   Data generator: [`python/generate_data.py`](python/generate_data.py)
-   Source data: [`data/`](data/)

## Tools Used

-   **MySQL** --- data querying and analysis using joins, aggregate
    functions, CTEs, subqueries, and window functions
-   **Python** --- synthetic data generation
-   **Git & GitHub** --- version control, project organization, and
    documentation

## Approach

1.  **Trend check** --- analyze monthly revenue and order volume (Query
    1--2)
2.  **Root-cause investigation** --- analyze review scores by
    delivery-delay bucket (Query 3)
3.  **Product & customer deep dive** --- identify top products by
    category, perform RFM segmentation, and analyze cohort retention
    (Query 4--6)
4.  **Operational diagnostics** --- examine payment mix, return rates by
    category, and city-level revenue efficiency (Query 7, 9--10)

## Key Findings

**1. Revenue and order volume fell \~45--50% in Jul--Sep 2024** compared
with the prior six-month average (Query 1--2).

**2. Root cause: delivery delays.** Orders delivered on time or early
averaged a **4.4/5** review score, while orders with a major delay (4+
days late) averaged just **1.8/5** (Query 3). The Q3 2024 dip coincides
with a spike in major delays, pointing to a logistics/fulfillment issue
rather than a demand or pricing issue.

**3. Returns are concentrated in specific categories.** Grocery, Sports
& Fitness, and Toys & Baby have the highest return rates (\~16%), well
above Electronics and Books, indicating areas worth investigating for
product quality, packaging, or fulfillment issues (Query 9).

**4. A small segment of "Champion" customers (high recency, frequency,
and spend) drives disproportionate revenue** (Query 5). Retention
efforts should prioritize this group because service failures such as
delivery delays may put valuable customers at risk.

**5. Cohort retention drops sharply after month 1** across signup
cohorts (Query 6), suggesting that onboarding and second-purchase
incentives could help improve customer lifetime value.

## Recommendation

Prioritize improvements to logistics SLAs to prevent Q3-style
delivery-delay spikes. The analysis shows a measurable relationship
between delivery delays and customer review scores.

Pair operational improvements with targeted win-back campaigns for **"At
Risk" RFM customers**, particularly customers whose most recent orders
occurred during the delay period.

## Repository Structure

``` text
e-commerce-sales-analytics/
│
├── data/
│   ├── customers.csv
│   ├── order_items.csv
│   ├── orders.csv
│   ├── payments.csv
│   ├── products.csv
│   └── reviews.csv
│
├── python/
│   └── generate_data.py
│
├── sql/
│   ├── ecommerce_sales_analysis.sql
│   └── schema.sql
│
└── README.md
```

## Files in This Repository

-   `data/` --- CSV datasets used in the analysis
-   `python/generate_data.py` --- synthetic data generator documenting
    the assumptions and data-generation logic
-   `sql/schema.sql` --- MySQL table definitions
-   `sql/ecommerce_sales_analysis.sql` --- SQL analysis queries used to
    investigate the business problem
-   `README.md` --- project overview, methodology, findings, and
    recommendations

## How to Reproduce

1.  Clone or download this repository.
2.  Open MySQL Workbench or another MySQL client.
3.  Run `sql/schema.sql` to create the required tables.
4.  Load the CSV files from the `data/` directory into their
    corresponding MySQL tables.
5.  Run `sql/ecommerce_sales_analysis.sql` to reproduce the analysis.
6.  Review the query outputs alongside the findings documented in this
    README.

> **Note:** The project is structured for MySQL. Database credentials
> and other sensitive information should not be committed to the
> repository.
