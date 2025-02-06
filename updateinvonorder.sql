CREATE OR REPLACE FUNCTION fn_update_inventory_on_order()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE inventory_levels
        SET current_level = current_level - NEW.bead_qty
        WHERE item_id = NEW.item_id;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE inventory_levels
        SET current_level = current_level + OLD.bead_qty
        WHERE item_id = OLD.item_id;
    END IF;

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER TR_Update_Inventory_On_Order
AFTER INSERT OR DELETE ON order_items
FOR EACH ROW
EXECUTE FUNCTION fn_update_inventory_on_order();
