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

def update_item_matrix(item_id, category, material, cord_size, status):
    """Updates the item_matrix table with new values."""
    query = sql.SQL("""
        UPDATE item_matrix
        SET category = %s,
            material = %s,
            cord_size = %s,
            status = %s,
            updated_at = CURRENT_TIMESTAMP
        WHERE item_id = %s;
    """)
    
    try:
        with psycopg2.connect(**DB_CONFIG) as conn:
            with conn.cursor() as cur:
                cur.execute(query, (category, material, cord_size, status, item_id))
                print(f"Item {item_id} updated successfully.")
    except Exception as e:
        print(f"Error updating item {item_id}: {e}")

if __name__ == "__main__":
    # Example: Updating an item
    update_item_matrix("CABC", "Cord", "Gold", "MWB", "Active")
