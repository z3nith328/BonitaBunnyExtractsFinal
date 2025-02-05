CREATE TRIGGER trg_update_inventory_on_order_change
AFTER INSERT OR UPDATE OR DELETE ON order_items
FOR EACH ROW
EXECUTE FUNCTION update_inventory_on_order_change();


CREATE OR REPLACE FUNCTION update_inventory_demand_forecasting()
RETURNS TRIGGER AS $$
BEGIN
    -- Update historical sales volume
    UPDATE inventory_demand_forecasting
    SET historical_sales_volume = historical_sales_volume + NEW.quantity
    WHERE item_id = NEW.item_id;

    -- Update moving average demand (7-day moving average)
    UPDATE inventory_demand_forecasting
    SET moving_average_demand = (
        SELECT COALESCE(AVG(quantity), 0)
        FROM order_items
        WHERE item_id = NEW.item_id AND order_date >= NOW() - INTERVAL '7 days'
    )
    WHERE item_id = NEW.item_id;

    -- Update forecast accuracy
    UPDATE inventory_demand_forecasting
    SET forecast_accuracy = 1 - (
        ABS(forecasted_demand - historical_sales_volume) / NULLIF(forecasted_demand, 0)
    )
    WHERE item_id = NEW.item_id;

    -- Update demand trend indicator
    UPDATE inventory_demand_forecasting
    SET demand_trend_indicator =
        CASE
            WHEN moving_average_demand > (SELECT AVG(moving_average_demand) FROM inventory_demand_forecasting) THEN 'Increasing'
            WHEN moving_average_demand < (SELECT AVG(moving_average_demand) FROM inventory_demand_forecasting) THEN 'Decreasing'
            ELSE 'Stable'
        END
    WHERE item_id = NEW.item_id;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
