CREATE TABLE historical_inventory_levels (
    history_id SERIAL PRIMARY KEY,
    item_id INT REFERENCES inventory_levels(item_id) ON DELETE CASCADE,
    current_level INT NOT NULL,  -- Now stores a static copy instead of a FK
    cost_per_unit DECIMAL(10,2),  -- Removed FK to suppliers(last_order_unit_cost)
    supplier_id INT REFERENCES suppliers(supplier_id) ON DELETE SET NULL,
    supplier_name TEXT NOT NULL,
    current_price DECIMAL(10,2) NOT NULL,  -- Now stores a static copy instead of a FK
    input_type_id INT REFERENCES input_type_lookup(type_id) NOT NULL,  -- Normalized input_type
    last_reorder_date TIMESTAMP,  -- Now stores a static copy instead of a FK
    archived_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Add an index for faster queries on supplier_id
CREATE INDEX idx_historical_inventory_supplier ON historical_inventory_levels (supplier_id);
