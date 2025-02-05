CREATE FUNCTION insert_initial_status() RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO order_status_tracking (order_id, status, status_timestamp)
    VALUES (NEW.order_id, 'Received', NOW());
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tr_auto_insert_received_status
AFTER INSERT ON orders
FOR EACH ROW EXECUTE FUNCTION insert_initial_status();
