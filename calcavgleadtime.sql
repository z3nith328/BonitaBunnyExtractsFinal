CREATE OR REPLACE FUNCTION calculate_avg_lead_time()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE inventory_safety_stock
    SET lead_time_variability = (
        SELECT AVG((jsonb_array_elements(supplier_lead_time_distribution)->>'lead_time_days')::INT)
        FROM inventory_safety_stock ils
        WHERE ils.item_id = NEW.item_id
    )
    WHERE item_id = NEW.item_id;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_calculate_avg_lead_time
AFTER UPDATE ON past_suppliers
FOR EACH ROW
EXECUTE FUNCTION calculate_avg_lead_time();
