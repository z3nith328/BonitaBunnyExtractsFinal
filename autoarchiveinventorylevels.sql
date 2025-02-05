CREATE OR REPLACE FUNCTION auto_archive_inventory_levels()
RETURNS TRIGGER AS $$
BEGIN
    IF OLD.current_level != NEW.current_level OR OLD.cost_per_unit != NEW.cost_per_unit THEN
        INSERT INTO historical_inventory_levels (
            item_id, current_level, cost_per_unit, supplier_id, supplier_name,
            current_price, input_type, last_reorder_date, archived_at
        )
        VALUES (
            OLD.item_id, OLD.current_level, OLD.cost_per_unit, OLD.supplier_id, OLD.supplier_name,
            OLD.current_price, OLD.input_type, OLD.last_reorder_date, NOW()
        );
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER TR_Auto_Archive_Inventory_Levels
AFTER UPDATE ON inventory_levels
FOR EACH ROW
EXECUTE FUNCTION auto_archive_inventory_levels();
