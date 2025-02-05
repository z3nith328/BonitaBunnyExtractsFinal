CREATE OR REPLACE FUNCTION add_stock_on_return()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE inventory_levels
    SET current_level = current_level + NEW.returned_quantity
    WHERE item_id = NEW.item_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_inventory_update_on_returns
AFTER INSERT ON returns
FOR EACH ROW
EXECUTE FUNCTION add_stock_on_return();
