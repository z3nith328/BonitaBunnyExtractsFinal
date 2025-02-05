CREATE TABLE order_discounts (
    discount_id SERIAL PRIMARY KEY,

    order_id INT NOT NULL REFERENCES orders(order_id) ON DELETE CASCADE,
    sub_order_id INT REFERENCES orders(sub_order_id) ON DELETE CASCADE,
    item_id TEXT REFERENCES order_items(item_id) ON DELETE CASCADE,

    discount_type TEXT CHECK (discount_type IN ('Percentage', 'Flat Amount', 'Bundle', 'Promo Code')) NOT NULL,
    discount_value DECIMAL(10,2) NOT NULL,

    applied_to TEXT CHECK (applied_to IN ('Order', 'Sub-Order', 'Item')) NOT NULL,
    discount_reason TEXT DEFAULT NULL,

    discounted_amount DECIMAL(10,2) GENERATED ALWAYS AS (
        CASE
            WHEN discount_type = 'Percentage' THEN
                LEAST(
                    (discount_value / 100) *
                    CASE
                        WHEN applied_to = 'Order' THEN (SELECT total_order_price FROM orders WHERE orders.order_id = order_discounts.order_id)
                        WHEN applied_to = 'Sub-Order' THEN (SELECT subtotal_amount FROM orders WHERE orders.sub_order_id = order_discounts.sub_order_id)
                        WHEN applied_to = 'Item' THEN (SELECT item_price FROM order_items WHERE order_items.item_id = order_discounts.item_id)
                    END,
                    CASE
                        WHEN applied_to = 'Order' THEN (SELECT total_order_price FROM orders WHERE orders.order_id = order_discounts.order_id)
                        WHEN applied_to = 'Sub-Order' THEN (SELECT subtotal_amount FROM orders WHERE orders.sub_order_id = order_discounts.sub_order_id)
                        WHEN applied_to = 'Item' THEN (SELECT item_price FROM order_items WHERE order_items.item_id = order_discounts.item_id)
                    END
                )
            WHEN discount_type = 'Flat Amount' THEN
                LEAST(
                    discount_value,
                    CASE
                        WHEN applied_to = 'Order' THEN (SELECT total_order_price FROM orders WHERE orders.order_id = order_discounts.order_id)
                        WHEN applied_to = 'Sub-Order' THEN (SELECT subtotal_amount FROM orders WHERE orders.sub_order_id = order_discounts.sub_order_id)
                        WHEN applied_to = 'Item' THEN (SELECT item_price FROM order_items WHERE order_items.item_id = order_discounts.item_id)
                    END
                )
            WHEN discount_type = 'Bundle' THEN
                LEAST(
                    (SELECT SUM(item_price) FROM order_items WHERE order_items.item_id = order_discounts.item_id) * 0.10,
                    (SELECT SUM(item_price) FROM order_items WHERE order_items.item_id = order_discounts.item_id)
                )
            ELSE 0
        END
    ) STORED
);
