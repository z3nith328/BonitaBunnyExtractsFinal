CREATE OR REPLACE FUNCTION update_sugg_restock_date()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE resupply_schedule
    SET sugg_restock_date = NOW() + INTERVAL '1 day' *
                            CEIL(NEW.reorder_qty / NEW.daily_item_sales)
    WHERE item_id = NEW.item_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER TR_Update_Sugg_Restock_Date
AFTER UPDATE ON resupply_schedule
FOR EACH ROW
EXECUTE FUNCTION update_sugg_restock_date();
