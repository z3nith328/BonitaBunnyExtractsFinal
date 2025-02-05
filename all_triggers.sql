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

CREATE OR REPLACE FUNCTION archive_inventory_levels()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO historical_inventory_levels (item_id, current_level, cost_per_unit, supplier_id, supplier_name, current_price, input_type, last_reorder_date, archived_at)
    SELECT
        NEW.item_id,
        NEW.current_level,
        NEW.cost_per_unit,
        NEW.supplier_id,
        NEW.supplier_name,
        NEW.current_price,
        NEW.input_type,
        NEW.last_reorder_date,
        NOW()
    FROM inventory_levels
    WHERE inventory_levels.item_id = NEW.item_id;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_archive_inventory_levels
AFTER UPDATE ON inventory_levels
FOR EACH ROW
EXECUTE FUNCTION archive_inventory_levels();


CREATE OR REPLACE FUNCTION update_lead_time_variability()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE inventory_safety_stock
    SET lead_time_variability = (
        SELECT STDDEV((jsonb_array_elements(supplier_lead_time_distribution)->>'lead_time_days')::INT)
        FROM inventory_safety_stock ils
        WHERE ils.item_id = NEW.item_id
    )
    WHERE inventory_safety_stock.item_id = NEW.item_id;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_update_lead_time_variability
AFTER INSERT OR UPDATE ON past_suppliers
FOR EACH ROW
EXECUTE FUNCTION update_lead_time_variability();

4. total_order_price
CREATE OR REPLACE FUNCTION update_total_order_price()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE orders
    SET total_order_price = shipping_fee + (
        SELECT SUM(subtotal_amount)
        FROM orders sub_orders
        WHERE sub_orders.order_id = NEW.order_id
    )
    WHERE orders.order_id = NEW.order_id;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_update_total_order_price
AFTER INSERT OR UPDATE ON orders
FOR EACH ROW
EXECUTE FUNCTION update_total_order_price();


CREATE OR REPLACE FUNCTION update_customer_order_history()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE customers
    SET
        total_orders = (
            SELECT COUNT(*) FROM orders WHERE orders.customer_id = NEW.customer_id
        ),
        total_spent = (
            SELECT SUM(subtotal_amount) FROM orders WHERE orders.customer_id = NEW.customer_id
        ),
        avg_order_value = (
            CASE
                WHEN total_orders = 0 THEN 0
                ELSE total_spent / total_orders
            END
        ),
        first_order_date = (
            SELECT MIN(order_date) FROM orders WHERE orders.customer_id = NEW.customer_id
        ),
        last_order_date = (
            SELECT MAX(order_date) FROM orders WHERE orders.customer_id = NEW.customer_id
        )
    WHERE customers.customer_id = NEW.customer_id;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_update_customer_history
AFTER INSERT OR UPDATE ON orders
FOR EACH ROW
EXECUTE FUNCTION update_customer_order_history();


CREATE OR REPLACE FUNCTION update_inventory_on_order_change()
RETURNS TRIGGER AS $$
BEGIN
    -- Reduce inventory when an order item is inserted
    IF TG_OP = 'INSERT' THEN
        UPDATE inventory_levels
        SET current_level = current_level - NEW.quantity
        WHERE item_id = NEW.item_id;
   
    -- Adjust inventory when an order item is updated
    ELSIF TG_OP = 'UPDATE' THEN
        UPDATE inventory_levels
        SET current_level = current_level - (NEW.quantity - OLD.quantity)
        WHERE item_id = NEW.item_id;

    -- Restore inventory when an order item is deleted
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE inventory_levels
        SET current_level = current_level + OLD.quantity
        WHERE item_id = OLD.item_id;
    END IF;
   
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_update_inventory_on_order_change
AFTER INSERT OR UPDATE OR DELETE ON order_items
FOR EACH ROW
EXECUTE FUNCTION update_inventory_on_order_change();


