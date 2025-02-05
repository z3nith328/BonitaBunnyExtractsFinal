CREATE OR REPLACE FUNCTION update_reorder_date_on_resupply()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE inventory_levels
    SET last_reorder_date = NOW()
    WHERE item_id = NEW.item_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_update_reorder_date_on_supplier_resupply
AFTER INSERT ON resupply_schedule
FOR EACH ROW
EXECUTE FUNCTION update_reorder_date_on_resupply();
