CREATE OR REPLACE FUNCTION auto_update_turnover_rate()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE inventory_items
    SET inventory_turnover_rate =
        COALESCE((cost_per_unit * total_units_sold) / NULLIF((beginning_inventory + ending_inventory) / 2, 0), 0)
    WHERE item_id = NEW.item_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER TR_Auto_Update_Turnover_Rate
AFTER UPDATE ON inventory_items
FOR EACH ROW
EXECUTE FUNCTION auto_update_turnover_rate();
