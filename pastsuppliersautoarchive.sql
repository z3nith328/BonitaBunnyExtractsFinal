CREATE OR REPLACE FUNCTION auto_update_supplier_archive()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO past_suppliers (
        supplier_id, supplier_name, item_id, last_order_qty, last_order_date,
        last_delivery_date, last_order_breakage, last_order_total_cost,
        last_order_unit_cost, current_supplier_flag, archived_at
    )
    VALUES (
        OLD.supplier_id, OLD.supplier_name, OLD.item_id, OLD.last_order_qty, OLD.last_order_date,
        OLD.last_delivery_date, OLD.last_order_breakage, OLD.last_order_total_cost,
        OLD.last_order_unit_cost, FALSE, NOW()
    );

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER TR_Auto_Update_Supplier_Archive
AFTER UPDATE ON suppliers
FOR EACH ROW
WHEN (OLD.supplier_id IS DISTINCT FROM NEW.supplier_id)
EXECUTE FUNCTION auto_update_supplier_archive();
