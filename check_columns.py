import pyodbc

conn = pyodbc.connect(
    'Driver={ODBC Driver 17 for SQL Server};'
    'Server=LAPTOP-JQ8GDQT6;'
    'Database=OLAP_QuanLyBanHang;'
    'Trusted_Connection=yes;'
)

cursor = conn.cursor()

# Check 3D table structure
print("=" * 60)
print("Columns in olap_s_month_product_custtype:")
print("=" * 60)
cursor.execute("""
    SELECT COLUMN_NAME 
    FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_NAME = 'olap_s_month_product_custtype' 
    ORDER BY ORDINAL_POSITION
""")
for row in cursor.fetchall():
    print(f"  - {row[0]}")

# Check if customer_key exists in any sales table
print("\n" + "=" * 60)
print("Sales tables containing 'customer_key':")
print("=" * 60)
cursor.execute("""
    SELECT DISTINCT TABLE_NAME 
    FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_NAME LIKE 'olap_s%' 
    AND COLUMN_NAME = 'customer_key'
    ORDER BY TABLE_NAME
""")
results = cursor.fetchall()
if results:
    for row in results:
        print(f"  ✓ {row[0]}")
else:
    print("  ✗ No sales tables have customer_key column")

# Check what customer-related columns exist
print("\n" + "=" * 60)
print("All customer-related columns in olap_s_month_product_custtype:")
print("=" * 60)
cursor.execute("""
    SELECT COLUMN_NAME 
    FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_NAME = 'olap_s_month_product_custtype' 
    AND (COLUMN_NAME LIKE '%customer%' OR COLUMN_NAME LIKE '%kh%')
    ORDER BY ORDINAL_POSITION
""")
results = cursor.fetchall()
if results:
    for row in results:
        print(f"  - {row[0]}")
else:
    print("  - No customer columns found")

conn.close()
