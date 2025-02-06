CREATE OR REPLACE FUNCTION fn_update_order_cogs()
RETURNS TRIGGER AS $$
BEGIN
    -- If an item is added, increase order_cogs
    IF TG_OP = 'INSERT' THEN
        UPDATE orders
        SET order_cogs = order_cogs + (NEW.item_cost * NEW.bead_qty)
        WHERE order_id = NEW.order_id;
    END IF;

    -- If an item is removed, decrease order_cogs
    IF TG_OP = 'DELETE' THEN
        UPDATE orders
        SET order_cogs = order_cogs - (OLD.item_cost * OLD.bead_qty)
        WHERE order_id = OLD.order_id;
    END IF;

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER TR_Update_Order_COGS_On_Item_Change
AFTER INSERT OR DELETE ON order_items
FOR EACH ROW
EXECUTE FUNCTION fn_update_order_cogs();
