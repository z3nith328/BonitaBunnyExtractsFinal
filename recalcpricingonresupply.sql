CREATE OR REPLACE FUNCTION recalculate_pricing()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE inventory_levels
    SET current_price = NEW.last_order_unit_cost * (1 + COALESCE((SELECT markup_percentage FROM inventory_items WHERE item_id = NEW.item_id), 0) / 100)
    WHERE item_id = NEW.item_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_recalculate_pricing_on_supplier_update
AFTER UPDATE ON suppliers
FOR EACH ROW
EXECUTE FUNCTION recalculate_pricing();
