CREATE TABLE shipments (
    shipment_id SERIAL PRIMARY KEY,

    order_id INT NOT NULL REFERENCES orders(order_id) ON DELETE CASCADE,

    tracking_number TEXT UNIQUE NOT NULL CHECK (
        tracking_number ~* '^(USPS|FedEx|UPS)-\d{8}-\d+$'
    ),

    carrier TEXT CHECK (carrier IN ('USPS', 'FedEx', 'UPS')) NOT NULL,

    shipping_type TEXT CHECK (
        (carrier = 'USPS' AND shipping_type IN ('USPS Flat Rate Priority', 'USPS Flat Rate Express')) OR
        (carrier = 'FedEx' AND shipping_type IN ('FedEx Home')) OR
        (carrier = 'UPS' AND shipping_type IN ('UPS Ground', 'UPS 2nd Day Air'))
    ) NOT NULL,

    ship_weight DECIMAL(10,2) GENERATED ALWAYS AS (
        (SELECT order_grs_wt FROM orders WHERE orders.order_id = shipments.order_id)
    ) STORED,

    estimated_delivery_date TIMESTAMP NOT NULL CHECK (estimated_delivery_date >= CURRENT_TIMESTAMP),

    actual_delivery_date TIMESTAMP DEFAULT NULL CHECK (actual_delivery_date >= shipment_created_at),

    shipment_created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL
);
