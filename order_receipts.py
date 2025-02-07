import psycopg2
import json
import random
from psycopg2 import sql
from flask import Flask, request, jsonify

# Database connection settings
DB_CONFIG = {
    "dbname": "bonita_bunny_extracts",
    "user": "chris_layton",
    "password": "Rainforest2011",
    "host": "5432",
    "port": "5432"
}

app = Flask(__name__)

### DATABASE FUNCTIONS ###
def fetch_prebuilt_input_list(pre_built_id):
    """Fetch input_list JSONB for a Pre-Built product."""
    query = sql.SQL("""
        SELECT input_list FROM curr_pre_built_list WHERE pre_built_id = %s;
    """)

    try:
        with psycopg2.connect(**DB_CONFIG) as conn:
            with conn.cursor() as cur:
                cur.execute(query, (pre_built_id,))
                result = cur.fetchone()
                return result[0] if result else None
    except Exception as e:
        return {"error": str(e)}

def fetch_item_details(item_ids):
    """Fetch details for the given item_ids from item_matrix & inventory_levels."""
    query = sql.SQL("""
        SELECT im.*, il.last_order_unit_cost 
        FROM item_matrix im 
        LEFT JOIN inventory_levels il ON im.item_id = il.item_id
        WHERE im.item_id IN %s;
    """)

    try:
        with psycopg2.connect(**DB_CONFIG) as conn:
            with conn.cursor() as cur:
                cur.execute(query, (tuple(item_ids),))
                result = cur.fetchall()
                columns = [desc[0] for desc in cur.description]
                return [dict(zip(columns, row)) for row in result]
    except Exception as e:
        return {"error": str(e)}

def generate_unique_random():
    """Generates a unique random number not in prev_used_rand."""
    while True:
        rand_num = random.randint(1, 1000000)
        query = "SELECT 1 FROM prev_used_rand WHERE random_number = %s;"

        try:
            with psycopg2.connect(**DB_CONFIG) as conn:
                with conn.cursor() as cur:
                    cur.execute(query, (rand_num,))
                    if not cur.fetchone():
                        cur.execute("INSERT INTO prev_used_rand (random_number) VALUES (%s);", (rand_num,))
                        conn.commit()
                        return rand_num
        except Exception as e:
            return {"error": str(e)}

def construct_sub_order(prebuilt=False, pre_built_id=None, product_line=None, custom_data=None):
    """Constructs a single sub-order object."""
    if prebuilt:
        # Fetch input_list from database
        input_list = fetch_prebuilt_input_list(pre_built_id)
        if not input_list:
            return {"error": "Pre-Built ID not found."}
        cord_list, pendant_list, bead_list = input_list.get("cord_list", {}), input_list.get("pendant_list", []), input_list.get("bead_list", [])
    else:
        # Extract data from custom_data
        cord_list, pendant_list, bead_list = custom_data["cord_list"], custom_data["pendant_list"], custom_data["bead_list"]

    # Extract item IDs
    item_ids = [cord_list.get("item_id")] if cord_list else []
    item_ids += [p["item_id"] for p in pendant_list]
    item_ids += [b["item_id"] for b in bead_list]

    # Fetch item details
    item_details = fetch_item_details(item_ids)

    # Build sub_order_id
    sorted_ids = sorted(item_ids)
    unique_rand = generate_unique_random()
    sub_order_id = "-".join(sorted_ids) + f"-{unique_rand}"

    # Compute bead quantity
    total_bead_qty = sum(b["bead_qty"] for b in bead_list)

    # Construct sub-order JSON
    sub_order = {
        "sub_order_id": sub_order_id,
        "product_line": product_line,
        "cord_list": cord_list,
        "pendant_list": pendant_list,
        "bead_list": bead_list,
        "total_bead_qty": total_bead_qty
    }
    return sub_order

def construct_order_id(sub_orders_list):
    """Constructs order_id based on sub_orders_list."""
    sub_order_ids = [sub["sub_order_id"] for sub in sub_orders_list]
    product_initials = "".join(sub["product_line"][0] for sub in sub_orders_list)
    return f"{product_initials}-" + "_".join(sub_order_ids)

def update_orders_table(order_id, sub_orders_list):
    """Updates orders table with order_id and sub_orders_list."""
    query = sql.SQL("""
        INSERT INTO orders (order_id, sub_orders_list)
        VALUES (%s, %s)
        RETURNING order_id;
    """)

    try:
        with psycopg2.connect(**DB_CONFIG) as conn:
            with conn.cursor() as cur:
                cur.execute(query, (order_id, json.dumps(sub_orders_list)))
                conn.commit()
                return {"message": f"Order {order_id} inserted successfully."}
    except Exception as e:
        return {"error": str(e)}

### FLASK API ENDPOINTS ###
@app.route("/add_prebuilt_to_cart", methods=["POST"])
def add_prebuilt_to_cart():
    """Handles adding a Pre-Built product to the cart."""
    data = request.get_json()
    pre_built_id = data.get("pre_built_id")
    product_line = data.get("product_line")

    if not pre_built_id or not product_line:
        return jsonify({"error": "Missing pre_built_id or product_line."}), 400

    sub_order = construct_sub_order(prebuilt=True, pre_built_id=pre_built_id, product_line=product_line)
    return jsonify(sub_order), 200

@app.route("/start_custom_order", methods=["POST"])
def start_custom_order():
    """Handles starting a custom product build."""
    data = request.get_json()
    product_line = data.get("product_line")
    custom_data = {
        "cord_list": data.get("cord_list", {}),
        "pendant_list": data.get("pendant_list", []),
        "bead_list": data.get("bead_list", [])
    }

    if not product_line:
        return jsonify({"error": "Missing product_line."}), 400

    sub_order = construct_sub_order(prebuilt=False, product_line=product_line, custom_data=custom_data)
    return jsonify(sub_order), 200

@app.route("/checkout", methods=["POST"])
def checkout():
    """Handles checkout and final order construction."""
    data = request.get_json()
    sub_orders_list = data.get("sub_orders_list")

    if not sub_orders_list:
        return jsonify({"error": "No sub_orders_list provided."}), 400

    # Generate order_id
    order_id = construct_order_id(sub_orders_list)

    # Insert into orders table
    result = update_orders_table(order_id, sub_orders_list)
    return jsonify(result), 200

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=True)
