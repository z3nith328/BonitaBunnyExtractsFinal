CREATE OR REPLACE FUNCTION fn_calculate_sales_velocity(p_item_id INT)
RETURNS DECIMAL(10,2) AS $$
DECLARE
    weekly_sales DECIMAL(10,2);
BEGIN
    SELECT COALESCE(SUM(bead_qty) / 4.0, 0)
    INTO weekly_sales
    FROM order_items
    WHERE item_id = p_item_id
    AND created_at >= NOW() - INTERVAL '30 days';

    RETURN weekly_sales;
END;
$$ LANGUAGE plpgsql;

CREATE INDEX idx_order_items_item_id_created_at ON order_items (item_id, created_at);
CREATE INDEX idx_inventory_levels_item_id ON inventory_levels (item_id);

CREATE TRIGGER trg_calculate_sales_velocity
AFTER INSERT OR UPDATE ON order_items
FOR EACH ROW
EXECUTE FUNCTION fn_calculate_sales_velocity(NEW.item_id);
