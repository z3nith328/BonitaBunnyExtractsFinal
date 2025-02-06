CREATE FUNCTION validate_status_progression() RETURNS TRIGGER AS $$
DECLARE
    last_status TEXT;
BEGIN
    SELECT status INTO last_status
    FROM order_status_tracking
    WHERE order_id = NEW.order_id
    ORDER BY status_timestamp DESC
    LIMIT 1;

    IF last_status = 'Received' AND NEW.status NOT IN ('Processing', 'Canceled') THEN
        RAISE EXCEPTION 'Invalid status transition from Received';
    ELSIF last_status = 'Processing' AND NEW.status NOT IN ('Shipped', 'Canceled') THEN
        RAISE EXCEPTION 'Invalid status transition from Processing';
    ELSIF last_status = 'Shipped' AND NEW.status NOT IN ('Delivered', 'Returned') THEN
        RAISE EXCEPTION 'Invalid status transition from Shipped';
    ELSIF last_status = 'Delivered' OR last_status = 'Canceled' THEN
        RAISE EXCEPTION 'Cannot update status after order is Delivered or Canceled';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tr_validate_status_progression
BEFORE INSERT OR UPDATE ON order_status_tracking
FOR EACH ROW EXECUTE FUNCTION validate_status_progression();

CREATE INDEX idx_order_status_tracking_order_id ON order_status_tracking(order_id, status_timestamp DESC);
```
