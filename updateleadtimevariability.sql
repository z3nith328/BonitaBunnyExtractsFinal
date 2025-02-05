CREATE OR REPLACE FUNCTION update_lead_time_variability()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE inventory_safety_stock
    SET lead_time_variability = (
        SELECT STDDEV((jsonb_array_elements(supplier_lead_time_distribution)->>'lead_time_days')::INT)
        FROM inventory_safety_stock ils
        WHERE ils.item_id = NEW.item_id
    )
    WHERE inventory_safety_stock.item_id = NEW.item_id;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_update_lead_time_variability
AFTER INSERT OR UPDATE ON past_suppliers
FOR EACH ROW
EXECUTE FUNCTION update_lead_time_variability();
