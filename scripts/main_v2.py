import pyodbc
from fastapi import FastAPI, HTTPException, Query
from fastapi.middleware.cors import CORSMiddleware
from typing import Optional, List, Dict, Any

app = FastAPI(
    title="OLAP API v2.0",
    description="Enhanced OLAP with 56 Cuboids + 7 Operations",
    version="2.0"
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], 
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ============================================================
# DATABASE CONNECTION
# ============================================================

def get_olap_connection():
    """Kết nối tới OLAP_QuanLyBanHang"""
    return pyodbc.connect(
        "DRIVER={ODBC Driver 17 for SQL Server};"
        "SERVER=localhost;"
        "DATABASE=OLAP_QuanLyBanHang;"
        "UID=sa;"
        "PWD=123456;"
    )

def get_dw_connection():
    """Kết nối tới DW_Core"""
    return pyodbc.connect(
        "DRIVER={ODBC Driver 17 for SQL Server};"
        "SERVER=localhost;"
        "DATABASE=DW_Core;"
        "UID=sa;"
        "PWD=123456;"
    )

# ============================================================
# UTILITY
# ============================================================

def execute_query(sql, params=None, connection_type="olap"):
    """Execute SQL và trả về danh sách dictionary"""
    try:
        conn = get_olap_connection() if connection_type == "olap" else get_dw_connection()
        cursor = conn.cursor()
        
        if params:
            cursor.execute(sql, params)
        else:
            cursor.execute(sql)
        
        columns = [desc[0] for desc in cursor.description]
        results = []
        for row in cursor.fetchall():
            results.append(dict(zip(columns, row)))
        
        conn.close()
        return results
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"DB Error: {str(e)}")

# ============================================================
# HOME
# ============================================================

@app.get("/")
def home():
    return {
        "api": "OLAP v2.0",
        "cuboids": "56 (24 Sales + 32 Inventory)",
        "operations": ["Drill-down", "Roll-up", "Slice", "Dice", "Pivot", "Drill Across", "Drill Through"],
        "status": "All 56 cuboid endpoints ready"
    }

# ============================================================
# METADATA ENDPOINTS
# ============================================================

@app.get("/api/metadata/customer-types")
def get_customer_types():
    sql = "SELECT DISTINCT customer_type FROM olap_s_custtype ORDER BY customer_type"
    try:
        results = execute_query(sql)
        return [{"value": r["customer_type"], "label": r["customer_type"]} for r in results]
    except:
        return []

@app.get("/api/metadata/products")
def get_products(limit: int = 100):
    sql = f"SELECT TOP {limit} product_key, description FROM olap_s_product ORDER BY product_key"
    try:
        results = execute_query(sql)
        return [{"value": r["product_key"], "label": f"{r['product_key']} - {r['description']}"} for r in results]
    except Exception as e:
        print(f"❌ Products API error: {str(e)}")
        return []

@app.get("/api/metadata/stores")
def get_stores():
    sql = "SELECT DISTINCT store_key FROM olap_i_store ORDER BY store_key"
    try:
        results = execute_query(sql)
        return [{"value": r["store_key"], "label": f"CH {r['store_key']}"} for r in results]
    except:
        return []

@app.get("/api/metadata/cities")
def get_cities():
    sql = "SELECT DISTINCT bang, ten_tp FROM olap_i_city ORDER BY bang, ten_tp"
    try:
        results = execute_query(sql)
        return [{"value": f"{r['bang']}|{r['ten_tp']}", "label": f"{r['ten_tp']} ({r['bang']})"} for r in results]
    except:
        return []

@app.get("/api/metadata/customers")
def get_customers():
    """Lấy danh sách tất cả customers từ DW_Core"""
    sql = "SELECT DISTINCT kh_key, ten, loai_kh FROM DW_Core.dbo.Dim_KhachHang ORDER BY loai_kh, kh_key"
    try:
        results = execute_query(sql, connection_type="dw")
        return [{"value": r["kh_key"], "label": f"{r['kh_key']} - {r['ten']} ({r['loai_kh']})"} for r in results]
    except Exception as e:
        print(f"❌ Customers API error: {str(e)}")
        return []

