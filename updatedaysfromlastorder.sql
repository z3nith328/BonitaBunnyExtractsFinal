CREATE OR REPLACE FUNCTION update_days_since_last_order()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE past_suppliers
    SET days_since_last_order = EXTRACT(DAY FROM NOW() - last_order_date)
    WHERE past_supplier_id = NEW.past_supplier_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER TR_Update_Days_Since_Last_Order
AFTER UPDATE ON past_suppliers
FOR EACH ROW
EXECUTE FUNCTION update_days_since_last_order();
