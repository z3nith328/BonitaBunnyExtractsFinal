CREATE FUNCTION update_status_history() RETURNS TRIGGER AS $$
BEGIN
    UPDATE orders
    SET status_history = status_history || jsonb_build_object(
        TO_CHAR(NEW.status_timestamp, 'YYYY-MM-DD HH24:MI'), NEW.status
    )
    WHERE order_id = NEW.order_id;
   
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tr_update_status_history
AFTER INSERT OR UPDATE ON order_status_tracking
FOR EACH ROW EXECUTE FUNCTION update_status_history();
