CREATE FUNCTION update_timestamps()
RETURNS TRIGGER AS $$
BEGIN
    -- Ensure first_listed_date is set only once
    IF NEW.first_listed_date IS NULL THEN
        NEW.first_listed_date := (SELECT MIN(created_at)
                                  FROM item_matrix
                                  WHERE item_id = NEW.item_id);
    END IF;

    -- Always update updated_at timestamp on any row update
    NEW.updated_at := CURRENT_TIMESTAMP;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_timestamps
BEFORE INSERT OR UPDATE ON item_matrix
FOR EACH ROW
EXECUTE FUNCTION update_timestamps();
