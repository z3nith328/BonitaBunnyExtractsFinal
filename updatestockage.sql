CREATE OR REPLACE FUNCTION update_stock_age_days()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE inventory_items
    SET stock_age_days = EXTRACT(DAY FROM NOW() - created_at)
    WHERE item_id = NEW.item_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER TR_Update_Stock_Age
AFTER UPDATE ON inventory_items
FOR EACH ROW
EXECUTE FUNCTION update_stock_age_days();
