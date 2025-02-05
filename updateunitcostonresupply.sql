CREATE OR REPLACE FUNCTION update_supplier_cost()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE inventory_levels
    SET cost_per_unit = NEW.last_order_unit_cost
    WHERE item_id = NEW.item_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_supplier_update_cost
AFTER UPDATE ON suppliers
FOR EACH ROW
EXECUTE FUNCTION update_supplier_cost();
