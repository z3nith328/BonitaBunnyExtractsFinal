CREATE OR REPLACE FUNCTION auto_schedule_restock_on_demand_spike()
RETURNS TRIGGER AS $$
BEGIN
    IF (NEW.daily_item_sales > (OLD.daily_item_sales * 1.2)) THEN
        UPDATE resupply_schedule
        SET sugg_restock_date = NOW() + INTERVAL '2 days'
        WHERE item_id = NEW.item_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER TR_Auto_Schedule_Restock_On_Demand_Spike
AFTER UPDATE ON inventory_demand_forecasting
FOR EACH ROW
EXECUTE FUNCTION auto_schedule_restock_on_demand_spike();
