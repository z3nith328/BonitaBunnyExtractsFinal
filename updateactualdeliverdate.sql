CREATE OR REPLACE FUNCTION update_delivery_date_on_order_status()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE shipments
    SET actual_delivery_date = CURRENT_TIMESTAMP
    WHERE order_id = NEW.order_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tr_update_actual_delivery_date
AFTER UPDATE OF order_status ON orders
FOR EACH ROW
WHEN (NEW.order_status = 'Delivered')
EXECUTE FUNCTION update_delivery_date_on_order_status();
