CREATE TABLE inventory_safety_stock (
    item_id INT PRIMARY KEY REFERENCES inventory_items(item_id) ON DELETE CASCADE,
   
    safety_stock_level INT GENERATED ALWAYS AS (
        Z * SQRT((lead_time_variability^2 * demand_variability^2) + (AVG(daily_demand) * lead_time_variability^2))
    ) STORED,

    lead_time_variability DECIMAL(10,2) GENERATED ALWAYS AS (
        (SELECT STDDEV((jsonb_array_elements(supplier_lead_time_distribution)->>'lead_time_days')::INT)
         FROM inventory_safety_stock ils
         WHERE ils.item_id = inventory_safety_stock.item_id)
    ) STORED,

    demand_variability DECIMAL(10,2) GENERATED ALWAYS AS (
        (SELECT STDDEV(sales_last_n_days)
         FROM sales_data
         WHERE sales_data.item_id = inventory_safety_stock.item_id)
    ) STORED,

    reorder_point INT GENERATED ALWAYS AS (
        safety_stock_level + (AVG(daily_demand) * AVG(lead_time_days))
    ) STORED,

    stock_depletion_rate DECIMAL(10,2) GENERATED ALWAYS AS (
        total_units_sold / total_days
    ) STORED,

    maximum_daily_demand INT GENERATED ALWAYS AS (
        (SELECT MAX(daily_sales) FROM sales_data WHERE sales_data.item_id = inventory_safety_stock.item_id)
    ) STORED,

    supplier_lead_time_distribution JSONB GENERATED ALWAYS AS (
        (SELECT jsonb_agg(
            jsonb_build_object(
                'item_id', item_id,
                'supplier_id', supplier_id,
                'lead_time_days', (last_delivery_date - last_order_date)
            )
        )
        FROM past_suppliers
        WHERE past_suppliers.item_id = inventory_safety_stock.item_id
        GROUP BY past_suppliers.item_id, past_suppliers.supplier_id)
    ) STORED,

    fill_rate DECIMAL(5,2) GENERATED ALWAYS AS (
        (total_fulfilled_orders / total_orders) * 100
    ) STORED
);
