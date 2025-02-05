import psycopg2
from psycopg2 import sql

# Database connection settings
DB_CONFIG = {
    "dbname": "bonita_bunny_extracts",
    "user": "chris_layton",
    "password": "Rainforest2011",
    "host": "5432",
    "port": "5432"
}

def update_supplier(supplier_id, supplier_name, last_order_qty, last_order_total_cost, last_order_date, last_delivery_date):
    """Updates the suppliers table with new values."""
    query = sql.SQL("""
        UPDATE suppliers
        SET supplier_name = %s,
            last_order_qty = %s,
            last_order_total_cost = %s,
            last_order_date = %s,
            last_delivery_date = %s,
            last_updated = CURRENT_TIMESTAMP
        WHERE supplier_id = %s;
    """)
    
    try:
        with psycopg2.connect(**DB_CONFIG) as conn:
            with conn.cursor() as cur:
                cur.execute(query, (supplier_name, last_order_qty, last_order_total_cost, last_order_date, last_delivery_date, supplier_id))
                print(f"Supplier {supplier_id} updated successfully.")
    except Exception as e:
        print(f"Error updating supplier {supplier_id}: {e}")

if __name__ == "__main__":
    # Example: Updating a supplier
    update_supplier(1, "New Supplier Name", 100, 500.00, "2024-01-01", "2024-01-10")
