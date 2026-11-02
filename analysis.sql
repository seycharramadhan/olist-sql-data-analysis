-- Olist Brazilian E-Commerce Data Analysis
-- SQL Portfolio Project
-- PostgreSQL

-- =========================================
-- 1. TOTAL REVENUE
-- =========================================

SELECT
    SUM(payment_value) AS total_revenue
FROM order_payments;

-- =========================================
-- 2. TOTAL ORDERS & AVERAGE ORDER VALUE
-- =========================================

SELECT
    COUNT(DISTINCT order_id) AS total_orders,
    ROUND(
        (SUM(payment_value) / COUNT(DISTINCT order_id))::numeric,
        2
    ) AS average_order_value
FROM order_payments;

-- =========================================
-- 3. MONTHLY REVENUE
-- =========================================

SELECT
    DATE_TRUNC(
        'month',
        order_purchase_timestamp::timestamp
    ) AS bulan,
    ROUND(SUM(p.payment_value)::numeric, 2) AS revenue
FROM orders o
JOIN order_payments p
    ON o.order_id = p.order_id
GROUP BY bulan
ORDER BY bulan;

-- =========================================
-- 4. TOP 5 PRODUCT CATEGORIES BY REVENUE
-- =========================================

SELECT
    COALESCE(
        t.product_category_name_english,
        p.product_category_name
    ) AS kategori,
    ROUND(
        SUM(oi.price + oi.freight_value)::numeric,
        2
    ) AS revenue
FROM order_items oi
JOIN products p
    ON oi.product_id = p.product_id
LEFT JOIN product_category_translation t
    ON p.product_category_name = t.product_category_name
GROUP BY kategori
ORDER BY revenue DESC
LIMIT 5;

-- =========================================
-- 5. PAYMENT METHODS
-- =========================================

SELECT
    payment_type,
    COUNT(*) AS total_transactions,
    ROUND(SUM(payment_value)::numeric, 2) AS total_payment
FROM order_payments
GROUP BY payment_type
ORDER BY total_payment DESC;

-- =========================================
-- 6. TOP 10 CUSTOMERS BY TOTAL SPEND
-- =========================================

SELECT
    c.customer_unique_id,
    COUNT(DISTINCT o.order_id) AS total_orders,
    ROUND(SUM(p.payment_value)::numeric, 2) AS total_spent
FROM customers c
JOIN orders o
    ON c.customer_id = o.customer_id
JOIN order_payments p
    ON o.order_id = p.order_id
GROUP BY c.customer_unique_id
ORDER BY total_spent DESC
LIMIT 10;

-- =========================================
-- 7. AVERAGE RATING BY PRODUCT CATEGORY
-- =========================================

SELECT
    COALESCE(
        t.product_category_name_english,
        p.product_category_name
    ) AS kategori,
    ROUND(AVG(r.review_score)::numeric, 2) AS rata_rata_rating,
    COUNT(*) AS total_review
FROM order_reviews r
JOIN order_items oi
    ON r.order_id = oi.order_id
JOIN products p
    ON oi.product_id = p.product_id
LEFT JOIN product_category_translation t
    ON p.product_category_name = t.product_category_name
GROUP BY kategori
HAVING COUNT(*) >= 100
ORDER BY rata_rata_rating DESC
LIMIT 10;

-- =========================================
-- 8. DELIVERY PERFORMANCE
-- =========================================

SELECT
    CASE
        WHEN NULLIF(order_delivered_customer_date, '') IS NULL
          OR NULLIF(order_estimated_delivery_date, '') IS NULL
        THEN 'Tidak Ada Data'
        
        WHEN NULLIF(order_delivered_customer_date, '')::date
             > NULLIF(order_estimated_delivery_date, '')::date
        THEN 'Terlambat'
        
        ELSE 'Tepat Waktu'
    END AS status_pengiriman,
    COUNT(*) AS total_orders
FROM orders
GROUP BY
    CASE
        WHEN NULLIF(order_delivered_customer_date, '') IS NULL
          OR NULLIF(order_estimated_delivery_date, '') IS NULL
        THEN 'Tidak Ada Data'
        
        WHEN NULLIF(order_delivered_customer_date, '')::date
             > NULLIF(order_estimated_delivery_date, '')::date
        THEN 'Terlambat'
        
        ELSE 'Tepat Waktu'
    END
ORDER BY total_orders DESC;

