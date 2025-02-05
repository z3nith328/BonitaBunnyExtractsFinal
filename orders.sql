CREATE TABLE orders (
    order_id SERIAL,
    sub_order_id INT,
    customer_id INT NOT NULL,
    order_status TEXT CHECK (order_status IN ('Pending', 'Processing', 'Shipped', 'Delivered', 'Cancelled', 'Returned')) NOT NULL,
    order_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    order_type TEXT CHECK (order_type IN ('Prebuilt', 'Custom', 'Combo')) NOT NULL,

    subtotal_amount DECIMAL(10,2) GENERATED ALWAYS AS (
        (SELECT SUM((sub_order_cogs / markup_percentage) - sub_order_disc)
         FROM orders o
         WHERE o.order_id = orders.order_id)
    ) STORED,

    tax_amount DECIMAL(10,2) NOT NULL DEFAULT 0,
    shipping_fee DECIMAL(10,2) NOT NULL DEFAULT 0,
    shipping_type TEXT CHECK (shipping_type IN ('USPS Flat Rate Priority', 'USPS Flat Rate Express', 'FedEx Home')) NOT NULL,
    shipment_id INT REFERENCES shipments(shipment_id) ON DELETE SET NULL,
    return_id INT REFERENCES returns(return_id) ON DELETE SET NULL,

    sub_orders_list JSONB NOT NULL,

    cord_list JSONB GENERATED ALWAYS AS (
        (SELECT sub_order->'cord_list'
         FROM jsonb_array_elements(sub_orders_list->'sub_orders') AS sub_order
         WHERE (sub_order->>'sub_order_id')::INT = sub_order_id
         LIMIT 1)
    ) STORED,

    pendant_list JSONB GENERATED ALWAYS AS (
        (SELECT COALESCE(sub_order->'pendant_list', '[]'::JSONB)
         FROM jsonb_array_elements(sub_orders_list->'sub_orders') AS sub_order
         WHERE (sub_order->>'sub_order_id')::INT = sub_order_id
         LIMIT 1)
    ) STORED,

    bead_list JSONB GENERATED ALWAYS AS (
        (SELECT COALESCE(sub_order->'bead_list', '[]'::JSONB)
         FROM jsonb_array_elements(sub_orders_list->'sub_orders') AS sub_order
         WHERE (sub_order->>'sub_order_id')::INT = sub_order_id
         LIMIT 1)
    ) STORED,

    num_pendant INT GENERATED ALWAYS AS (
        (SELECT COALESCE(COUNT(pendants), 0)
         FROM jsonb_array_elements(sub_orders_list->'sub_orders') AS sub_order
         LEFT JOIN LATERAL jsonb_array_elements(sub_order->'pendant_list') AS pendants ON TRUE
         WHERE (sub_order->>'sub_order_id')::INT = sub_order_id)
    ) STORED,

    num_bead INT GENERATED ALWAYS AS (
        (SELECT COALESCE(COUNT(beads), 0)
         FROM jsonb_array_elements(sub_orders_list->'sub_orders') AS sub_order
         LEFT JOIN LATERAL jsonb_array_elements(sub_order->'bead_list') AS beads ON TRUE
         WHERE (sub_order->>'sub_order_id')::INT = sub_order_id)
    ) STORED,

    sub_order_wt DECIMAL(10,2) GENERATED ALWAYS AS (
        (SELECT COALESCE(
            (sub_order->'cord_list'->>'cord_wt')::DECIMAL +
            (SELECT COALESCE(SUM((pendants->>'pendant_wt')::DECIMAL), 0)
             FROM jsonb_array_elements(sub_order->'pendant_list') AS pendants) +
            (SELECT COALESCE(SUM((beads->>'bead_wt')::DECIMAL * (beads->>'bead_qty')::INT), 0)
             FROM jsonb_array_elements(sub_order->'bead_list') AS beads)
        , 0)
         FROM jsonb_array_elements(sub_orders_list->'sub_orders') AS sub_order
         WHERE (sub_order->>'sub_order_id')::INT = sub_order_id)
    ) STORED,

    order_grs_wt DECIMAL(10,2) GENERATED ALWAYS AS (
        (SELECT COALESCE(SUM(sub_order_wt), 0)
         FROM orders o
         WHERE o.order_id = orders.order_id)
    ) STORED,

    order_cogs DECIMAL(10,2) GENERATED ALWAYS AS (
        (SELECT COALESCE(SUM(sub_order_cogs), 0)
         FROM orders o
         WHERE o.order_id = orders.order_id)
    ) STORED,

    markup_percentage DECIMAL(5,2) GENERATED ALWAYS AS (
        (SELECT COALESCE(
            ((sub_order->'cord_list'->>'cord_cost')::DECIMAL * (sub_order->'cord_list'->>'markup_percentage')::DECIMAL) +
            (SELECT COALESCE(SUM((pendants->>'pendant_cost')::DECIMAL * (pendants->>'markup_percentage')::DECIMAL), 0)
             FROM jsonb_array_elements(sub_order->'pendant_list') AS pendants) +
            (SELECT COALESCE(SUM((beads->>'bead_cost')::DECIMAL * (beads->>'markup_percentage')::DECIMAL * (beads->>'bead_qty')::INT), 0)
             FROM jsonb_array_elements(sub_order->'bead_list') AS beads)
        , 0) / sub_order_cogs * 100
         FROM jsonb_array_elements(sub_orders_list->'sub_orders') AS sub_order
         WHERE (sub_order->>'sub_order_id')::INT = sub_order_id)
    ) STORED,

    total_order_price DECIMAL(10,2) GENERATED ALWAYS AS (
        shipping_fee + 
        (SELECT SUM(sub_orders.subtotal_amount) 
         FROM orders AS sub_orders
         WHERE sub_orders.order_id = orders.order_id
         GROUP BY sub_orders.sub_order_id)
    ) STORED,

    PRIMARY KEY (order_id, sub_order_id)
) PARTITION BY LIST (order_type);
