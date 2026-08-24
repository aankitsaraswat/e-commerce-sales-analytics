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
select 
     date_format(o.order_date, '%Y-%m') as month,
     count(distinct o.order_id) as total_orders,
	 round(sum(r.order_value),2) as total_revenue,
     round(avg(r.order_value),2) as avg_order_value
from orders o
join order_revenue r on o.order_id = r.order_id
where o.order_status != 'cancelled'
group by month
order by month;

-- ------------------------------------------------------------
-- 2. MONTH-OVER-MONTH GROWTH %
-- Skills: Window function LAG, CTE
-- ------------------------------------------------------------
WITH order_revenue AS (
    SELECT oi.order_id,SUM(oi.quantity * oi.unit_price * (1 - oi.discount_pct/100.0)) AS order_value
    FROM order_items oi GROUP BY oi.order_id
),
monthly as(  
    SELECT date_format(o.order_date,'%y-%m') AS month, SUM(r.order_value) AS revenue
    FROM orders o JOIN order_revenue r ON o.order_id = r.order_id
    WHERE o.order_status != 'Cancelled'
    GROUP BY month
)
select 
    month,
    round(revenue,2) as revenue,
    round(lag(revenue) over (order by month),2) as prev_month_revenue,
    round(100 * (revenue - lag(revenue) over(order by month))/lag(revenue) over(order by month),1) AS mom_growth_pct
from monthly
order by month;


-- ------------------------------------------------------------
-- 3. DELIVERY DELAY IMPACT ON REVIEW SCORE  (the key insight)
-- Skills: CTE, CASE, JOIN, aggregate
-- ------------------------------------------------------------
with delivery_perf as(
  select
      review_id,
      order_id,
      review_score,
      datediff(actual_delivery_date, estimated_delivery_date) as delay_days,
      case
          when datediff(actual_delivery_date, estimated_delivery_date) <= 0 then 'on time/early'
          when datediff(actual_delivery_date, estimated_delivery_date) between 1 and 3 then 'slight delay 1-3 days'
          else 'major delay (4+ days)'
	  end as delay_bucket
  from reviews
)
select
      delay_bucket,
      count(*)                    as num_orders,
      round(avg(review_score),2)  as avg_review_score,
      round(avg(delay_days),1)    as avg_delay_days
from delivery_perf
group by delay_bucket
order by avg_review_score;


-- ------------------------------------------------------------
-- 4. TOP PRODUCTS BY REVENUE (with rank per category)
-- Skills: Window function RANK, JOIN
-- ------------------------------------------------------------
with product_revenue as(
   select p.category,
		  p.product_name,
          sum(oi.quantity * oi.unit_price * (1- oi.discount_pct/100)) as revenue,
          sum(oi.quantity) as units_sold
   from order_items oi
   join products p on oi.product_id = p.product_id
   join orders o on oi.order_id = o.order_id
   where o.order_status != 'Cancelled'
   group by p.category,p.product_name
)
select category,product_name,round(revenue,2) as revenue, units_sold, category_rank
from(
	select *,
			rank() over(partition by category order by revenue desc) as category_rank
	from product_revenue
) ranked_products
WHERE category_rank <= 3
ORDER BY category, category_rank;


-- ------------------------------------------------------------
-- 5. CUSTOMER RFM SEGMENTATION
-- Skills: CTE, NTILE, CASE, date math
-- ------------------------------------------------------------
with order_value as (
    select oi.order_id,
    sum(oi.quantity * oi.unit_price * (1-oi.discount_pct/100)) as value
    from order_items oi group by oi.order_id
),
customer_orders as (
	select o.customer_id,
    max(o.order_date)         as last_order_date,
    count(distinct o.order_id) as frequency,
    sum(ov.value)              as monetary
 from orders o
 join order_value ov on o.order_id = ov.order_id
 where o.order_status != 'Cancelled'
 group by o.customer_id 
  ),
  rfm_scores as (
     select customer_id,
     datediff('2024-12-31', last_order_date) as recency_days,frequency,
     round(monetary,2) as monetary,
     ntile(4) over (order by last_order_date desc) as recency_score,
     ntile(4) over (order by frequency asc) as frequency_score,
     ntile(4) over (order by monetary asc) as monetary_score
  from customer_orders
)
select 
     customer_id,
     recency_days,
     frequency,
     monetary,
     (recency_score + frequency_score + monetary_score) as rfm_total,
case
    when recency_score >= 3 and frequency_score >= 3 and monetary_score >= 3 then 'Champions'
	when recency_score >= 3 and frequency_score <= 2 then 'New/Promising'
    when recency_score <= 2 and frequency_score >= 3 then 'At risk (was loyal)'
    when recency_score <= 2 and frequency_score <= 2 then 'Lost/Churned'
	else 'Regular'
end as customer_segment
from rfm_scores
order by rfm_total desc
limit 20;


-- ------------------------------------------------------------
-- 6. MONTHLY COHORT RETENTION (signup month -> repeat purchase)
-- Skills: CTE, self-join style logic, date functions
-- ------------------------------------------------------------
with first_purchase as (
	select customer_id, min(order_date) as first_order_date
    from orders
    where order_status != 'Cancelled'
    group by customer_id
),
cohort as (
   select fp.customer_id,
   date_format(fp.first_order_date, '%Y-%m') as cohort_month,
   date_format(o.order_date, '%Y-%m') as order_month
 FROM first_purchase fp
 JOIN orders o ON fp.customer_id = o.customer_id
 WHERE o.order_status != 'Cancelled'
),
cohort_index as (
	select 
       cohort_month,
       order_month,
       customer_id,
       timestampdiff (
    MONTH,
    STR_TO_DATE(CONCAT(cohort_month, '-01'), '%Y-%m-%d'),
    STR_TO_DATE(CONCAT(order_month, '-01'), '%Y-%m-%d')
) AS month_number
from cohort
) 
select
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
select c.customer_segment,
	   p.payment_type,
	   count(*) as num_payments,
	   round(100 * count(*)/sum(count(*)) over (partition by c.customer_segment),1) as pct_within_segment
from payments p
join orders o on p.order_id = o.order_id
join customers c on o.customer_id = c.customer_id
GROUP BY c.customer_segment, p.payment_type
ORDER BY c.customer_segment, num_payments DESC;


-- ------------------------------------------------------------
-- 8. RUNNING TOTAL OF REVENUE (YTD cumulative)
-- Skills: Window function SUM() OVER, ROWS/ORDER BY
-- ------------------------------------------------------------
with order_revenue as (
	   select oi.order_id,sum(oi.quantity * oi.unit_price * (1 - oi.discount_pct/100)) as order_value
       from order_items oi group by oi.order_id
),
monthly as (
   select date_format(o.order_date, '%Y-%m') as month, sum(r.order_value) as revenue
   from orders o join order_revenue r on r.order_id = o.order_id
   where o.order_status != 'Cancelled'
   group by month
)
select
     month,
     round(revenue,2) as revenue, 
     round(sum(revenue) over(order by month rows between unbounded preceding and current row), 2) as running_total
from monthly
order by month;


-- ------------------------------------------------------------
-- 9. CANCELLATION / RETURN RATE BY CATEGORY
-- Skills: CASE, JOIN, aggregate ratio
-- ------------------------------------------------------------
select 
     p.category,
     count(distinct o.order_id) as total_orders, 
     sum(case when o.order_status = 'Returned' then 1 else 0 end) as returned_orders,
     round(100 * sum(case when o.order_status = 'Retured' then 1 else 0 end)/count(distinct o.order_id),2) as return_rate_pct
from orders o
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