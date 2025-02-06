CREATE OR REPLACE FUNCTION update_order_status_tracking()
RETURNS VOID AS $$
BEGIN
    BEGIN
        INSERT INTO order_status_tracking (order_id, status, status_timestamp)
        SELECT o.order_id, o.order_status, NOW()
        FROM orders o
        WHERE NOT EXISTS (
            SELECT 1 FROM order_status_tracking ost
            WHERE ost.order_id = o.order_id
            AND ost.status = o.order_status
        );
    EXCEPTION WHEN OTHERS THEN
        INSERT INTO job_error_logs (job_name, error_message)
        VALUES ('update_order_tracking', SQLERRM);
END;
$$ LANGUAGE plpgsql;

SELECT cron.schedule(
    'update_order_status_tracking',
    '0 * * * *',  -- Runs every hour
    'SELECT fn_log_order_status_changes();'
);
