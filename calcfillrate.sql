CREATE OR REPLACE FUNCTION calculate_fill_rate()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE inventory_safety_stock
    SET fill_rate = (
        SELECT COUNT(*)::DECIMAL / NULLIF(total_orders, 0) * 100
        FROM (
            SELECT COUNT(*) AS delivered_orders
            FROM orders
            WHERE order_status = 'Delivered'
        ) AS delivered,
        (
            SELECT COUNT(*) AS total_orders
            FROM orders
        ) AS total
    )
    WHERE item_id = NEW.item_id;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
```
