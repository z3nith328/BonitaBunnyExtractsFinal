CREATE OR REPLACE FUNCTION update_inventory_last_updated()
RETURNS TRIGGER AS $$
BEGIN
    NEW.last_updated_date = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_update_inventory_last_updated
BEFORE UPDATE ON inventory_levels
FOR EACH ROW
EXECUTE FUNCTION update_inventory_last_updated();
