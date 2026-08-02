-- ============================================================
-- E-COMMERCE SALES ANALYTICS
-- Business Question: Why did revenue and customer satisfaction
-- dip in Q3 2024, and which customers/products should we
-- prioritize for recovery?
-- ============================================================


-- ------------------------------------------------------------
-- 1. REVENUE OVERVIEW: Monthly revenue trend
-- Skills: JOIN, CTE, aggregate functions
-- ------------------------------------------------------------
WITH order_revenue AS (
    SELECT
        oi.order_id,
        SUM(oi.quantity * oi.unit_price * (1 - oi.discount_pct/100.0)) AS order_value
    FROM order_items oi
    GROUP BY oi.order_id
)
SELECT
    strftime('%Y-%m', o.order_date) AS month,
    COUNT(DISTINCT o.order_id)      AS total_orders,
    ROUND(SUM(r.order_value), 2)    AS total_revenue,
    ROUND(AVG(r.order_value), 2)    AS avg_order_value
FROM orders o
JOIN order_revenue r ON o.order_id = r.order_id
WHERE o.order_status != 'Cancelled'
GROUP BY month
ORDER BY month;


-- ------------------------------------------------------------
-- 2. MONTH-OVER-MONTH GROWTH %
-- Skills: Window function LAG, CTE
-- ------------------------------------------------------------
WITH order_revenue AS (
    SELECT oi.order_id, SUM(oi.quantity * oi.unit_price * (1 - oi.discount_pct/100.0)) AS order_value
    FROM order_items oi GROUP BY oi.order_id
),
monthly AS (
    SELECT strftime('%Y-%m', o.order_date) AS month, SUM(r.order_value) AS revenue
    FROM orders o JOIN order_revenue r ON o.order_id = r.order_id
    WHERE o.order_status != 'Cancelled'
    GROUP BY month
)
SELECT
    month,
    ROUND(revenue, 2) AS revenue,
    ROUND(LAG(revenue) OVER (ORDER BY month), 2) AS prev_month_revenue,
    ROUND(100.0 * (revenue - LAG(revenue) OVER (ORDER BY month)) / LAG(revenue) OVER (ORDER BY month), 1) AS mom_growth_pct
FROM monthly
ORDER BY month;


-- ------------------------------------------------------------
-- 3. DELIVERY DELAY IMPACT ON REVIEW SCORE  (the key insight)
-- Skills: CTE, CASE, JOIN, aggregate
-- ------------------------------------------------------------
WITH delivery_perf AS (
    SELECT
        review_id,
        order_id,
        review_score,
        julianday(actual_delivery_date) - julianday(estimated_delivery_date) AS delay_days,
        CASE
            WHEN julianday(actual_delivery_date) - julianday(estimated_delivery_date) <= 0 THEN 'On Time / Early'
            WHEN julianday(actual_delivery_date) - julianday(estimated_delivery_date) BETWEEN 1 AND 3 THEN 'Slight Delay (1-3 days)'
            ELSE 'Major Delay (4+ days)'
        END AS delay_bucket
    FROM reviews
)
SELECT
    delay_bucket,
    COUNT(*)                          AS num_orders,
    ROUND(AVG(review_score), 2)       AS avg_review_score,
    ROUND(AVG(delay_days), 1)         AS avg_delay_days
FROM delivery_perf
GROUP BY delay_bucket
ORDER BY avg_review_score;


-- ------------------------------------------------------------
-- 4. TOP PRODUCTS BY REVENUE (with rank per category)
-- Skills: Window function RANK, JOIN
-- ------------------------------------------------------------
WITH product_revenue AS (
    SELECT
        p.category,
        p.product_name,
        SUM(oi.quantity * oi.unit_price * (1 - oi.discount_pct/100.0)) AS revenue,
        SUM(oi.quantity) AS units_sold
    FROM order_items oi
    JOIN products p ON oi.product_id = p.product_id
    JOIN orders o ON oi.order_id = o.order_id
    WHERE o.order_status != 'Cancelled'
    GROUP BY p.category, p.product_name
)
SELECT category, product_name, ROUND(revenue,2) AS revenue, units_sold, category_rank
FROM (
    SELECT *,
        RANK() OVER (PARTITION BY category ORDER BY revenue DESC) AS category_rank
    FROM product_revenue
)
WHERE category_rank <= 3
ORDER BY category, category_rank;


-- ------------------------------------------------------------
-- 5. CUSTOMER RFM SEGMENTATION
-- Skills: CTE, NTILE, CASE, date math
-- ------------------------------------------------------------
WITH order_value AS (
    SELECT oi.order_id, SUM(oi.quantity * oi.unit_price * (1 - oi.discount_pct/100.0)) AS value
    FROM order_items oi GROUP BY oi.order_id
),
customer_orders AS (
    SELECT
        o.customer_id,
        MAX(o.order_date)              AS last_order_date,
        COUNT(DISTINCT o.order_id)     AS frequency,
        SUM(ov.value)                  AS monetary
    FROM orders o
    JOIN order_value ov ON o.order_id = ov.order_id
    WHERE o.order_status != 'Cancelled'
    GROUP BY o.customer_id
),
rfm_scores AS (
    SELECT
        customer_id,
        CAST(julianday('2024-12-31') - julianday(last_order_date) AS INTEGER) AS recency_days,
        frequency,
        ROUND(monetary, 2) AS monetary,
        NTILE(4) OVER (ORDER BY julianday(last_order_date) DESC) AS recency_score,
        NTILE(4) OVER (ORDER BY frequency ASC)                   AS frequency_score,
        NTILE(4) OVER (ORDER BY monetary ASC)                    AS monetary_score
    FROM customer_orders
)
SELECT
    customer_id,
    recency_days,
    frequency,
    monetary,
    (recency_score + frequency_score + monetary_score) AS rfm_total,
    CASE
        WHEN recency_score >= 3 AND frequency_score >= 3 AND monetary_score >= 3 THEN 'Champions'
        WHEN recency_score >= 3 AND frequency_score <= 2 THEN 'New / Promising'
        WHEN recency_score <= 2 AND frequency_score >= 3 THEN 'At Risk (was loyal)'
        WHEN recency_score <= 2 AND frequency_score <= 2 THEN 'Lost / Churned'
        ELSE 'Regular'
    END AS customer_segment
