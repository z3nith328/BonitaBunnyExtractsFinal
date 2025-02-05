CREATE OR REPLACE FUNCTION calculate_fill_rate()
RETURNS TRIGGER AS $$
DECLARE
    delivered_count INT;
    total_count INT;
BEGIN
    SELECT COUNT(*) INTO delivered_count FROM orders WHERE order_status = 'Delivered';
    SELECT COUNT(*) INTO total_count FROM orders;

    UPDATE inventory_safety_stock
    SET fill_rate = (delivered_count::DECIMAL / NULLIF(total_count, 0)) * 100
    WHERE item_id = NEW.item_id;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_calculate_fill_rate
AFTER INSERT OR UPDATE ON orders
FOR EACH ROW
EXECUTE FUNCTION calculate_fill_rate();
