CREATE OR REPLACE FUNCTION update_refund_on_status_change()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.return_status = 'Refunded' THEN
        UPDATE returns
        SET refund_amount = COALESCE((
            SELECT SUM(discounted_sub_order_price)
            FROM orders sub_orders
            WHERE sub_orders.order_id = NEW.order_id
              AND sub_orders.sub_order_id = NEW.sub_order_id
        ), 0)
        WHERE return_id = NEW.return_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tr_update_refund_on_status_change
AFTER UPDATE OF return_status ON returns
FOR EACH ROW
WHEN (NEW.return_status = 'Refunded')
EXECUTE FUNCTION update_refund_on_status_change();
