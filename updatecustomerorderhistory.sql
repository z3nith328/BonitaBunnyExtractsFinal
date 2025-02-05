CREATE OR REPLACE FUNCTION update_customer_order_history()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE customers
    SET
        total_orders = (
            SELECT COUNT(*) FROM orders WHERE orders.customer_id = NEW.customer_id
        ),
        total_spent = (
            SELECT SUM(subtotal_amount) FROM orders WHERE orders.customer_id = NEW.customer_id
        ),
        avg_order_value = (
            CASE
                WHEN total_orders = 0 THEN 0
                ELSE total_spent / total_orders
            END
        ),
        first_order_date = (
            SELECT MIN(order_date) FROM orders WHERE orders.customer_id = NEW.customer_id
        ),
        last_order_date = (
            SELECT MAX(order_date) FROM orders WHERE orders.customer_id = NEW.customer_id
        )
    WHERE customers.customer_id = NEW.customer_id;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_update_customer_history
AFTER INSERT OR UPDATE ON orders
FOR EACH ROW
EXECUTE FUNCTION update_customer_order_history();