# ============================================================
# SALES CUBE - 0-D (APEX)
# ============================================================

@app.get("/api/sales/apex")
def sales_apex():
    """0-D: Tổng toàn hệ thống - olap_s_all"""
    sql = "SELECT total_quantity, sum_amount FROM olap_s_all"
    return execute_query(sql)

# ============================================================
# SALES CUBE - 1-D (Time Hierarchy)
# ============================================================

@app.get("/api/sales/time/year")
def sales_time_year():
    """1D Time: By Year - olap_s_year"""
    sql = "SELECT year, total_quantity, sum_amount FROM olap_s_year ORDER BY year"
    return execute_query(sql)

@app.get("/api/sales/time/quarter")
def sales_time_quarter(year: Optional[int] = None):
    """1D Time: By Quarter - olap_s_quarter"""
    if year:
        sql = "SELECT year, quarter, total_quantity, sum_amount FROM olap_s_quarter WHERE year = ? ORDER BY quarter"
        return execute_query(sql, (year,))
    sql = "SELECT year, quarter, total_quantity, sum_amount FROM olap_s_quarter ORDER BY year, quarter"
    return execute_query(sql)

@app.get("/api/sales/time/month")
def sales_time_month(year: Optional[int] = None):
    """1D Time: By Month - olap_s_month"""
    if year:
        sql = "SELECT year, quarter, month, total_quantity, sum_amount FROM olap_s_month WHERE year = ? ORDER BY quarter, month"
        return execute_query(sql, (year,))
    sql = "SELECT TOP 100 year, quarter, month, total_quantity, sum_amount FROM olap_s_month ORDER BY year, quarter, month"
    return execute_query(sql)

# ============================================================
# SALES CUBE - 1-D (Slice by dimension)
# ============================================================

@app.get("/api/sales/product")
def sales_product():
    """1D Product: All products - olap_s_product"""
    sql = "SELECT product_key, description, total_quantity, sum_amount FROM olap_s_product ORDER BY sum_amount DESC"
    return execute_query(sql)

@app.get("/api/sales/customer-type")
def sales_customer_type():
    """1D Customer: By customer type - olap_s_custtype"""
    sql = "SELECT customer_type, total_quantity, sum_amount FROM olap_s_custtype ORDER BY sum_amount DESC"
    return execute_query(sql)

# ============================================================
# SALES CUBE - 2-D (Time × Product)
# ============================================================

@app.get("/api/sales/time-product/year-product")
def sales_year_product():
    """2D Time×Product: Year × Product - olap_s_year_product"""
    sql = "SELECT year, product_key, description, total_quantity, sum_amount FROM olap_s_year_product ORDER BY year, sum_amount DESC"
    return execute_query(sql)

@app.get("/api/sales/time-product/quarter-product")
def sales_quarter_product(year: Optional[int] = None):
    """2D Time×Product: Quarter × Product - olap_s_quarter_product"""
    if year:
        sql = "SELECT year, quarter, product_key, description, total_quantity, sum_amount FROM olap_s_quarter_product WHERE year = ? ORDER BY quarter, sum_amount DESC"
        return execute_query(sql, (year,))
    sql = "SELECT year, quarter, product_key, description, total_quantity, sum_amount FROM olap_s_quarter_product ORDER BY year, quarter, sum_amount DESC"
    return execute_query(sql)

@app.get("/api/sales/time-product/month-product")
def sales_month_product(year: Optional[int] = None):
    """2D Time×Product: Month × Product - olap_s_month_product"""
    if year:
        sql = "SELECT year, quarter, month, product_key, description, total_quantity, sum_amount FROM olap_s_month_product WHERE year = ? ORDER BY month, sum_amount DESC"
        return execute_query(sql, (year,))
    sql = "SELECT TOP 200 year, quarter, month, product_key, description, total_quantity, sum_amount FROM olap_s_month_product ORDER BY year, month, sum_amount DESC"
    return execute_query(sql)

# ============================================================
# SALES CUBE - 2-D (Time × Customer)
# ============================================================

