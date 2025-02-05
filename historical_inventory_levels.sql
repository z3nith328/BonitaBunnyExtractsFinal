CREATE TABLE historical_inventory_levels (
    history_id SERIAL PRIMARY KEY,
    item_id INT REFERENCES inventory_levels(item_id) ON DELETE CASCADE,
    current_level INT REFERENCES inventory_levels(current_level) ON DELETE CASCADE,
    cost_per_unit DECIMAL(10,2) REFERENCES suppliers(last_order_unit_cost) ON DELETE SET NULL,
    supplier_id INT REFERENCES suppliers(supplier_id) ON DELETE SET NULL,
    supplier_name TEXT NOT NULL,
    current_price DECIMAL(10,2) REFERENCES inventory_levels(current_price) ON DELETE CASCADE,
    input_type TEXT CHECK (input_type IN ('Bead', 'Cord', 'Pendant')) NOT NULL,
    last_reorder_date TIMESTAMP REFERENCES inventory_levels(last_reorder_date) ON DELETE CASCADE,
    archived_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
