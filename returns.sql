CREATE TABLE returns (
    return_id SERIAL PRIMARY KEY,

    order_id INT NOT NULL REFERENCES orders(order_id) ON DELETE CASCADE,
   
    sub_order_id INT NOT NULL REFERENCES orders(sub_order_id) ON DELETE CASCADE,

    return_reason TEXT NOT NULL,

    return_status TEXT CHECK (return_status IN ('Pending', 'Approved', 'Rejected', 'Refunded')) NOT NULL,

    refund_amount DECIMAL(10,2) GENERATED ALWAYS AS (
        (SELECT SUM(discounted_sub_order_price)
         FROM orders sub_orders
         WHERE sub_orders.order_id = returns.order_id
           AND sub_orders.sub_order_id = returns.sub_order_id)
    ) STORED,

    restock_status TEXT CHECK (restock_status IN ('Restocked', 'Not Restocked')) DEFAULT NULL,

    return_requested_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL
);
