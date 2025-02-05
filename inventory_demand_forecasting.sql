CREATE TABLE inventory_demand_forecasting (
    item_id INT PRIMARY KEY REFERENCES inventory_items(item_id) ON DELETE CASCADE,

    historical_sales_volume INT NOT NULL,

    seasonality_factor DECIMAL(5,2) GENERATED ALWAYS AS (
        (SELECT COALESCE(AVG(order_items.quantity) / AVG(total_average_sales), 1)
         FROM order_items
         WHERE order_items.item_id = inventory_demand_forecasting.item_id)
    ) STORED,

    lead_time_demand INT GENERATED ALWAYS AS (
        (SELECT COALESCE(AVG(average_daily_sales * supplier_lead_time), 0)
         FROM resupply_schedule
         WHERE resupply_schedule.item_id = inventory_demand_forecasting.item_id)
    ) STORED,

    forecasted_demand INT NOT NULL, -- Updated manually by external Python script

    forecast_accuracy DECIMAL(5,2) GENERATED ALWAYS AS (
        (1 - (ABS(forecasted_demand -
            (SELECT COALESCE(SUM(order_items.quantity), 1)
             FROM order_items
             WHERE order_items.item_id = inventory_demand_forecasting.item_id))
        ) /
        (SELECT COALESCE(SUM(order_items.quantity), 1)
         FROM order_items
         WHERE order_items.item_id = inventory_demand_forecasting.item_id)))
    ) STORED,

    demand_trend_indicator TEXT CHECK (demand_trend_indicator IN ('Increasing', 'Decreasing', 'Stable')) NOT NULL,

    moving_average_demand DECIMAL(10,2) GENERATED ALWAYS AS (
        (SELECT COALESCE(SUM(order_items.quantity) / COUNT(DISTINCT order_items.order_id), 0)
         FROM order_items
         WHERE order_items.item_id = inventory_demand_forecasting.item_id)
    ) STORED,

    days_of_inventory_on_hand DECIMAL(10,2) GENERATED ALWAYS AS (
        (SELECT COALESCE(current_level / AVG(average_daily_sales), 0)
         FROM inventory_levels
         WHERE inventory_levels.item_id = inventory_demand_forecasting.item_id)
    ) STORED,

    sales_velocity DECIMAL(10,2) GENERATED ALWAYS AS (
        (SELECT COALESCE(SUM(order_items.quantity) / COUNT(DISTINCT order_items.order_id), 0)
         FROM order_items
         WHERE order_items.item_id = inventory_demand_forecasting.item_id)
    ) STORED,

    market_demand_index DECIMAL(10,2) GENERATED ALWAYS AS (
        ((forecasted_demand /
            (SELECT COALESCE(SUM(forecasted_demand), 1)
             FROM inventory_demand_forecasting)) * 100)
    ) STORED
);
