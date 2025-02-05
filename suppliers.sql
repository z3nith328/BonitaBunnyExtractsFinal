CREATE TABLE suppliers (
    supplier_id SERIAL PRIMARY KEY,
    supplier_name TEXT NOT NULL UNIQUE,
    item_id TEXT REFERENCES inventory_levels(item_id) ON DELETE CASCADE,

    last_order_qty INT NOT NULL CHECK (last_order_qty >= 0),
    last_order_date TIMESTAMP DEFAULT NULL,
    last_delivery_date TIMESTAMP DEFAULT NULL,

    last_order_breakage DECIMAL(5,2) DEFAULT 0 CHECK (last_order_breakage >= 0),
    last_order_total_cost DECIMAL(10,2) DEFAULT 0 CHECK (last_order_total_cost >= 0),

    -- Auto-calculated field
    last_order_unit_cost DECIMAL(10,2) GENERATED ALWAYS AS (
        CASE
            WHEN last_order_qty > 0 THEN last_order_total_cost / last_order_qty
            ELSE NULL
        END
    ) STORED
);
