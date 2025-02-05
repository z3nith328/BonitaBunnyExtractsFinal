CREATE OR REPLACE FUNCTION add_stock_on_resupply()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE inventory_levels
    SET current_level = current_level + NEW.restock_quantity
    WHERE item_id = NEW.item_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_inventory_update_on_resupply
AFTER INSERT ON resupply_schedule
FOR EACH ROW
EXECUTE FUNCTION add_stock_on_resupply();
