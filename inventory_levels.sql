CREATE TABLE inventory_levels (
    item_id TEXT PRIMARY KEY REFERENCES item_matrix(item_id) ON DELETE CASCADE,
    supplier_id INT REFERENCES suppliers(supplier_id) ON DELETE SET NULL,
    supplier_name TEXT NOT NULL,
    current_level INT NOT NULL CHECK (current_level >= 0),
    cost_per_unit DECIMAL(10,2) NOT NULL CHECK (cost_per_unit >= 0),

    -- Ensured subquery returns a single row by using ORDER BY and LIMIT 1
    current_price DECIMAL(10,2) GENERATED ALWAYS AS (
        (SELECT last_order_unit_cost * (1 + COALESCE(il.markup_percentage, 0) / 100)
         FROM suppliers s
         WHERE s.supplier_id = inventory_levels.supplier_id
         AND s.item_id = inventory_levels.item_id
         ORDER BY s.last_order_date DESC
         LIMIT 1)
    ) STORED,

    input_type TEXT CHECK (input_type IN ('Bead', 'Cord', 'Pendant')) NOT NULL,
    last_updated_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_reorder_date TIMESTAMP
);
