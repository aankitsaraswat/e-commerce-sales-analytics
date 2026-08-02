-- ============================================================
-- E-COMMERCE SALES ANALYTICS — SCHEMA
-- ============================================================

DROP TABLE IF EXISTS reviews;
DROP TABLE IF EXISTS payments;
DROP TABLE IF EXISTS order_items;
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS customers;

CREATE TABLE customers (
    customer_id       TEXT PRIMARY KEY,
    customer_name      TEXT NOT NULL,
    email             TEXT,
    city              TEXT,
    state             TEXT,
    signup_date       DATE,
    customer_segment  TEXT CHECK (customer_segment IN ('New','Regular','Loyal','VIP'))
);

CREATE TABLE products (
    product_id    TEXT PRIMARY KEY,
    product_name  TEXT NOT NULL,
    category      TEXT,
    price         REAL,
    cost          REAL
);

CREATE TABLE orders (
    order_id      TEXT PRIMARY KEY,
    customer_id   TEXT REFERENCES customers(customer_id),
    order_date    DATE,
    order_status  TEXT CHECK (order_status IN ('Delivered','Shipped','Cancelled','Returned'))
);

CREATE TABLE order_items (
    order_item_id  TEXT PRIMARY KEY,
    order_id       TEXT REFERENCES orders(order_id),
    product_id     TEXT REFERENCES products(product_id),
    quantity       INTEGER,
    unit_price     REAL,
    discount_pct   REAL
);

CREATE TABLE payments (
    payment_id     TEXT PRIMARY KEY,
    order_id       TEXT REFERENCES orders(order_id),
    payment_type   TEXT,
    payment_value  REAL,
    payment_date   DATE
);

CREATE TABLE reviews (
    review_id                 TEXT PRIMARY KEY,
    order_id                  TEXT REFERENCES orders(order_id),
    review_score              INTEGER CHECK (review_score BETWEEN 1 AND 5),
    review_comment             TEXT,
    estimated_delivery_date   DATE,
    actual_delivery_date      DATE,
    review_date               DATE
);

CREATE INDEX idx_orders_customer ON orders(customer_id);
CREATE INDEX idx_orders_date ON orders(order_date);
CREATE INDEX idx_items_order ON order_items(order_id);
CREATE INDEX idx_items_product ON order_items(product_id);
CREATE INDEX idx_payments_order ON payments(order_id);
CREATE INDEX idx_reviews_order ON reviews(order_id);
