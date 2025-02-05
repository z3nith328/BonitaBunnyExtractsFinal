CREATE OR REPLACE FUNCTION fn_update_sales_velocity_and_days_on_hand()
RETURNS TRIGGER AS $$
BEGIN
    -- Update item_sales_velocity_weekly (Runs Weekly on Monday)
    IF date_part('dow', CURRENT_DATE) = 1 THEN
        UPDATE inventory_items
        SET item_sales_velocity_weekly = (
            SELECT COALESCE(SUM(quantity), 0) / 7
            FROM order_items oi
            JOIN orders o ON oi.order_id = o.order_id
            WHERE oi.item_id = NEW.item_id
            AND o.order_date >= CURRENT_DATE - INTERVAL '7 days'
        )
        WHERE item_id = NEW.item_id;
    END IF;

    -- Update days_on_hand (Runs Daily at Midnight)
    UPDATE inventory_items
    SET days_on_hand = (
        SELECT CASE
            WHEN current_level = 0 THEN NULL
            ELSE current_level / NULLIF(item_sales_velocity_weekly, 0)
        END
    )
    WHERE item_id = NEW.item_id;

    -- Update prev_week_forecast_variance
    UPDATE resupply_schedule
    SET prev_week_forecast_variance =
        ABS(prev_week_demand_forecast - (
            SELECT COALESCE(SUM(quantity), 0)
            FROM order_items oi
            JOIN orders o ON oi.order_id = o.order_id
            WHERE oi.item_id = NEW.item_id
            AND o.order_date >= CURRENT_DATE - INTERVAL '7 days'
        )) / NULLIF(prev_week_demand_forecast, 0)
    WHERE item_id = NEW.item_id;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_update_sales_velocity_and_days_on_hand
AFTER INSERT OR UPDATE ON order_items
FOR EACH ROW
EXECUTE FUNCTION fn_update_sales_velocity_and_days_on_hand();
