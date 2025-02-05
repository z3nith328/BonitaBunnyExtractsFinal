CREATE OR REPLACE FUNCTION update_order_status_tracking()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO order_status_tracking (order_id, status, status_timestamp)
    VALUES (NEW.order_id, NEW.order_status, NOW());

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_update_order_status_tracking
AFTER UPDATE ON orders
FOR EACH ROW
EXECUTE FUNCTION update_order_status_tracking();
