CREATE OR REPLACE FUNCTION update_resupply_schedule()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE resupply_schedule
    SET reorder_qty =
        CASE
            WHEN NEW.current_level < safety_stock_level THEN NEW.current_level * 1.5
            ELSE reorder_qty
        END,
        sugg_restock_date =
            CASE
                WHEN NEW.current_level < safety_stock_level THEN NOW() + INTERVAL '7 days'
                ELSE sugg_restock_date
            END,
        prev_week_demand_forecast = (
            SELECT AVG(quantity)
            FROM order_items
            WHERE item_id = NEW.item_id AND order_date >= NOW() - INTERVAL '7 days'
        )
    WHERE item_id = NEW.item_id;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_update_resupply_schedule
AFTER UPDATE ON inventory_levels
FOR EACH ROW
EXECUTE FUNCTION update_resupply_schedule();
