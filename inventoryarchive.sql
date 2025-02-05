CREATE OR REPLACE FUNCTION archive_inventory_levels()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO historical_inventory_levels (item_id, current_level, cost_per_unit, supplier_id, supplier_name, current_price, input_type, last_reorder_date, archived_at)
    SELECT
        NEW.item_id,
        NEW.current_level,
        NEW.cost_per_unit,
        NEW.supplier_id,
        NEW.supplier_name,
        NEW.current_price,
        NEW.input_type,
        NEW.last_reorder_date,
        NOW()
    FROM inventory_levels
    WHERE inventory_levels.item_id = NEW.item_id;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_archive_inventory_levels
AFTER UPDATE ON inventory_levels
FOR EACH ROW
EXECUTE FUNCTION archive_inventory_levels();