CREATE OR REPLACE FUNCTION update_inventory_demand_forecasting()
RETURNS TRIGGER AS $$
BEGIN
    -- Update historical sales volume
    UPDATE inventory_demand_forecasting
    SET historical_sales_volume = historical_sales_volume + NEW.quantity
    WHERE item_id = NEW.item_id;

    -- Update moving average demand (7-day moving average)
    UPDATE inventory_demand_forecasting
    SET moving_average_demand = (
        SELECT COALESCE(AVG(quantity), 0)
        FROM order_items
        WHERE item_id = NEW.item_id AND order_date >= NOW() - INTERVAL '7 days'
    )
    WHERE item_id = NEW.item_id;

    -- Update forecast accuracy
    UPDATE inventory_demand_forecasting
    SET forecast_accuracy = 1 - (
        ABS(forecasted_demand - historical_sales_volume) / NULLIF(forecasted_demand, 0)
    )
    WHERE item_id = NEW.item_id;

    -- Update demand trend indicator
    UPDATE inventory_demand_forecasting
    SET demand_trend_indicator =
        CASE
            WHEN moving_average_demand > (SELECT AVG(moving_average_demand) FROM inventory_demand_forecasting) THEN 'Increasing'
            WHEN moving_average_demand < (SELECT AVG(moving_average_demand) FROM inventory_demand_forecasting) THEN 'Decreasing'
            ELSE 'Stable'
        END
    WHERE item_id = NEW.item_id;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_update_inventory_demand_forecasting
AFTER INSERT ON order_items
FOR EACH ROW
EXECUTE FUNCTION update_inventory_demand_forecasting();


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


CREATE OR REPLACE FUNCTION update_resupply_schedule()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE resupply_schedule
    SET reorder_qty =
        CASE
            WHEN NEW.current_level < safety_stock_level THEN NEW.current_level * 1.5
            ELSE reorder_qty
        END,
        sugg_restock_date =
            CASE
                WHEN NEW.current_level < safety_stock_level THEN NOW() + INTERVAL '7 days'
                ELSE sugg_restock_date
            END,
        prev_week_demand_forecast = (
            SELECT AVG(quantity)
            FROM order_items
            WHERE item_id = NEW.item_id AND order_date >= NOW() - INTERVAL '7 days'
        )
    WHERE item_id = NEW.item_id;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_update_resupply_schedule
AFTER UPDATE ON inventory_levels
FOR EACH ROW
EXECUTE FUNCTION update_resupply_schedule();


CREATE OR REPLACE FUNCTION calculate_fill_rate()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE inventory_safety_stock
    SET fill_rate = (SELECT COUNT(*) FROM orders WHERE order_status = 'Delivered')::DECIMAL /
                    (SELECT COUNT(*) FROM orders) * 100
    WHERE item_id = NEW.item_id;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_calculate_fill_rate
AFTER INSERT OR UPDATE ON orders
FOR EACH ROW
EXECUTE FUNCTION calculate_fill_rate();


CREATE OR REPLACE FUNCTION update_order_status_tracking()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO order_status_tracking (order_id, status, status_timestamp)
    VALUES (NEW.order_id, NEW.order_status, NOW());

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_update_order_status_tracking
AFTER UPDATE ON orders
FOR EACH ROW
EXECUTE FUNCTION update_order_status_tracking();

CREATE OR REPLACE FUNCTION auto_create_return_record()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.status = 'Returned' THEN
        INSERT INTO returns (order_id, sub_order_id, return_reason, refund_amount, return_requested_at)
        SELECT
            NEW.order_id,
            sub_orders.sub_order_id,
            'Customer Request', -- Default reason, can be updated manually
            SUM(sub_orders.discounted_sub_order_price),
            NOW()
        FROM orders sub_orders
        WHERE sub_orders.order_id = NEW.order_id
        GROUP BY sub_orders.sub_order_id;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_auto_create_return_record
AFTER INSERT ON order_status_tracking
FOR EACH ROW
EXECUTE FUNCTION auto_create_return_record();


