CREATE TABLE order_items (
    order_id INT NOT NULL REFERENCES orders(order_id) ON DELETE CASCADE,
    sub_order_id INT NOT NULL REFERENCES orders(sub_order_id) ON DELETE CASCADE,
    item_id TEXT NOT NULL REFERENCES item_matrix(item_id),
    
    item_type TEXT CHECK (item_type IN ('Bead', 'Cord', 'Pendant')) NOT NULL,

    -- Cord Fields
    material TEXT GENERATED ALWAYS AS (
        (SELECT sub_order->'cord_list'->>'material'
         FROM jsonb_array_elements(orders.sub_orders_list->'sub_orders') AS sub_order
         WHERE (sub_order->>'sub_order_id')::INT = order_items.sub_order_id)
    ) STORED,

    cord_size TEXT GENERATED ALWAYS AS (
        (SELECT sub_order->'cord_list'->>'cord_size'
         FROM jsonb_array_elements(orders.sub_orders_list->'sub_orders') AS sub_order
         WHERE (sub_order->>'sub_order_id')::INT = order_items.sub_order_id)
    ) STORED,

    cord_wt DECIMAL(10,2) GENERATED ALWAYS AS (
        (SELECT (sub_order->'cord_list'->>'cord_wt')::DECIMAL
         FROM jsonb_array_elements(orders.sub_orders_list->'sub_orders') AS sub_order
         WHERE (sub_order->>'sub_order_id')::INT = order_items.sub_order_id)
    ) STORED,

    cord_cost DECIMAL(10,2) GENERATED ALWAYS AS (
        (SELECT (sub_order->'cord_list'->>'cord_cost')::DECIMAL
         FROM jsonb_array_elements(orders.sub_orders_list->'sub_orders') AS sub_order
         WHERE (sub_order->>'sub_order_id')::INT = order_items.sub_order_id)
    ) STORED,

    markup_percentage DECIMAL(5,2) GENERATED ALWAYS AS (
        (SELECT (sub_order->'cord_list'->>'markup_percentage')::DECIMAL
         FROM jsonb_array_elements(orders.sub_orders_list->'sub_orders') AS sub_order
         WHERE (sub_order->>'sub_order_id')::INT = order_items.sub_order_id)
    ) STORED,

    cord_price DECIMAL(10,2) GENERATED ALWAYS AS (
        (SELECT (sub_order->'cord_list'->>'cord_price')::DECIMAL
         FROM jsonb_array_elements(orders.sub_orders_list->'sub_orders') AS sub_order
         WHERE (sub_order->>'sub_order_id')::INT = order_items.sub_order_id)
    ) STORED,

    cord_disc DECIMAL(10,2) CHECK (cord_disc >= 0) GENERATED ALWAYS AS (
        (SELECT (sub_order->'cord_list'->>'cord_disc')::DECIMAL
         FROM jsonb_array_elements(orders.sub_orders_list->'sub_orders') AS sub_order
         WHERE (sub_order->>'sub_order_id')::INT = order_items.sub_order_id)
    ) STORED,

    -- Pendant Fields
    pendant_width DECIMAL(10,2) GENERATED ALWAYS AS (
        (SELECT (pendants->>'pendant_width')::DECIMAL
         FROM jsonb_array_elements(orders.sub_orders_list->'sub_orders') AS sub_order
         CROSS JOIN LATERAL jsonb_array_elements(sub_order->'pendant_list') AS pendants
         WHERE (sub_order->>'sub_order_id')::INT = order_items.sub_order_id
         LIMIT 1)
    ) STORED,

    pendant_wt DECIMAL(10,2) GENERATED ALWAYS AS (
        (SELECT (pendants->>'pendant_wt')::DECIMAL
         FROM jsonb_array_elements(orders.sub_orders_list->'sub_orders') AS sub_order
         CROSS JOIN LATERAL jsonb_array_elements(sub_order->'pendant_list') AS pendants
         WHERE (sub_order->>'sub_order_id')::INT = order_items.sub_order_id
         LIMIT 1)
    ) STORED,

    pendant_disc DECIMAL(10,2) CHECK (pendant_disc >= 0) GENERATED ALWAYS AS (
        (SELECT (pendants->>'pendant_disc')::DECIMAL
         FROM jsonb_array_elements(orders.sub_orders_list->'sub_orders') AS sub_order
         CROSS JOIN LATERAL jsonb_array_elements(sub_order->'pendant_list') AS pendants
         WHERE (sub_order->>'sub_order_id')::INT = order_items.sub_order_id
         LIMIT 1)
    ) STORED,

    -- Bead Fields
    bead_qty INT GENERATED ALWAYS AS (
        (SELECT (beads->>'bead_qty')::INT
         FROM jsonb_array_elements(orders.sub_orders_list->'sub_orders') AS sub_order
         CROSS JOIN LATERAL jsonb_array_elements(sub_order->'bead_list') AS beads
         WHERE (sub_order->>'sub_order_id')::INT = order_items.sub_order_id
         LIMIT 1)
    ) STORED,

    bead_wt DECIMAL(10,2) GENERATED ALWAYS AS (
        (SELECT (beads->>'bead_wt')::DECIMAL
         FROM jsonb_array_elements(orders.sub_orders_list->'sub_orders') AS sub_order
         CROSS JOIN LATERAL jsonb_array_elements(sub_order->'bead_list') AS beads
         WHERE (sub_order->>'sub_order_id')::INT = order_items.sub_order_id
         LIMIT 1)
    ) STORED,

    bead_disc DECIMAL(10,2) CHECK (bead_disc >= 0) GENERATED ALWAYS AS (
        (SELECT (beads->>'bead_disc')::DECIMAL
         FROM jsonb_array_elements(orders.sub_orders_list->'sub_orders') AS sub_order
         CROSS JOIN LATERAL jsonb_array_elements(sub_order->'bead_list') AS beads
         WHERE (sub_order->>'sub_order_id')::INT = order_items.sub_order_id
         LIMIT 1)
    ) STORED,

    -- Order Tracking Fields
    fulfillment_status TEXT CHECK (fulfillment_status IN ('Pending', 'Processing', 'Shipped', 'Delivered')) NOT NULL,
    shipment_id INT REFERENCES shipments(shipment_id) ON DELETE SET NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (order_id, sub_order_id, item_id)
);