@app.get("/api/sales/time-customer/year-custtype")
def sales_year_custtype():
    """2D Time×Customer: Year × CustType - olap_s_year_custtype"""
    sql = "SELECT year, customer_type, total_quantity, sum_amount FROM olap_s_year_custtype ORDER BY year, sum_amount DESC"
    return execute_query(sql)

@app.get("/api/sales/time-customer/quarter-custtype")
def sales_quarter_custtype(year: Optional[int] = None):
    """2D Time×Customer: Quarter × CustType - olap_s_quarter_custtype"""
    if year:
        sql = "SELECT year, quarter, customer_type, total_quantity, sum_amount FROM olap_s_quarter_custtype WHERE year = ? ORDER BY quarter, sum_amount DESC"
        return execute_query(sql, (year,))
    sql = "SELECT year, quarter, customer_type, total_quantity, sum_amount FROM olap_s_quarter_custtype ORDER BY year, quarter, sum_amount DESC"
    return execute_query(sql)

@app.get("/api/sales/time-customer/month-custtype")
def sales_month_custtype(year: int):
    """2D Time×Customer: Month × CustType - olap_s_month_custtype"""
    sql = "SELECT year, quarter, month, customer_type, total_quantity, sum_amount FROM olap_s_month_custtype WHERE year = ? ORDER BY month, customer_type"
    return execute_query(sql, (year,))

@app.get("/api/sales/time-customer/month-customer")
def sales_month_customer(year: int):
    """2D Time×Customer: Month × Customer_key - olap_s_month_customer"""
    sql = "SELECT year, quarter, month, customer_key, total_quantity, sum_amount FROM olap_s_month_customer WHERE year = ? ORDER BY month, customer_key"
    return execute_query(sql, (year,))

# ============================================================
# SALES CUBE - 2-D (Product × Customer)
# ============================================================

@app.get("/api/sales/product-customer")
def sales_product_custtype(year: Optional[int] = None):
    """2D Product×Customer: Product × CustType - olap_s_product_custtype"""
    if year:
        sql = "SELECT TOP 200 year, product_key, description, customer_type, total_quantity, sum_amount FROM olap_s_year_product_custtype WHERE year = ? ORDER BY product_key, customer_type"
        return execute_query(sql, (year,))
    sql = "SELECT TOP 100 product_key, description, customer_type, total_quantity, sum_amount FROM olap_s_product_custtype ORDER BY product_key, customer_type"
    return execute_query(sql)

# ============================================================
# SALES CUBE - 3-D (Time × Product × Customer)
# ============================================================

@app.get("/api/sales/3d/year-product-custtype")
def sales_3d_year_product_custtype(year: int):
    """3D Year×Product×Customer - olap_s_year_product_custtype"""
    sql = "SELECT year, product_key, description, customer_type, total_quantity, sum_amount FROM olap_s_year_product_custtype WHERE year = ? ORDER BY product_key, customer_type"
    return execute_query(sql, (year,))

@app.get("/api/sales/3d/quarter-product-custtype")
def sales_3d_quarter_product_custtype(year: int, quarter: int):
    """3D Quarter×Product×Customer - olap_s_quarter_product_custtype"""
    sql = "SELECT year, quarter, product_key, description, customer_type, total_quantity, sum_amount FROM olap_s_quarter_product_custtype WHERE year = ? AND quarter = ? ORDER BY product_key, customer_type"
    return execute_query(sql, (year, quarter))

@app.get("/api/sales/3d/month-product-custtype")
def sales_3d_month_product_custtype(year: int, month: int):
    """3D Month×Product×Customer - olap_s_month_product_custtype (customer_type)"""
    sql = "SELECT year, quarter, month, product_key, description, customer_type, total_quantity, sum_amount FROM olap_s_month_product_custtype WHERE year = ? AND month = ? ORDER BY product_key, customer_type"
    return execute_query(sql, (year, month))