CREATE OR REPLACE FUNCTION calculate_avg_lead_time()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE inventory_safety_stock
    SET lead_time_variability = (
        SELECT AVG((jsonb_array_elements(supplier_lead_time_distribution)->>'lead_time_days')::INT)
        FROM inventory_safety_stock ils
        WHERE ils.item_id = NEW.item_id
    )
    WHERE item_id = NEW.item_id;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_calculate_avg_lead_time
AFTER UPDATE ON past_suppliers
FOR EACH ROW
EXECUTE FUNCTION calculate_avg_lead_time();

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


CREATE OR REPLACE FUNCTION add_stock_on_return()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE inventory_levels
    SET current_level = current_level + NEW.returned_quantity
    WHERE item_id = NEW.item_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_inventory_update_on_returns
AFTER INSERT ON returns
FOR EACH ROW
EXECUTE FUNCTION add_stock_on_return();


CREATE OR REPLACE FUNCTION add_stock_on_resupply()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE inventory_levels
    SET current_level = current_level + NEW.restock_quantity
    WHERE item_id = NEW.item_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_inventory_update_on_resupply
AFTER INSERT ON resupply_schedule
FOR EACH ROW
EXECUTE FUNCTION add_stock_on_resupply();


CREATE OR REPLACE FUNCTION update_supplier_cost()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE inventory_levels
    SET cost_per_unit = NEW.last_order_unit_cost
    WHERE item_id = NEW.item_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_supplier_update_cost
AFTER UPDATE ON suppliers
FOR EACH ROW
EXECUTE FUNCTION update_supplier_cost();

CREATE OR REPLACE FUNCTION recalculate_pricing()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE inventory_levels
    SET current_price = NEW.last_order_unit_cost * (1 + COALESCE((SELECT markup_percentage FROM inventory_items WHERE item_id = NEW.item_id), 0) / 100)
    WHERE item_id = NEW.item_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_recalculate_pricing_on_supplier_update
AFTER UPDATE ON suppliers
FOR EACH ROW
EXECUTE FUNCTION recalculate_pricing();


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


CREATE OR REPLACE FUNCTION update_reorder_date_on_resupply()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE inventory_levels
    SET last_reorder_date = NOW()
    WHERE item_id = NEW.item_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_update_reorder_date_on_supplier_resupply
AFTER INSERT ON resupply_schedule
FOR EACH ROW
EXECUTE FUNCTION update_reorder_date_on_resupply();

CREATE OR REPLACE FUNCTION update_last_order_date()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE suppliers
    SET last_order_date = NOW()
    WHERE supplier_id = NEW.supplier_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_update_last_order_date
AFTER INSERT ON resupply_schedule
FOR EACH ROW
EXECUTE FUNCTION update_last_order_date();


CREATE OR REPLACE FUNCTION update_last_delivery_date()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE suppliers
    SET last_delivery_date = NOW()
    WHERE supplier_id = NEW.supplier_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_update_last_delivery_date
AFTER INSERT ON inventory_levels
FOR EACH ROW
EXECUTE FUNCTION update_last_delivery_date();

CREATE OR REPLACE FUNCTION update_last_order_total_cost()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE suppliers
    SET last_order_total_cost = last_order_total_cost + NEW.last_order_total_cost
    WHERE supplier_id = NEW.supplier_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_update_last_order_total_cost
AFTER INSERT ON resupply_schedule
FOR EACH ROW
EXECUTE FUNCTION update_last_order_total_cost();

CREATE OR REPLACE FUNCTION update_reorder_qty_on_stock_change()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE resupply_schedule
    SET reorder_qty = (SELECT reorder_point FROM inventory_safety_stock WHERE inventory_safety_stock.item_id = NEW.item_id)
    WHERE item_id = NEW.item_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER TR_Update_Resupply_On_Stock_Change
AFTER UPDATE ON inventory_levels
FOR EACH ROW
EXECUTE FUNCTION update_reorder_qty_on_stock_change();


