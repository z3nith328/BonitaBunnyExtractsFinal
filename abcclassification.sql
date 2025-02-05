CREATE OR REPLACE FUNCTION classify_abc_category() RETURNS TRIGGER AS $$
BEGIN
    IF NEW.revenue_contribution >= 80 THEN
        NEW.abc_category := 'A';
    ELSIF NEW.revenue_contribution >= 50 THEN
        NEW.abc_category := 'B';
    ELSE
        NEW.abc_category := 'C';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER TR_Classify_ABC
BEFORE INSERT OR UPDATE ON inventory_abc_classification
FOR EACH ROW EXECUTE FUNCTION classify_abc_category();
