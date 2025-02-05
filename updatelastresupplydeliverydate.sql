CREATE OR REPLACE FUNCTION update_last_delivery_date()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE suppliers
    SET last_delivery_date = NOW()
    WHERE supplier_id = NEW.supplier_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_update_last_delivery_date
AFTER INSERT ON inventory_levels
FOR EACH ROW
EXECUTE FUNCTION update_last_delivery_date();
