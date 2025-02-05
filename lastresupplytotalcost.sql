CREATE OR REPLACE FUNCTION update_last_order_total_cost()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE suppliers
    SET last_order_total_cost = COALESCE(last_order_total_cost, 0) + NEW.last_order_total_cost
    WHERE supplier_id = NEW.supplier_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_update_last_order_total_cost
AFTER INSERT ON resupply_schedule
FOR EACH ROW
EXECUTE FUNCTION update_last_order_total_cost();