@app.get("/api/sales/3d/month-product-customer")
def sales_3d_month_product_customer(year: int, month: int):
    """3D Month×Product×Customer - olap_s_month_product_customer (customer_key)"""
    sql = "SELECT year, quarter, month, product_key, customer_key, total_quantity, sum_amount FROM olap_s_month_product_customer WHERE year = ? AND month = ? ORDER BY product_key, customer_key"
    return execute_query(sql, (year, month))

# ============================================================
# INVENTORY CUBE - 0-D (APEX)
# ============================================================

@app.get("/api/inventory/apex")
def inventory_apex():
    """0-D: Tổng toàn hệ thống - olap_i_all"""
    sql = "SELECT total_quantity_on_hand FROM olap_i_all"
    return execute_query(sql)

# ============================================================
# INVENTORY CUBE - 1-D (Time Hierarchy)
# ============================================================

@app.get("/api/inventory/time/year")
def inventory_time_year():
    """1D Time: By Year - olap_i_year"""
    sql = "SELECT year, total_quantity_on_hand FROM olap_i_year ORDER BY year"
    return execute_query(sql)

@app.get("/api/inventory/time/quarter")
def inventory_time_quarter(year: Optional[int] = None):
    """1D Time: By Quarter - olap_i_quarter"""
    if year:
        sql = "SELECT year, quarter, total_quantity_on_hand FROM olap_i_quarter WHERE year = ? ORDER BY quarter"
        return execute_query(sql, (year,))
    sql = "SELECT year, quarter, total_quantity_on_hand FROM olap_i_quarter ORDER BY year, quarter"
    return execute_query(sql)

@app.get("/api/inventory/time/month")
def inventory_time_month(year: Optional[int] = None):
    """1D Time: By Month - olap_i_month"""
    if year:
        sql = "SELECT year, quarter, month, total_quantity_on_hand FROM olap_i_month WHERE year = ? ORDER BY quarter, month"
        return execute_query(sql, (year,))
    sql = "SELECT TOP 100 year, quarter, month, total_quantity_on_hand FROM olap_i_month ORDER BY year, quarter, month"
    return execute_query(sql)

# ============================================================
# INVENTORY CUBE - 1-D (Slice by dimension)
# ============================================================

@app.get("/api/inventory/product")
def inventory_product():
    """1D Product: All products - olap_i_product"""
    sql = "SELECT product_key, total_quantity_on_hand FROM olap_i_product ORDER BY total_quantity_on_hand DESC"
    return execute_query(sql)

@app.get("/api/inventory/store")
def inventory_store():
    """1D Store: All stores - olap_i_store"""
    sql = "SELECT store_key, total_quantity_on_hand FROM olap_i_store ORDER BY total_quantity_on_hand DESC"
    return execute_query(sql)

# ============================================================
# INVENTORY CUBE - 2-D (Time × Product)
# ============================================================

@app.get("/api/inventory/time-product/year-product")
def inventory_year_product():
    """2D Time×Product: Year × Product - olap_i_year_product"""
    sql = "SELECT year, product_key, total_quantity_on_hand FROM olap_i_year_product ORDER BY year, total_quantity_on_hand DESC"
    return execute_query(sql)

@app.get("/api/inventory/time-product/quarter-product")
def inventory_quarter_product(year: Optional[int] = None):
    """2D Time×Product: Quarter × Product - olap_i_quarter_product"""
    if year:
        sql = "SELECT year, quarter, product_key, total_quantity_on_hand FROM olap_i_quarter_product WHERE year = ? ORDER BY quarter, total_quantity_on_hand DESC"
        return execute_query(sql, (year,))
    sql = "SELECT year, quarter, product_key, total_quantity_on_hand FROM olap_i_quarter_product ORDER BY year, quarter, total_quantity_on_hand DESC"
    return execute_query(sql)

@app.get("/api/inventory/time-product/month-product")
def inventory_month_product(year: Optional[int] = None):
    """2D Time×Product: Month × Product - olap_i_month_product"""
    if year:
        sql = "SELECT year, quarter, month, product_key, total_quantity_on_hand FROM olap_i_month_product WHERE year = ? ORDER BY month, total_quantity_on_hand DESC"
        return execute_query(sql, (year,))
    sql = "SELECT TOP 200 year, quarter, month, product_key, total_quantity_on_hand FROM olap_i_month_product ORDER BY year, month, total_quantity_on_hand DESC"
    return execute_query(sql)

