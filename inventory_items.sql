CREATE TABLE inventory_items (
    item_id INT PRIMARY KEY REFERENCES inventory_levels(item_id) ON DELETE CASCADE,
    input_type TEXT CHECK (input_type IN ('Bead', 'Cord', 'Pendant')) NOT NULL,
    current_level INT REFERENCES inventory_levels(current_level) ON DELETE CASCADE,
    current_price DECIMAL(10,2) REFERENCES inventory_levels(current_price) ON DELETE CASCADE,
    reorder_qty INT REFERENCES resupply_schedule(reorder_qty) ON DELETE CASCADE,
    last_restock_date TIMESTAMP DEFAULT NULL,
   
    markup_percentage DECIMAL(5,2) GENERATED ALWAYS AS (
        (current_price - cost_per_unit) / cost_per_unit * 100
    ) STORED,

    profit_margin DECIMAL(5,2) GENERATED ALWAYS AS (
        (current_price - cost_per_unit) / current_price * 100
    ) STORED,

    inventory_turnover_rate DECIMAL(10,2) GENERATED ALWAYS AS (
        COALESCE((cost_per_unit * total_units_sold) / ((beginning_inventory + ending_inventory) / 2), 0)
    ) STORED,

    stock_age_days INT GENERATED ALWAYS AS (EXTRACT(DAY FROM NOW() - created_at)) STORED,

    status TEXT CHECK (status IN ('Available', 'Out of Stock', 'Discontinued')) NOT NULL,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);
