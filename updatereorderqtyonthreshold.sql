CREATE OR REPLACE FUNCTION update_ss_level_on_stock_change()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE resupply_schedule
    SET current_level = NEW.current_level,
        reorder_qty = CASE WHEN NEW.current_level < iss.reorder_point
                           THEN iss.safety_stock_level
                           ELSE reorder_qty END,
        days_on_hand = (NEW.current_level / rs.daily_item_sales)
    FROM inventory_safety_stock iss, resupply_schedule rs
    WHERE rs.item_id = NEW.item_id AND iss.item_id = NEW.item_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER TR_Update_Resupply_On_Stock_Change
AFTER UPDATE ON inventory_levels
FOR EACH ROW
EXECUTE FUNCTION update_ss_level_on_stock_change();
