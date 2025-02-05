CREATE OR REPLACE FUNCTION update_total_order_price()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE orders
    SET total_order_price = shipping_fee + (
        SELECT SUM(subtotal_amount)
        FROM orders sub_orders
        WHERE sub_orders.order_id = NEW.order_id
    )
    WHERE orders.order_id = NEW.order_id;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_update_total_order_price
AFTER INSERT OR UPDATE ON orders
FOR EACH ROW
EXECUTE FUNCTION update_total_order_price();
