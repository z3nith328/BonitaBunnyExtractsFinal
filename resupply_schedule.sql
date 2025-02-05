CREATE TABLE resupply_schedule (
    schedule_id SERIAL PRIMARY KEY,
    supplier_id INT NOT NULL REFERENCES suppliers(supplier_id) ON DELETE CASCADE,
    supplier_name TEXT NOT NULL,
    item_id INT NOT NULL REFERENCES inventory_levels(item_id) ON DELETE CASCADE,
    current_level INT NOT NULL DEFAULT 0,

    -- Reorder quantity should auto-update based on inventory safety stock levels
    reorder_qty INT GENERATED ALWAYS AS (
        (SELECT reorder_point FROM inventory_safety_stock WHERE inventory_safety_stock.item_id = resupply_schedule.item_id)
    ) STORED,

    -- Forecasting-based replenishment tracking
    daily_item_sales DECIMAL(10,2) DEFAULT NULL,
    item_sales_velocity_weekly DECIMAL(10,2) DEFAULT NULL,
    days_on_hand INT DEFAULT NULL,

    -- Supplier logistics & lead time tracking
    supplier_lead_time INT NOT NULL CHECK (supplier_lead_time > 0), -- Must be a positive integer

    -- Forecast variance tracking (compares predicted demand to actual sales)
    prev_week_demand_forecast DECIMAL(10,2) DEFAULT NULL,
    prev_week_forecast_variance DECIMAL(10,2) GENERATED ALWAYS AS (
        (prev_week_demand_forecast - daily_item_sales) / NULLIF(prev_week_demand_forecast, 0)
    ) STORED,

    -- Auto-updating suggested restock date based on lead time & demand trends
    last_order_date TIMESTAMP DEFAULT NULL,
    sugg_restock_date TIMESTAMP GENERATED ALWAYS AS (
        last_order_date + (supplier_lead_time || ' days')::INTERVAL
    ) STORED
);