FROM rfm_scores
ORDER BY rfm_total DESC
LIMIT 20;


-- ------------------------------------------------------------
-- 6. MONTHLY COHORT RETENTION (signup month -> repeat purchase)
-- Skills: CTE, self-join style logic, date functions
-- ------------------------------------------------------------
WITH first_purchase AS (
    SELECT customer_id, MIN(order_date) AS first_order_date
    FROM orders
    WHERE order_status != 'Cancelled'
    GROUP BY customer_id
),
cohort AS (
    SELECT
        fp.customer_id,
        strftime('%Y-%m', fp.first_order_date) AS cohort_month,
        strftime('%Y-%m', o.order_date)         AS order_month
    FROM first_purchase fp
    JOIN orders o ON fp.customer_id = o.customer_id
    WHERE o.order_status != 'Cancelled'
),
cohort_index AS (
    SELECT
        cohort_month,
        order_month,
        customer_id,
        (CAST(strftime('%Y', order_month || '-01') AS INT) - CAST(strftime('%Y', cohort_month || '-01') AS INT)) * 12
        + (CAST(strftime('%m', order_month || '-01') AS INT) - CAST(strftime('%m', cohort_month || '-01') AS INT)) AS month_number
    FROM cohort
)
SELECT
    cohort_month,
    month_number,
    COUNT(DISTINCT customer_id) AS active_customers
FROM cohort_index
GROUP BY cohort_month, month_number
ORDER BY cohort_month, month_number;


-- ------------------------------------------------------------
-- 7. PAYMENT METHOD PREFERENCE BY CUSTOMER SEGMENT
-- Skills: JOIN across 3 tables, GROUP BY, percentage calc
-- ------------------------------------------------------------
SELECT
    c.customer_segment,
    p.payment_type,
    COUNT(*) AS num_payments,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (PARTITION BY c.customer_segment), 1) AS pct_within_segment
FROM payments p
JOIN orders o ON p.order_id = o.order_id
JOIN customers c ON o.customer_id = c.customer_id
GROUP BY c.customer_segment, p.payment_type
ORDER BY c.customer_segment, num_payments DESC;


-- ------------------------------------------------------------
-- 8. RUNNING TOTAL OF REVENUE (YTD cumulative)
-- Skills: Window function SUM() OVER, ROWS/ORDER BY
-- ------------------------------------------------------------
WITH order_revenue AS (
    SELECT oi.order_id, SUM(oi.quantity * oi.unit_price * (1 - oi.discount_pct/100.0)) AS order_value
    FROM order_items oi GROUP BY oi.order_id
),
monthly AS (
    SELECT strftime('%Y-%m', o.order_date) AS month, SUM(r.order_value) AS revenue
    FROM orders o JOIN order_revenue r ON o.order_id = r.order_id
    WHERE o.order_status != 'Cancelled'
    GROUP BY month
)
SELECT
    month,
    ROUND(revenue, 2) AS revenue,
    ROUND(SUM(revenue) OVER (ORDER BY month ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW), 2) AS running_total
FROM monthly
ORDER BY month;


-- ------------------------------------------------------------
-- 9. CANCELLATION / RETURN RATE BY CATEGORY
-- Skills: CASE, JOIN, aggregate ratio
-- ------------------------------------------------------------
SELECT
    p.category,
    COUNT(DISTINCT o.order_id) AS total_orders,
    SUM(CASE WHEN o.order_status = 'Returned' THEN 1 ELSE 0 END) AS returned_orders,
    ROUND(100.0 * SUM(CASE WHEN o.order_status = 'Returned' THEN 1 ELSE 0 END) / COUNT(DISTINCT o.order_id), 2) AS return_rate_pct
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p ON oi.product_id = p.product_id
GROUP BY p.category
ORDER BY return_rate_pct DESC;


-- ------------------------------------------------------------
-- 10. TOP 10 CITIES BY REVENUE PER CUSTOMER (efficiency, not just volume)
-- Skills: CTE, JOIN, ratio metric
-- ------------------------------------------------------------
WITH order_revenue AS (
    SELECT oi.order_id, SUM(oi.quantity * oi.unit_price * (1 - oi.discount_pct/100.0)) AS order_value
    FROM order_items oi GROUP BY oi.order_id
)
SELECT
    c.city,
    COUNT(DISTINCT c.customer_id)         AS num_customers,
    ROUND(SUM(r.order_value), 2)          AS total_revenue,
    ROUND(SUM(r.order_value) / COUNT(DISTINCT c.customer_id), 2) AS revenue_per_customer
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
JOIN order_revenue r ON o.order_id = r.order_id
WHERE o.order_status != 'Cancelled'
GROUP BY c.city
ORDER BY revenue_per_customer DESC
LIMIT 10;