# ============================================================
# INVENTORY CUBE - 2-D (Time × Store)
# ============================================================

@app.get("/api/inventory/time-store/year-store")
def inventory_year_store():
    """2D Time×Store: Year × Store - olap_i_year_store"""
    sql = "SELECT year, store_key, total_quantity_on_hand FROM olap_i_year_store ORDER BY year, total_quantity_on_hand DESC"
    return execute_query(sql)

@app.get("/api/inventory/time-store/quarter-store")
def inventory_quarter_store(year: Optional[int] = None):
    """2D Time×Store: Quarter × Store - olap_i_quarter_store"""
    if year:
        sql = "SELECT year, quarter, store_key, total_quantity_on_hand FROM olap_i_quarter_store WHERE year = ? ORDER BY quarter, total_quantity_on_hand DESC"
        return execute_query(sql, (year,))
    sql = "SELECT year, quarter, store_key, total_quantity_on_hand FROM olap_i_quarter_store ORDER BY year, quarter, total_quantity_on_hand DESC"
    return execute_query(sql)

@app.get("/api/inventory/time-store/month-store")
def inventory_month_store(year: Optional[int] = None):
    """2D Time×Store: Month × Store - olap_i_month_store"""
    if year:
        sql = "SELECT year, quarter, month, store_key, total_quantity_on_hand FROM olap_i_month_store WHERE year = ? ORDER BY month, total_quantity_on_hand DESC"
        return execute_query(sql, (year,))
    sql = "SELECT TOP 200 year, quarter, month, store_key, total_quantity_on_hand FROM olap_i_month_store ORDER BY year, month, total_quantity_on_hand DESC"
    return execute_query(sql)

# ============================================================
# INVENTORY CUBE - 2-D (Product × Store)
# ============================================================

@app.get("/api/inventory/product-store")
def inventory_product_store():
    """2D Product×Store: Product × Store - olap_i_product_store"""
    sql = "SELECT product_key, store_key, total_quantity_on_hand FROM olap_i_product_store ORDER BY total_quantity_on_hand DESC"
    return execute_query(sql)

# ============================================================
# INVENTORY CUBE - 3-D (Time × Product × Store)
# ============================================================

@app.get("/api/inventory/3d/year-product-store")
def inventory_3d_year_product_store(year: int):
    """3D Year×Product×Store - olap_i_year_product_store"""
    sql = "SELECT year, product_key, store_key, total_quantity_on_hand FROM olap_i_year_product_store WHERE year = ? ORDER BY product_key, store_key"
    return execute_query(sql, (year,))

@app.get("/api/inventory/3d/quarter-product-store")
def inventory_3d_quarter_product_store(year: int, quarter: int):
    """3D Quarter×Product×Store - olap_i_quarter_product_store"""
    sql = "SELECT year, quarter, product_key, store_key, total_quantity_on_hand FROM olap_i_quarter_product_store WHERE year = ? AND quarter = ? ORDER BY product_key, store_key"
    return execute_query(sql, (year, quarter))

@app.get("/api/inventory/3d/month-product-store")
def inventory_3d_month_product_store(year: int, month: Optional[int] = None, store_key: Optional[int] = None):
    """3D Month×Product×Store - olap_i_month_product_store"""
    if store_key:
        sql = "SELECT TOP 300 year, quarter, month, product_key, store_key, total_quantity_on_hand FROM olap_i_month_product_store WHERE year = ? AND store_key = ? ORDER BY month, product_key"
        return execute_query(sql, (year, store_key))
    sql = "SELECT TOP 500 year, quarter, month, product_key, store_key, total_quantity_on_hand FROM olap_i_month_product_store WHERE year = ? ORDER BY month, product_key"
    return execute_query(sql, (year,))

# ============================================================
# DRILL ACROSS (So sánh 2 Cube)
# ============================================================

