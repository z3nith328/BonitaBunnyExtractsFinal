CREATE TRIGGER trg_update_reorder_point
AFTER UPDATE ON inventory_safety_stock
FOR EACH ROW
WHEN (OLD.safety_stock_level IS DISTINCT FROM NEW.safety_stock_level OR
      OLD.lead_time_variability IS DISTINCT FROM NEW.lead_time_variability OR
      OLD.demand_variability IS DISTINCT FROM NEW.demand_variability)
EXECUTE FUNCTION update_reorder_point();
