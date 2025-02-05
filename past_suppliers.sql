CREATE TABLE past_suppliers (
    past_supplier_id SERIAL PRIMARY KEY,
    supplier_id INT REFERENCES suppliers(supplier_id) ON DELETE CASCADE,
    supplier_name TEXT NOT NULL,
    item_id INT REFERENCES inventory_levels(item_id) ON DELETE CASCADE,
    last_order_qty INT NOT NULL,
    last_order_date TIMESTAMP DEFAULT NULL,
    last_delivery_date TIMESTAMP DEFAULT NULL,
    last_order_breakage DECIMAL(5,2) DEFAULT NULL,
    last_order_total_cost DECIMAL(10,2) DEFAULT NULL,
    last_order_unit_cost DECIMAL(10,2) DEFAULT NULL,
    current_supplier_flag BOOLEAN NOT NULL DEFAULT TRUE,
    days_since_last_order INT GENERATED ALWAYS AS (EXTRACT(DAY FROM NOW() - last_order_date)) STORED,
    archived_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
