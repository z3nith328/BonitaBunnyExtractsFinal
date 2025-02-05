CREATE OR REPLACE FUNCTION auto_create_return_record()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.status = 'Returned' THEN
        INSERT INTO returns (order_id, sub_order_id, return_reason, refund_amount, return_requested_at)
        SELECT
            NEW.order_id,
            sub_orders.sub_order_id,
            'Customer Request', -- Default reason, can be updated manually
            SUM(sub_orders.discounted_sub_order_price),
            NOW()
        FROM orders sub_orders
        WHERE sub_orders.order_id = NEW.order_id
        GROUP BY sub_orders.sub_order_id;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_auto_create_return_record
AFTER INSERT ON order_status_tracking
FOR EACH ROW
EXECUTE FUNCTION auto_create_return_record();
