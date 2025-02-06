CREATE OR REPLACE FUNCTION update_reorder_qty_on_stock_change()
RETURNS TRIGGER AS $$
BEGIN
    IF OLD.current_level = NEW.current_level THEN
        RETURN NEW;
    END IF;

    UPDATE resupply_schedule
    SET reorder_qty = iss.reorder_point
    FROM inventory_safety_stock iss
    WHERE iss.item_id = NEW.item_id AND resupply_schedule.item_id = NEW.item_id;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER TR_Update_Resupply_On_Stock_Change
AFTER UPDATE ON inventory_levels
FOR EACH ROW
EXECUTE FUNCTION update_reorder_qty_on_stock_change();
