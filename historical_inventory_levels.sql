CREATE TABLE historical_inventory_levels (
    history_id SERIAL PRIMARY KEY,
    item_id INT REFERENCES inventory_levels(item_id) ON DELETE CASCADE,
    
    -- Removed FK constraints on volatile columns, now storing static copies
    current_level INT NOT NULL, 
    cost_per_unit DECIMAL(10,2),  
    supplier_id INT REFERENCES suppliers(supplier_id) ON DELETE SET NULL,
    supplier_name TEXT NOT NULL,
    current_price DECIMAL(10,2) NOT NULL, 
    input_type TEXT CHECK (input_type IN ('Bead', 'Cord', 'Pendant')) NOT NULL,
    last_reorder_date TIMESTAMP,  

    archived_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_historical_inventory_supplier ON historical_inventory_levels (supplier_id);