CREATE OR REPLACE FUNCTION auto_schedule_restock_on_demand_spike()
RETURNS TRIGGER AS $$
BEGIN
    IF (NEW.daily_item_sales > (OLD.daily_item_sales * 1.2)) THEN
        UPDATE resupply_schedule
        SET sugg_restock_date = NOW() + INTERVAL '2 days'
        WHERE item_id = NEW.item_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER TR_Auto_Schedule_Restock_On_Demand_Spike
AFTER UPDATE ON inventory_demand_forecasting
FOR EACH ROW
EXECUTE FUNCTION auto_schedule_restock_on_demand_spike();


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

CREATE OR REPLACE FUNCTION fn_update_sales_velocity_and_days_on_hand()
RETURNS TRIGGER AS $$
BEGIN
    -- Update item_sales_velocity_weekly (Runs Weekly on Monday)
    IF date_part('dow', CURRENT_DATE) = 1 THEN
        UPDATE inventory_items
        SET item_sales_velocity_weekly = (
            SELECT COALESCE(SUM(quantity), 0) / 7
            FROM order_items oi
            JOIN orders o ON oi.order_id = o.order_id
            WHERE oi.item_id = NEW.item_id
            AND o.order_date >= CURRENT_DATE - INTERVAL '7 days'
        )
        WHERE item_id = NEW.item_id;
    END IF;

    -- Update days_on_hand (Runs Daily at Midnight)
    UPDATE inventory_items
    SET days_on_hand = (
        SELECT CASE
            WHEN current_level = 0 THEN NULL
            ELSE current_level / NULLIF(item_sales_velocity_weekly, 0)
        END
    )
    WHERE item_id = NEW.item_id;

    -- Update prev_week_forecast_variance
    UPDATE resupply_schedule
    SET prev_week_forecast_variance =
        ABS(prev_week_demand_forecast - (
            SELECT COALESCE(SUM(quantity), 0)
            FROM order_items oi
            JOIN orders o ON oi.order_id = o.order_id
            WHERE oi.item_id = NEW.item_id
            AND o.order_date >= CURRENT_DATE - INTERVAL '7 days'
        )) / NULLIF(prev_week_demand_forecast, 0)
    WHERE item_id = NEW.item_id;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Auto-updates `current_level`, `reorder_qty`, and `days_on_hand` when inventory stock changes.
CREATE OR REPLACE FUNCTION update_resupply_on_stock_change()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE resupply_schedule
    SET current_level = NEW.current_level,
        reorder_qty = CASE WHEN NEW.current_level < (SELECT reorder_point FROM inventory_safety_stock WHERE item_id = NEW.item_id)
                           THEN (SELECT safety_stock_level FROM inventory_safety_stock WHERE item_id = NEW.item_id)
                           ELSE reorder_qty END,
        days_on_hand = (NEW.current_level / (SELECT daily_item_sales FROM resupply_schedule WHERE item_id = NEW.item_id))
    WHERE item_id = NEW.item_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER TR_Update_Resupply_On_Stock_Change
AFTER UPDATE ON inventory_levels
FOR EACH ROW
EXECUTE FUNCTION update_resupply_on_stock_change();


-- Recalculates `reorder_qty` when stock falls below `reorder_point`
CREATE OR REPLACE FUNCTION update_reorder_qty_on_threshold()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE resupply_schedule
    SET reorder_qty = (SELECT safety_stock_level FROM inventory_safety_stock WHERE item_id = NEW.item_id)
    WHERE item_id = NEW.item_id AND NEW.current_level < (SELECT reorder_point FROM inventory_safety_stock WHERE item_id = NEW.item_id);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER TR_Update_Reorder_Qty_On_Threshold
AFTER UPDATE ON inventory_levels
FOR EACH ROW
EXECUTE FUNCTION update_reorder_qty_on_threshold();


