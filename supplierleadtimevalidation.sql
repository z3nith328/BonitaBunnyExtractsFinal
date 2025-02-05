CREATE OR REPLACE FUNCTION validate_supplier_lead_time()
RETURNS TRIGGER AS $$
BEGIN
    IF (NEW.supplier_lead_time < 1 OR NEW.supplier_lead_time > 60) THEN
        RAISE EXCEPTION 'Invalid supplier lead time: must be between 1 and 60 days';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER TR_Validate_Supplier_Lead_Time
BEFORE INSERT OR UPDATE ON resupply_schedule
FOR EACH ROW
EXECUTE FUNCTION validate_supplier_lead_time();
