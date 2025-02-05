CREATE TABLE order_status_tracking (
    status_id SERIAL PRIMARY KEY,

    order_id INT NOT NULL REFERENCES orders(order_id) ON DELETE CASCADE,

    status TEXT CHECK (status IN ('Received', 'Processing', 'Shipped', 'Delivered', 'Returned', 'Canceled')) NOT NULL,
    previous_status TEXT DEFAULT NULL,

    status_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
   
    -- Ensure status updates are always moving forward in time
    CONSTRAINT chk_status_timestamp CHECK (
        status_timestamp > (
            SELECT COALESCE(MAX(status_timestamp), '1900-01-01'::TIMESTAMP)
            FROM order_status_tracking
            WHERE order_status_tracking.order_id = order_status_tracking.order_id
        )
    ),

    updated_by INT REFERENCES employees(employee_id) ON DELETE SET NULL,
    comments TEXT DEFAULT NULL,

    received_date TIMESTAMP GENERATED ALWAYS AS (CASE WHEN status = 'Received' THEN status_timestamp ELSE NULL END) STORED,
    processing_date TIMESTAMP GENERATED ALWAYS AS (CASE WHEN status = 'Processing' THEN status_timestamp ELSE NULL END) STORED,
    shipped_date TIMESTAMP GENERATED ALWAYS AS (CASE WHEN status = 'Shipped' THEN status_timestamp ELSE NULL END) STORED,
    delivered_date TIMESTAMP GENERATED ALWAYS AS (CASE WHEN status = 'Delivered' THEN status_timestamp ELSE NULL END) STORED,
    returned_date TIMESTAMP GENERATED ALWAYS AS (CASE WHEN status = 'Returned' THEN status_timestamp ELSE NULL END) STORED,
    canceled_date TIMESTAMP GENERATED ALWAYS AS (CASE WHEN status = 'Canceled' THEN status_timestamp ELSE NULL END) STORED
);