-- Updates `item_sales_velocity_weekly` every week
CREATE OR REPLACE FUNCTION update_sales_velocity_weekly()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE resupply_schedule
    SET item_sales_velocity_weekly = (SELECT SUM(quantity) / 7 FROM order_items WHERE item_id = NEW.item_id AND order_date >= NOW() - INTERVAL '7 days')
    WHERE item_id = NEW.item_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER TR_Update_Sales_Velocity_Weekly
AFTER INSERT OR UPDATE ON order_items
FOR EACH ROW
WHEN (date_part('dow', NOW()) = 1)  -- Runs every Monday
EXECUTE FUNCTION update_sales_velocity_weekly();


-- Updates `supplier_lead_time` when `supplier_lead_time_distribution` changes
CREATE OR REPLACE FUNCTION update_supplier_lead_time()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE resupply_schedule
    SET supplier_lead_time = (SELECT AVG((lead_time->>'lead_time_days')::INT) FROM jsonb_array_elements((SELECT supplier_lead_time_distribution FROM inventory_safety_stock WHERE item_id = NEW.item_id)) AS lead_time)
    WHERE item_id = NEW.item_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER TR_Update_Supplier_Lead_Time
AFTER UPDATE ON inventory_safety_stock
FOR EACH ROW
EXECUTE FUNCTION update_supplier_lead_time();


-- Updates `last_order_date` when a new order is placed with the supplier
CREATE OR REPLACE FUNCTION update_last_order_date()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE resupply_schedule
    SET last_order_date = NOW()
    WHERE supplier_id = NEW.supplier_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER TR_Update_Last_Order_Date
AFTER INSERT ON suppliers
FOR EACH ROW
EXECUTE FUNCTION update_last_order_date();

-- Auto-updates `sugg_restock_date` based on forecasted demand and stock levels.
CREATE OR REPLACE FUNCTION update_sugg_restock_date()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE resupply_schedule
    SET sugg_restock_date = NOW() + INTERVAL '1 day' *
                            (SELECT CEIL(reorder_qty / daily_item_sales)
                             FROM resupply_schedule WHERE item_id = NEW.item_id)
    WHERE item_id = NEW.item_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER TR_Update_Sugg_Restock_Date
AFTER UPDATE ON resupply_schedule
FOR EACH ROW
EXECUTE FUNCTION update_sugg_restock_date();

-- When a new supplier order is placed, the previous supplier is moved to `past_suppliers`
CREATE OR REPLACE FUNCTION auto_update_supplier_archive()
RETURNS TRIGGER AS $$
BEGIN
    -- Archive old supplier before adding a new one
    INSERT INTO past_suppliers (
        supplier_id, supplier_name, item_id, last_order_qty, last_order_date,
        last_delivery_date, last_order_breakage, last_order_total_cost,
        last_order_unit_cost, current_supplier_flag, archived_at
    )
    SELECT
        OLD.supplier_id, OLD.supplier_name, OLD.item_id, OLD.last_order_qty, OLD.last_order_date,
        OLD.last_delivery_date, OLD.last_order_breakage, OLD.last_order_total_cost,
        OLD.last_order_unit_cost, FALSE, NOW()
    FROM suppliers AS OLD
    WHERE OLD.supplier_id = NEW.supplier_id;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER TR_Auto_Update_Supplier_Archive
AFTER UPDATE ON suppliers
FOR EACH ROW
WHEN (OLD.supplier_id IS DISTINCT FROM NEW.supplier_id)
EXECUTE FUNCTION auto_update_supplier_archive();


-- Auto-updates `days_since_last_order` daily
CREATE OR REPLACE FUNCTION update_days_since_last_order()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE past_suppliers
    SET days_since_last_order = EXTRACT(DAY FROM NOW() - last_order_date)
    WHERE past_supplier_id = NEW.past_supplier_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER TR_Update_Days_Since_Last_Order
AFTER UPDATE ON past_suppliers
FOR EACH ROW
EXECUTE FUNCTION update_days_since_last_order();