@app.get("/api/cross-analysis/sales-vs-inventory-by-product")
def drill_across_product():
    """So sánh doanh thu vs tồn kho theo sản phẩm"""
    try:
        sales_sql = "SELECT product_key, description, sum_amount as total_sales, total_quantity as sales_qty FROM olap_s_product ORDER BY product_key"
        inventory_sql = "SELECT product_key, total_quantity_on_hand as inventory_qty FROM olap_i_product ORDER BY product_key"
        
        sales_data = {r["product_key"]: r for r in execute_query(sales_sql)}
        inventory_data = {r["product_key"]: r for r in execute_query(inventory_sql)}
        
        results = []
        all_products = set(sales_data.keys()) | set(inventory_data.keys())
        
        for product_key in sorted(all_products):
            sales = sales_data.get(product_key, {})
            inventory = inventory_data.get(product_key, {})
            
            total_sales = sales.get("total_sales", 0) or 0
            sales_qty = sales.get("sales_qty", 0) or 0
            inventory_qty = inventory.get("inventory_qty", 0) or 0
            
            ratio = (sales_qty / inventory_qty * 100) if inventory_qty > 0 else 0
            
            results.append({
                "product_key": product_key,
                "description": sales.get("description", ""),
                "total_sales": total_sales,
                "sales_quantity": sales_qty,
                "inventory_quantity": inventory_qty,
                "turnover_ratio_percent": round(ratio, 2)
            })
        
        return results
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/cross-analysis/sales-vs-inventory-by-month")
def drill_across_month(year: int):
    """So sánh doanh thu vs tồn kho theo tháng"""
    try:
        sales_sql = "SELECT year, quarter, month, sum_amount, total_quantity FROM olap_s_month WHERE year = ? ORDER BY quarter, month"
        inventory_sql = "SELECT year, quarter, month, total_quantity_on_hand FROM olap_i_month WHERE year = ? ORDER BY quarter, month"
        
        sales_data = {r["month"]: r for r in execute_query(sales_sql, (year,))}
        inventory_data = {r["month"]: r for r in execute_query(inventory_sql, (year,))}
        
        results = []
        all_months = set(sales_data.keys()) | set(inventory_data.keys())
        
        for month in sorted(all_months):
            sales = sales_data.get(month, {})
            inventory = inventory_data.get(month, {})
            
            results.append({
                "year": year,
                "quarter": sales.get("quarter") or inventory.get("quarter"),
                "month": month,
                "sales_amount": sales.get("sum_amount", 0) or 0,
                "sales_quantity": sales.get("total_quantity", 0) or 0,
                "inventory_quantity": inventory.get("total_quantity_on_hand", 0) or 0
            })
        
        return results
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# ============================================================
# DRILL THROUGH (Raw transaction data)
# ============================================================

