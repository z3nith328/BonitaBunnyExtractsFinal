CREATE OR REPLACE FUNCTION ensure_valid_item_input_type()
RETURNS TRIGGER AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM item_matrix WHERE item_id = NEW.item_id AND category = NEW.input_type) THEN
        RAISE EXCEPTION 'Invalid input_type: % does not match item_matrix.category', NEW.input_type;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_ensure_valid_item_input_type
BEFORE INSERT OR UPDATE ON inventory_levels
FOR EACH ROW
EXECUTE FUNCTION ensure_valid_item_input_type();
