CREATE TABLE inventory_abc_classification (
    item_id INT PRIMARY KEY REFERENCES inventory_items(item_id) ON DELETE CASCADE,

    abc_category TEXT CHECK (abc_category IN ('A', 'B', 'C')) NOT NULL,

    revenue_contribution DECIMAL(5,2) GENERATED ALWAYS AS (
        (SELECT COALESCE(SUM(oi.item_price * oi.quantity), 0)
         FROM order_items oi
         WHERE oi.item_id = inventory_abc_classification.item_id)
        /
        (SELECT COALESCE(SUM(oi.item_price * oi.quantity), 1)
         FROM order_items oi)
    ) STORED,

    inventory_turnover_ratio DECIMAL(10,2) GENERATED ALWAYS AS (
        (SELECT COALESCE(SUM(oi.cogs * oi.quantity), 0)
         FROM order_items oi
         WHERE oi.item_id = inventory_abc_classification.item_id)
        /
        ((SELECT COALESCE(SUM(il.beginning_inventory + il.ending_inventory) / 2, 1)
          FROM inventory_levels il
          WHERE il.item_id = inventory_abc_classification.item_id))
    ) STORED,

    holding_cost_per_unit DECIMAL(10,2) GENERATED ALWAYS AS (
        CASE
            WHEN (SELECT current_level
                  FROM inventory_levels il
                  WHERE il.item_id = inventory_abc_classification.item_id) > 0
            THEN
                (SELECT last_order_unit_cost
                 FROM suppliers s
                 WHERE s.item_id = inventory_abc_classification.item_id
                 ORDER BY s.last_order_date DESC LIMIT 1)
                /
                (SELECT current_level
                 FROM inventory_levels il
                 WHERE il.item_id = inventory_abc_classification.item_id)
            ELSE NULL
        END
    ) STORED,

    stock_aging_analysis JSONB GENERATED ALWAYS AS (
        (SELECT jsonb_build_object(
            'item_id', item_id,
            'supplier_id', supplier_id,
            'total_units', (SELECT current_level FROM inventory_levels il WHERE il.item_id = inventory_abc_classification.item_id),
            'age_distribution', jsonb_build_object(
                '0-30_days', COUNT(*) FILTER (WHERE EXTRACT(DAY FROM NOW() - created_at) BETWEEN 0 AND 30),
                '31-60_days', COUNT(*) FILTER (WHERE EXTRACT(DAY FROM NOW() - created_at) BETWEEN 31 AND 60),
                '61-90_days', COUNT(*) FILTER (WHERE EXTRACT(DAY FROM NOW() - created_at) BETWEEN 61 AND 90),
                '91+_days', COUNT(*) FILTER (WHERE EXTRACT(DAY FROM NOW() - created_at) > 90)
            ),
            'oldest_stock_age_days', EXTRACT(DAY FROM NOW() - MIN(created_at)),
            'average_stock_age_days', EXTRACT(DAY FROM NOW() - AVG(created_at)),
            'last_restock_date', (SELECT last_reorder_date FROM inventory_levels il WHERE il.item_id = inventory_abc_classification.item_id)
        ) FROM inventory_items ii WHERE ii.item_id = inventory_abc_classification.item_id)
    ) STORED,

    demand_consistency_score DECIMAL(10,2) GENERATED ALWAYS AS (
        1 - (
            (SELECT STDDEV(oi.quantity)
             FROM order_items oi
             WHERE oi.item_id = inventory_abc_classification.item_id)
            /
            (SELECT AVG(oi.quantity)
             FROM order_items oi
             WHERE oi.item_id = inventory_abc_classification.item_id)
        )
    ) STORED,

    average_order_quantity INT GENERATED ALWAYS AS (
        (SELECT AVG(oi.quantity)
         FROM order_items oi
         WHERE oi.item_id = inventory_abc_classification.item_id)
    ) STORED,

    contribution_to_operating_profit DECIMAL(5,2) GENERATED ALWAYS AS (
        (SELECT COALESCE(SUM(oi.item_price - oi.cogs) * oi.quantity, 0)
         FROM order_items oi
         WHERE oi.item_id = inventory_abc_classification.item_id)
        /
        (SELECT COALESCE(SUM(oi.item_price - oi.cogs) * oi.quantity, 1)
         FROM order_items oi)
    ) STORED
);