-- Ensures `stock_age_days` updates daily
CREATE OR REPLACE FUNCTION update_stock_age_days()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE inventory_items
    SET stock_age_days = EXTRACT(DAY FROM NOW() - created_at)
    WHERE item_id = NEW.item_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER TR_Update_Stock_Age
AFTER UPDATE ON inventory_items
FOR EACH ROW
EXECUTE FUNCTION update_stock_age_days();

-- Ensures `inventory_turnover_rate` is recalculated on stock changes
CREATE OR REPLACE FUNCTION auto_update_turnover_rate()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE inventory_items
    SET inventory_turnover_rate =
        COALESCE((cost_per_unit * total_units_sold) / ((beginning_inventory + ending_inventory) / 2), 0)
    WHERE item_id = NEW.item_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER TR_Auto_Update_Turnover_Rate
AFTER UPDATE ON inventory_items
FOR EACH ROW
EXECUTE FUNCTION auto_update_turnover_rate();

-- Automatically moves past inventory records to historical_inventory_levels on significant stock changes
CREATE OR REPLACE FUNCTION auto_archive_inventory_levels()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO historical_inventory_levels (
        item_id, current_level, cost_per_unit, supplier_id, supplier_name,
        current_price, input_type, last_reorder_date, archived_at
    )
    SELECT
        OLD.item_id, OLD.current_level, OLD.cost_per_unit, OLD.supplier_id, OLD.supplier_name,
        OLD.current_price, OLD.input_type, OLD.last_reorder_date, NOW()
    FROM inventory_levels
    WHERE OLD.item_id = NEW.item_id
        AND (OLD.current_level != NEW.current_level OR OLD.cost_per_unit != NEW.cost_per_unit);

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER TR_Auto_Archive_Inventory_Levels
AFTER UPDATE ON inventory_levels
FOR EACH ROW
EXECUTE FUNCTION auto_archive_inventory_levels();

-- Auto-updates `reorder_point` whenever `safety_stock_level`, `lead_time_variability`, or `demand_variability` changes.
CREATE OR REPLACE FUNCTION update_reorder_point()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE inventory_safety_stock
    SET reorder_point = safety_stock_level + (AVG(daily_demand) * AVG(lead_time_days))
    WHERE item_id = NEW.item_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER TR_Update_Reorder_Point
AFTER UPDATE ON inventory_safety_stock
FOR EACH ROW
EXECUTE FUNCTION update_reorder_point();

-- Auto-updates `forecast_accuracy`, `moving_average_demand`, and `demand_trend_indicator` when order_items data updates.
CREATE OR REPLACE FUNCTION update_inventory_demand_forecasting()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE inventory_demand_forecasting
    SET
        forecast_accuracy = (1 - (ABS(NEW.forecasted_demand -
            (SELECT COALESCE(SUM(order_items.quantity), 1)
             FROM order_items
             WHERE order_items.item_id = NEW.item_id))
        ) /
        (SELECT COALESCE(SUM(order_items.quantity), 1)
         FROM order_items
         WHERE order_items.item_id = NEW.item_id)),
       
        moving_average_demand = (SELECT COALESCE(SUM(order_items.quantity) / COUNT(DISTINCT order_items.order_id), 0)
                                 FROM order_items
                                 WHERE order_items.item_id = NEW.item_id),

        demand_trend_indicator = CASE
            WHEN moving_average_demand > (SELECT moving_average_demand FROM inventory_demand_forecasting WHERE item_id = NEW.item_id) THEN 'Increasing'
            WHEN moving_average_demand < (SELECT moving_average_demand FROM inventory_demand_forecasting WHERE item_id = NEW.item_id) THEN 'Decreasing'
            ELSE 'Stable'
        END
    WHERE item_id = NEW.item_id;
   
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER TR_Update_Inventory_Demand
AFTER UPDATE ON order_items
FOR EACH ROW
EXECUTE FUNCTION update_inventory_demand_forecasting();

