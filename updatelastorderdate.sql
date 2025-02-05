CREATE OR REPLACE FUNCTION update_last_order_date()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE suppliers
    SET last_order_date = NOW()
    WHERE supplier_id = NEW.supplier_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_update_last_order_date
AFTER INSERT ON resupply_schedule
FOR EACH ROW
EXECUTE FUNCTION update_last_order_date();
