CREATE OR REPLACE FUNCTION update_order_status_tracking()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO order_status_tracking (order_id, status, status_timestamp)
    VALUES (NEW.order_id, NEW.order_status, NOW());

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

SELECT cron.schedule(
    'update_order_status_tracking',
    '0 * * * *',  -- Runs every hour
    'SELECT fn_log_order_status_changes();'
);
