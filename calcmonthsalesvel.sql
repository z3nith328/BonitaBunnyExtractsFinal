CREATE OR REPLACE FUNCTION fn_calculate_sales_velocity(p_item_id INT)
RETURNS DECIMAL(10,2) AS $$
DECLARE
    weekly_bead_sales DECIMAL(10,2);
    weekly_pendant_sales DECIMAL(10,2);
    weekly_cord_sales DECIMAL(10,2);
    total_weekly_sales DECIMAL(10,2);
BEGIN
    -- Calculate weekly bead sales
    SELECT COALESCE(SUM(bead_qty) / 4.0, 0)
    INTO weekly_bead_sales
    FROM order_items
    WHERE item_id = p_item_id
    AND created_at >= NOW() - INTERVAL '30 days'
    AND item_type = 'Bead';

    -- Calculate weekly pendant sales
    SELECT COALESCE(SUM(pendant_qty) / 4.0, 0)
    INTO weekly_pendant_sales
    FROM order_items
    WHERE item_id = p_item_id
    AND created_at >= NOW() - INTERVAL '30 days'
    AND item_type = 'Pendant';

    -- Calculate weekly cord sales
    SELECT COALESCE(SUM(cord_qty) / 4.0, 0)
    INTO weekly_cord_sales
    FROM order_items
    WHERE item_id = p_item_id
    AND created_at >= NOW() - INTERVAL '30 days'
    AND item_type = 'Cord';

    -- Sum up the total sales across all types
    total_weekly_sales := weekly_bead_sales + weekly_pendant_sales + weekly_cord_sales;

    RETURN total_weekly_sales;
END;
$$ LANGUAGE plpgsql;

CREATE INDEX idx_order_items_item_id_created_at ON order_items (item_id, created_at);
CREATE INDEX idx_inventory_levels_item_id ON inventory_levels (item_id);

CREATE TRIGGER trg_calculate_sales_velocity
AFTER INSERT OR UPDATE ON order_items
FOR EACH ROW
EXECUTE FUNCTION fn_calculate_sales_velocity(NEW.item_id);
