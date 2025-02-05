CREATE OR REPLACE FUNCTION populate_order_items()
RETURNS TRIGGER AS $$
BEGIN
    -- Delete existing order_items for the given sub_order_id
    DELETE FROM order_items WHERE order_id = NEW.order_id AND sub_order_id = NEW.sub_order_id;

    -- Insert new Cord records
    INSERT INTO order_items (order_id, sub_order_id, item_id, item_type, cord_type, cord_size, cord_wt, cord_cost, markup_percentage, cord_price, cord_disc)
    SELECT
        NEW.order_id,
        NEW.sub_order_id,
        (cord_list->>'item_id')::TEXT,
        'Cord',
        (cord_list->>'material')::TEXT,
        (cord_list->>'cord_size')::TEXT,
        (cord_list->>'cord_wt')::DECIMAL,
        (cord_list->>'cord_cost')::DECIMAL,
        (cord_list->>'markup_percentage')::DECIMAL,
        (cord_list->>'cord_price')::DECIMAL,
        (cord_list->>'cord_disc')::DECIMAL
    FROM jsonb_array_elements(NEW.cord_list) AS cord_list;

    -- Insert new Pendant records
    INSERT INTO order_items (order_id, sub_order_id, item_id, item_type, pendant_type, pendant_width, pendant_wt, pendant_cost, markup_percentage, pendant_price, pendant_disc)
    SELECT
        NEW.order_id,
        NEW.sub_order_id,
        (pendant_list->>'item_id')::TEXT,
        'Pendant',
        (pendant_list->>'material')::TEXT,
        (pendant_list->>'pendant_width')::DECIMAL,
        (pendant_list->>'pendant_wt')::DECIMAL,
        (pendant_list->>'pendant_cost')::DECIMAL,
        (pendant_list->>'markup_percentage')::DECIMAL,
        (pendant_list->>'pendant_price')::DECIMAL,
        (pendant_list->>'pendant_disc')::DECIMAL
    FROM jsonb_array_elements(NEW.pendant_list) AS pendant_list;

    -- Insert new Bead records
    INSERT INTO order_items (order_id, sub_order_id, item_id, item_type, bead_type, bead_diam, bead_wt, bead_cost, markup_percentage, bead_price, bead_disc)
    SELECT
        NEW.order_id,
        NEW.sub_order_id,
        (bead_list->>'item_id')::TEXT,
        'Bead',
        (bead_list->>'material')::TEXT,
        (bead_list->>'bead_diam')::DECIMAL,
        (bead_list->>'bead_wt')::DECIMAL,
        (bead_list->>'bead_cost')::DECIMAL,
        (bead_list->>'markup_percentage')::DECIMAL,
        (bead_list->>'bead_price')::DECIMAL,
        (bead_list->>'bead_disc')::DECIMAL
    FROM jsonb_array_elements(NEW.bead_list) AS bead_list;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_populate_order_items
AFTER INSERT OR UPDATE ON orders
FOR EACH ROW
EXECUTE FUNCTION populate_order_items();