-- =========================================
-- 9. AVERAGE DELIVERY TIME
-- =========================================

SELECT
    ROUND(
        AVG(
            NULLIF(order_delivered_customer_date, '')::date
            - NULLIF(order_purchase_timestamp, '')::date
        ),
        2
    ) AS rata_rata_hari_pengiriman
FROM orders
WHERE NULLIF(order_delivered_customer_date, '') IS NOT NULL
  AND NULLIF(order_purchase_timestamp, '') IS NOT NULL
  AND NULLIF(order_estimated_delivery_date, '') IS NOT NULL
  AND NULLIF(order_delivered_customer_date, '')::date
      <= NULLIF(order_estimated_delivery_date, '')::date;

-- =========================================
-- 10. DELIVERY STATUS VS CUSTOMER RATING
-- =========================================

SELECT
    CASE
        WHEN NULLIF(o.order_delivered_customer_date, '') IS NULL
          OR NULLIF(o.order_estimated_delivery_date, '') IS NULL
        THEN 'Tidak Ada Data'

        WHEN NULLIF(o.order_delivered_customer_date, '')::date
             > NULLIF(o.order_estimated_delivery_date, '')::date
        THEN 'Terlambat'

        ELSE 'Tepat Waktu'
    END AS status_pengiriman,
    
    r.review_score AS rating,
    COUNT(*) AS total_review

FROM orders o
JOIN order_reviews r
    ON o.order_id = r.order_id

GROUP BY status_pengiriman, r.review_score
ORDER BY status_pengiriman, rating;

-- =========================================
-- 11. TOP 10 SELLERS BY REVENUE
-- =========================================

SELECT
    s.seller_id,
    s.seller_city,
    s.seller_state,
    ROUND(
        SUM(oi.price + oi.freight_value)::numeric,
        2
    ) AS total_revenue,
    COUNT(DISTINCT oi.order_id) AS total_orders
FROM sellers s
JOIN order_items oi
    ON s.seller_id = oi.seller_id
GROUP BY
    s.seller_id,
    s.seller_city,
    s.seller_state
ORDER BY total_revenue DESC
LIMIT 10;

-- =========================================
-- 12. TOP 10 SELLERS BY NUMBER OF ORDERS
-- =========================================

SELECT
    s.seller_id,
    s.seller_city,
    s.seller_state,
    COUNT(DISTINCT oi.order_id) AS total_orders,
    ROUND(
        SUM(oi.price + oi.freight_value)::numeric,
        2
    ) AS total_revenue
FROM sellers s
JOIN order_items oi
    ON s.seller_id = oi.seller_id
GROUP BY
    s.seller_id,
    s.seller_city,
    s.seller_state
ORDER BY total_orders DESC
LIMIT 10;

-- =========================================
-- 13. YEARLY REVENUE GROWTH
-- =========================================

WITH revenue_tahunan AS (
    SELECT
        EXTRACT(
            YEAR FROM o.order_purchase_timestamp::timestamp
        ) AS tahun,
        SUM(p.payment_value) AS revenue
    FROM orders o
    JOIN order_payments p
        ON o.order_id = p.order_id
    GROUP BY tahun
)
SELECT
    tahun,
    ROUND(revenue::numeric, 2) AS revenue,
    ROUND(
        (
            (revenue - LAG(revenue) OVER (ORDER BY tahun))
            / LAG(revenue) OVER (ORDER BY tahun)
            * 100
        )::numeric,
        2
    ) AS pertumbuhan_persen
FROM revenue_tahunan
ORDER BY tahun;

-- =========================================
-- PROJECT SUMMARY
-- =========================================
--
-- Dataset:
-- Olist Brazilian E-Commerce Public Dataset
--
-- Database:
-- PostgreSQL
--
-- Main Analysis:
-- 1. Revenue & business performance
-- 2. Order value & customer behavior
-- 3. Product category performance
-- 4. Payment methods
-- 5. Customer reviews
-- 6. Delivery performance
-- 7. Seller performance
-- 8. Revenue growth
--
-- Key Findings:
-- - Total revenue: approximately 16.01M BRL
-- - Average order value: approximately 160.99 BRL
-- - Average on-time delivery: approximately 10 days
-- - Credit card is the dominant payment method
-- - Revenue increased year over year
-- - Revenue growth reached approximately 20% in 2018
--
-- =========================================