CREATE TABLE customers (
    customer_id SERIAL PRIMARY KEY,

    first_name TEXT NOT NULL CHECK (LENGTH(first_name) > 0),
    last_name TEXT NOT NULL CHECK (LENGTH(last_name) > 0),

    email TEXT UNIQUE NOT NULL CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'),
    phone_number TEXT UNIQUE DEFAULT NULL CHECK (phone_number ~ '^\+?[0-9\s\-\(\)]*$'),

    address TEXT DEFAULT NULL CHECK (address IS NULL OR LENGTH(address) > 0),
    city TEXT DEFAULT NULL CHECK (city IS NULL OR LENGTH(city) > 0),
    state TEXT DEFAULT NULL CHECK (state IS NULL OR LENGTH(state) > 0),
    zip_code TEXT DEFAULT NULL CHECK (zip_code IS NULL OR LENGTH(zip_code) > 0),
    country TEXT DEFAULT NULL CHECK (country IS NULL OR LENGTH(country) > 0),

    total_orders INT GENERATED ALWAYS AS (
        (SELECT COUNT(*)
         FROM orders
         WHERE orders.customer_id = customers.customer_id)
    ) STORED,

    total_spent DECIMAL(10,2) GENERATED ALWAYS AS (
        (SELECT COALESCE(SUM(subtotal_amount), 0)
         FROM orders
         WHERE orders.customer_id = customers.customer_id)
    ) STORED,

    avg_order_value DECIMAL(10,2) GENERATED ALWAYS AS (
        CASE
            WHEN total_orders = 0 THEN 0
            ELSE total_spent / total_orders
        END
    ) STORED,

    first_order_date TIMESTAMP GENERATED ALWAYS AS (
        (SELECT MIN(order_date)
         FROM orders
         WHERE orders.customer_id = customers.customer_id)
    ) STORED,

    last_order_date TIMESTAMP GENERATED ALWAYS AS (
        (SELECT MAX(order_date)
         FROM orders
         WHERE orders.customer_id = customers.customer_id)
    ) STORED,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