-- Auto-Classify ABC Category Based on Revenue Contribution
CREATE OR REPLACE FUNCTION classify_abc_category() RETURNS TRIGGER AS $$
BEGIN
    UPDATE inventory_abc_classification
    SET abc_category =
        CASE
            WHEN revenue_contribution >= 80 THEN 'A'
            WHEN revenue_contribution >= 50 THEN 'B'
            ELSE 'C'
        END
    WHERE item_id = NEW.item_id;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER TR_Classify_ABC
AFTER INSERT OR UPDATE ON inventory_abc_classification
FOR EACH ROW EXECUTE FUNCTION classify_abc_category();

CREATE FUNCTION insert_initial_status() RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO order_status_tracking (order_id, status, status_timestamp)
    VALUES (NEW.order_id, 'Received', NOW());
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tr_auto_insert_received_status
AFTER INSERT ON orders
FOR EACH ROW EXECUTE FUNCTION insert_initial_status();

CREATE FUNCTION validate_status_progression() RETURNS TRIGGER AS $$
DECLARE
    last_status TEXT;
BEGIN
    SELECT status INTO last_status
    FROM order_status_tracking
    WHERE order_id = NEW.order_id
    ORDER BY status_timestamp DESC
    LIMIT 1;

    -- Enforce status progression rules
    IF last_status = 'Received' AND NEW.status NOT IN ('Processing', 'Canceled') THEN
        RAISE EXCEPTION 'Invalid status transition from Received';
    ELSIF last_status = 'Processing' AND NEW.status NOT IN ('Shipped', 'Canceled') THEN
        RAISE EXCEPTION 'Invalid status transition from Processing';
    ELSIF last_status = 'Shipped' AND NEW.status NOT IN ('Delivered', 'Returned') THEN
        RAISE EXCEPTION 'Invalid status transition from Shipped';
    ELSIF last_status = 'Delivered' OR last_status = 'Canceled' THEN
        RAISE EXCEPTION 'Cannot update status after order is Delivered or Canceled';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tr_validate_status_progression
BEFORE INSERT OR UPDATE ON order_status_tracking
FOR EACH ROW EXECUTE FUNCTION validate_status_progression();

CREATE FUNCTION update_status_history() RETURNS TRIGGER AS $$
BEGIN
    UPDATE orders
    SET status_history = status_history || jsonb_build_object(
        TO_CHAR(NEW.status_timestamp, 'YYYY-MM-DD HH24:MI'), NEW.status
    )
    WHERE order_id = NEW.order_id;
   
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tr_update_status_history
AFTER INSERT OR UPDATE ON order_status_tracking
FOR EACH ROW EXECUTE FUNCTION update_status_history();

CREATE OR REPLACE FUNCTION update_order_status_on_shipment()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE orders
    SET order_status = 'Shipped'
    WHERE order_id = NEW.order_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tr_update_order_status_on_shipment
AFTER INSERT ON shipments
FOR EACH ROW
EXECUTE FUNCTION update_order_status_on_shipment();

-- Auto-Update actual_delivery_date when an order is marked as 'Delivered'
CREATE OR REPLACE FUNCTION update_delivery_date_on_order_status()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.order_status = 'Delivered' THEN
        UPDATE shipments
        SET actual_delivery_date = CURRENT_TIMESTAMP
        WHERE order_id = NEW.order_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tr_update_actual_delivery_date
AFTER UPDATE OF order_status ON orders
FOR EACH ROW
WHEN (NEW.order_status = 'Delivered')
EXECUTE FUNCTION update_delivery_date_on_order_status();

CREATE OR REPLACE FUNCTION update_refund_on_status_change()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.return_status = 'Refunded' THEN
        UPDATE returns
        SET refund_amount = (SELECT SUM(discounted_sub_order_price)
                             FROM orders sub_orders
                             WHERE sub_orders.order_id = NEW.order_id
                               AND sub_orders.sub_order_id = NEW.sub_order_id)
        WHERE return_id = NEW.return_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tr_update_refund_on_status_change
