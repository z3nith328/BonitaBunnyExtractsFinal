import psycopg2
import json
from psycopg2 import sql
from flask import Flask, request, jsonify

# Database connection settings
DB_CONFIG = {
    "dbname": "your_database",
    "user": "your_user",
    "password": "your_password",
    "host": "your_host",
    "port": "your_port"
}

app = Flask(__name__)

def validate_sub_orders_list(sub_orders_list):
    """Validates the structure of the sub_orders_list JSONB object."""
    required_keys = {"sub_order_id", "cord_list", "pendant_list", "bead_list"}
    if not isinstance(sub_orders_list, list):
        return False
    for sub_order in sub_orders_list:
        if not isinstance(sub_order, dict) or not required_keys.issubset(sub_order.keys()):
            return False
        if not isinstance(sub_order["cord_list"], list) or not isinstance(sub_order["pendant_list"], list) or not isinstance(sub_order["bead_list"], list):
            return False
    return True

def update_sub_orders(order_id, sub_orders_list):
    """Updates the sub_orders_list column in the orders table."""
    if not validate_sub_orders_list(sub_orders_list):
        return {"error": "Invalid sub_orders_list format."}, 400
    
    query = sql.SQL("""
        UPDATE orders
        SET sub_orders_list = %s
        WHERE order_id = %s;
    """)
    
    try:
        with psycopg2.connect(**DB_CONFIG) as conn:
            with conn.cursor() as cur:
                cur.execute(query, (json.dumps(sub_orders_list), order_id))
                return {"message": f"Order {order_id} updated successfully."}, 200
    except Exception as e:
        return {"error": str(e)}, 500

@app.route("/update_sub_orders", methods=["POST"])
def handle_update_sub_orders():
    """API endpoint to receive and update sub_orders_list."""
    data = request.get_json()
    if "order_id" not in data or "sub_orders_list" not in data:
        return {"error": "Missing order_id or sub_orders_list."}, 400
    
    return update_sub_orders(data["order_id"], data["sub_orders_list"])

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=True)