@app.get("/api/drill-through/sales")
def drill_through_sales(
    year: int,
    month: Optional[int] = None,
    customer_type: Optional[str] = None,
    product_key: Optional[str] = None,
    limit: int = 50,
    offset: int = 0
):
    """Raw data từ Fact_BanHang"""
    try:
        where_parts = ["t.nam = ?"]
        params = [year]
        
        if month:
            where_parts.append("t.thang = ?")
            params.append(month)
        
        if customer_type:
            where_parts.append("k.loai_kh = ?")
            params.append(customer_type)
        
        if product_key:
            where_parts.append("m.mh_key = ?")
            params.append(product_key)
        
        where_clause = " AND ".join(where_parts)
        
        sql = f"""
        SELECT TOP {limit}
            f.time_key,
            t.nam as year,
            t.quy as quarter,
            t.thang as month,
            k.ten as customer_name,
            k.loai_kh as customer_type,
            m.mh_key as product_key,
            m.mo_ta as product_description,
            f.so_luong as quantity,
            f.tong_tien as amount
        FROM DW_Core.dbo.Fact_BanHang f
        JOIN DW_Core.dbo.Dim_ThoiGian t ON f.time_key = t.time_key
        JOIN DW_Core.dbo.Dim_KhachHang k ON f.kh_key = k.kh_key
        JOIN DW_Core.dbo.Dim_MatHang m ON f.mh_key = m.mh_key
        WHERE {where_clause}
        ORDER BY f.time_key DESC
        OFFSET {offset} ROWS
        """
        
        results = execute_query(sql, params, connection_type="dw")
        
        count_sql = f"""
        SELECT COUNT(*) as total
        FROM DW_Core.dbo.Fact_BanHang f
        JOIN DW_Core.dbo.Dim_ThoiGian t ON f.time_key = t.time_key
        JOIN DW_Core.dbo.Dim_KhachHang k ON f.kh_key = k.kh_key
        JOIN DW_Core.dbo.Dim_MatHang m ON f.mh_key = m.mh_key
        WHERE {where_clause}
        """
        count_result = execute_query(count_sql, params, connection_type="dw")
        total = count_result[0].get("total", 0) if count_result else 0
        
        return {
            "data": results,
            "pagination": {
                "limit": limit,
                "offset": offset,
                "total": total,
                "pages": (total + limit - 1) // limit
            }
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/drill-through/inventory")
def drill_through_inventory(
    year: int,
    month: Optional[int] = None,
    store_key: Optional[int] = None,
    product_key: Optional[str] = None,
    limit: int = 50,
    offset: int = 0
):
    """Raw data từ Fact_Kho"""
    try:
        where_parts = ["t.nam = ?"]
        params = [year]
        
        if month:
            where_parts.append("t.thang = ?")
            params.append(month)
        
        if store_key:
            where_parts.append("f.ch_key = ?")
            params.append(store_key)
        
        if product_key:
            where_parts.append("f.mh_key = ?")
            params.append(product_key)
        
        where_clause = " AND ".join(where_parts)
        
        sql = f"""
        SELECT TOP {limit}
            f.time_key,
            t.nam as year,
            t.quy as quarter,
            t.thang as month,
            c.ch_key as store_key,
            v.ten_tp as city,
            v.bang as state,
            m.mh_key as product_key,
            m.mo_ta as product_description,
            f.so_luong as quantity_on_hand
        FROM DW_Core.dbo.Fact_Kho f
        JOIN DW_Core.dbo.Dim_ThoiGian t ON f.time_key = t.time_key
        JOIN DW_Core.dbo.Dim_CuaHang c ON f.ch_key = c.ch_key
        JOIN DW_Core.dbo.Dim_VPDD v ON c.vp_key = v.vp_key
        JOIN DW_Core.dbo.Dim_MatHang m ON f.mh_key = m.mh_key
        WHERE {where_clause}
        ORDER BY f.time_key DESC
        OFFSET {offset} ROWS
        """
        
        results = execute_query(sql, params, connection_type="dw")
        
        count_sql = f"""
        SELECT COUNT(*) as total
        FROM DW_Core.dbo.Fact_Kho f
        JOIN DW_Core.dbo.Dim_ThoiGian t ON f.time_key = t.time_key
        JOIN DW_Core.dbo.Dim_CuaHang c ON f.ch_key = c.ch_key
        JOIN DW_Core.dbo.Dim_VPDD v ON c.vp_key = v.vp_key
        JOIN DW_Core.dbo.Dim_MatHang m ON f.mh_key = m.mh_key
        WHERE {where_clause}
        """
        count_result = execute_query(count_sql, params, connection_type="dw")
        total = count_result[0].get("total", 0) if count_result else 0
        
        return {
            "data": results,
            "pagination": {
                "limit": limit,
                "offset": offset,
                "total": total,
                "pages": (total + limit - 1) // limit
            }
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# ============================================================
# SUMMARY
# ============================================================

@app.get("/api/summary/sales-total")
def sales_total():
    sql = "SELECT total_quantity, sum_amount FROM olap_s_all"
    result = execute_query(sql)
    return result[0] if result else {"total_quantity": 0, "sum_amount": 0}

@app.get("/api/summary/inventory-total")
def inventory_total():
    sql = "SELECT total_quantity_on_hand FROM olap_i_all"
    result = execute_query(sql)
    return result[0] if result else {"total_quantity_on_hand": 0}

# ============================================================
# RUN
# ============================================================

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="127.0.0.1", port=8000)