AFTER UPDATE OF return_status ON returns
FOR EACH ROW
WHEN (NEW.return_status = 'Refunded')
EXECUTE FUNCTION update_refund_on_status_change();

-- Auto-Update inventory levels when an item is Restocked
CREATE OR REPLACE FUNCTION update_inventory_on_restock()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.restock_status = 'Restocked' THEN
        UPDATE inventory_levels
        SET current_level = current_level + (SELECT SUM(quantity)
                                             FROM order_items
                                             WHERE order_id = NEW.order_id
                                             AND sub_order_id = NEW.sub_order_id)
        WHERE item_id IN (SELECT item_id FROM order_items
                          WHERE order_id = NEW.order_id
                          AND sub_order_id = NEW.sub_order_id);
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tr_update_inventory_on_restock
AFTER UPDATE OF restock_status ON returns
FOR EACH ROW
WHEN (NEW.restock_status = 'Restocked')
EXECUTE FUNCTION update_inventory_on_restock();

CREATE OR REPLACE FUNCTION fn_update_order_cogs()
RETURNS TRIGGER AS $$
BEGIN
    -- If an item is added, increase order_cogs
    IF TG_OP = 'INSERT' THEN
        UPDATE orders
        SET order_cogs = order_cogs + (NEW.item_cost * NEW.bead_qty)
        WHERE order_id = NEW.order_id;
    END IF;

    -- If an item is removed, decrease order_cogs
    IF TG_OP = 'DELETE' THEN
        UPDATE orders
        SET order_cogs = order_cogs - (OLD.item_cost * OLD.bead_qty)
        WHERE order_id = OLD.order_id;
    END IF;

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER TR_Update_Order_COGS_On_Item_Change
AFTER INSERT OR DELETE ON order_items
FOR EACH ROW
EXECUTE FUNCTION fn_update_order_cogs();

CREATE OR REPLACE FUNCTION fn_validate_item_type()
RETURNS TRIGGER AS $$
DECLARE
    expected_category TEXT;
BEGIN
    -- Get the expected category from item_matrix
    SELECT category INTO expected_category
    FROM item_matrix
    WHERE item_id = NEW.item_id;

    -- If the category does not match, prevent the insert/update
    IF expected_category IS DISTINCT FROM NEW.item_type THEN
        RAISE EXCEPTION 'Item type mismatch: % does not match %', NEW.item_type, expected_category;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER TR_Validate_Item_Type_Against_Item_Matrix
BEFORE INSERT OR UPDATE ON order_items
FOR EACH ROW
EXECUTE FUNCTION fn_validate_item_type();

CREATE OR REPLACE FUNCTION fn_update_inventory_on_order()
RETURNS TRIGGER AS $$
BEGIN
    -- If an item is added, reduce inventory
    IF TG_OP = 'INSERT' THEN
        UPDATE inventory_levels
        SET current_level = current_level - NEW.bead_qty
        WHERE item_id = NEW.item_id;
    END IF;

    -- If an item is removed or order canceled, restore inventory
    IF TG_OP = 'DELETE' THEN
        UPDATE inventory_levels
        SET current_level = current_level + OLD.bead_qty
        WHERE item_id = OLD.item_id;
    END IF;

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER TR_Update_Inventory_On_Order
AFTER INSERT OR DELETE ON order_items
FOR EACH ROW
EXECUTE FUNCTION fn_update_inventory_on_order();

CREATE OR REPLACE FUNCTION fn_calculate_sales_velocity(p_item_id INT)
RETURNS DECIMAL(10,2) AS $$
DECLARE
    weekly_sales DECIMAL(10,2);
BEGIN
    SELECT COALESCE(SUM(bead_qty) / 4.0, 0)
    INTO weekly_sales
    FROM order_items
    WHERE item_id = p_item_id
    AND created_at >= NOW() - INTERVAL '30 days';

    RETURN weekly_sales;
END;
$$ LANGUAGE plpgsql;
