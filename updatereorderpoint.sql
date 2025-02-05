CREATE OR REPLACE FUNCTION update_reorder_point()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE inventory_safety_stock
    SET reorder_point = safety_stock_level + (SELECT AVG(lead_time_variability * demand_variability) FROM inventory_safety_stock)
    WHERE item_id = NEW.item_id;
   
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_update_reorder_point
AFTER UPDATE ON inventory_safety_stock
FOR EACH ROW
WHEN (OLD.safety_stock_level IS DISTINCT FROM NEW.safety_stock_level OR
      OLD.lead_time_variability IS DISTINCT FROM NEW.lead_time_variability OR
      OLD.demand_variability IS DISTINCT FROM NEW.demand_variability)
EXECUTE FUNCTION update_reorder_point();
