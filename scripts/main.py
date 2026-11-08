import pyodbc
from fastapi import FastAPI, HTTPException, Query
from fastapi.middleware.cors import CORSMiddleware
from typing import Optional, List, Dict, Any
from datetime import datetime, timedelta
import json

app = FastAPI(
    title="OLAP API",
    description="Data Warehouse OLAP Analysis with 56 Cuboids",
    version="2.0"
)

# CORS Configuration
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
    """Kết nối tới OLAP_QuanLyBanHang (cuboid tables)"""
    return pyodbc.connect(
        "DRIVER={ODBC Driver 17 for SQL Server};"
        "SERVER=localhost;"
        "DATABASE=OLAP_QuanLyBanHang;"
        "UID=sa;"
        "PWD=123456;"
    )

def get_dw_connection():
    """Kết nối tới DW_Core (raw Fact tables)"""
    return pyodbc.connect(
        "DRIVER={ODBC Driver 17 for SQL Server};"
        "SERVER=localhost;"
        "DATABASE=DW_Core;"
        "UID=sa;"
        "PWD=123456;"
    )

# ============================================================
# UTILITY FUNCTIONS
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
        
        # Lấy tên cột
        columns = [desc[0] for desc in cursor.description]
        
        # Đọc từng dòng
        results = []
        for row in cursor.fetchall():
            results.append(dict(zip(columns, row)))
        
        conn.close()
        return results
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")

def build_where_clause(filters: Dict[str, Any]) -> tuple:
    """Xây dựng WHERE clause động từ filters
    
    Returns: (where_sql, params)
    """
    where_parts = []
    params = []
    
    for key, value in filters.items():
        if value is None:
            continue
            
        if key == "year":
            where_parts.append("year = ?")
            params.append(value)
        elif key == "month":
            where_parts.append("month = ?")
            params.append(value)
        elif key == "quarter":
            where_parts.append("quarter = ?")
            params.append(value)
        elif key == "customer_type":
            where_parts.append("customer_type = ?")
            params.append(value)
        elif key == "product_key":
            where_parts.append("product_key = ?")
            params.append(value)
        elif key == "store_key":
            where_parts.append("store_key = ?")
            params.append(value)
        elif key == "bang":
            where_parts.append("bang = ?")
            params.append(value)
        elif key == "ten_tp":
            where_parts.append("ten_tp = ?")
            params.append(value)
    
    where_sql = " AND ".join(where_parts)
    return ("WHERE " + where_sql) if where_sql else "", params

# --- API ENDPOINTS ---

@app.get("/")
def home():
    return {
        "message": "API OLAP (T-SQL) đang chạy!",
        "database": "OLAP_QuanLyBanHang",
        "cuboids": "56 bảng (24 Sales + 32 Inventory)"
    }

# ============================================================
# SALES CUBE APIs
# ============================================================

@app.get("/api/sales/by-month")
def sales_by_month(year: Optional[int] = None):
    """Doanh thu theo tháng"""
    if year:
        sql = "SELECT year, quarter, month, total_quantity, sum_amount FROM olap_s_month WHERE year = ?"
        return execute_query(sql, (year,))
    else:
        sql = "SELECT year, quarter, month, total_quantity, sum_amount FROM olap_s_month"
        return execute_query(sql)

@app.get("/api/sales/by-quarter")
def sales_by_quarter(year: Optional[int] = None):
    """Doanh thu theo quý"""
    if year:
        sql = "SELECT year, quarter, total_quantity, sum_amount FROM olap_s_quarter WHERE year = ?"
        return execute_query(sql, (year,))
    else:
        sql = "SELECT year, quarter, total_quantity, sum_amount FROM olap_s_quarter"
        return execute_query(sql)

@app.get("/api/sales/by-year")
def sales_by_year():
    """Doanh thu theo năm"""
    sql = "SELECT year, total_quantity, sum_amount FROM olap_s_year"
    return execute_query(sql)

@app.get("/api/sales/by-product")
def sales_by_product():
    """Doanh thu theo sản phẩm"""
    sql = "SELECT product_key, description, unit_price, total_quantity, sum_amount FROM olap_s_product ORDER BY sum_amount DESC"
    return execute_query(sql)

@app.get("/api/sales/by-customer-type")
def sales_by_customer_type():
    """Doanh thu theo loại khách hàng"""
    sql = "SELECT customer_type, total_quantity, sum_amount FROM olap_s_custtype"
    return execute_query(sql)

@app.get("/api/sales/by-customer")
def sales_by_customer():
    """Doanh thu theo từng khách hàng"""
    sql = "SELECT customer_key, customer_name, customer_type, total_quantity, sum_amount FROM olap_s_customer ORDER BY sum_amount DESC LIMIT 50"
    return execute_query(sql)

@app.get("/api/sales/month-product")
def sales_month_product(year: Optional[int] = None):
    """Doanh thu theo tháng × sản phẩm"""
    if year:
        sql = "SELECT year, quarter, month, product_key, description, total_quantity, sum_amount FROM olap_s_month_product WHERE year = ?"
        return execute_query(sql, (year,))
    else:
        sql = "SELECT year, quarter, month, product_key, description, total_quantity, sum_amount FROM olap_s_month_product LIMIT 500"
        return execute_query(sql)

@app.get("/api/sales/year-product")
def sales_year_product():
    """Doanh thu theo năm × sản phẩm"""
    sql = "SELECT year, product_key, description, total_quantity, sum_amount FROM olap_s_year_product"
    return execute_query(sql)

# ============================================================
# INVENTORY CUBE APIs
# ============================================================

@app.get("/api/inventory/by-month")
def inventory_by_month(year: Optional[int] = None):
    """Tồn kho theo tháng"""
    if year:
        sql = "SELECT year, quarter, month, total_quantity_on_hand FROM olap_i_month WHERE year = ?"
        return execute_query(sql, (year,))
    else:
        sql = "SELECT year, quarter, month, total_quantity_on_hand FROM olap_i_month"
        return execute_query(sql)

@app.get("/api/inventory/by-product")
def inventory_by_product():
    """Tồn kho theo sản phẩm"""
    sql = "SELECT product_key, total_quantity_on_hand FROM olap_i_product ORDER BY total_quantity_on_hand DESC"
    return execute_query(sql)

@app.get("/api/inventory/by-store")
def inventory_by_store():
    """Tồn kho theo cửa hàng"""
    sql = "SELECT store_key, total_quantity_on_hand FROM olap_i_store ORDER BY total_quantity_on_hand DESC"
    return execute_query(sql)

@app.get("/api/inventory/by-city")
def inventory_by_city():
    """Tồn kho theo thành phố"""
    sql = "SELECT bang, ten_tp, total_quantity_on_hand FROM olap_i_city ORDER BY total_quantity_on_hand DESC"
    return execute_query(sql)

@app.get("/api/inventory/month-product-store")
def inventory_month_product_store(year: Optional[int] = None):
    """Tồn kho theo tháng × sản phẩm × cửa hàng"""
    if year:
        sql = """SELECT year, quarter, month, product_key, store_key, total_quantity_on_hand 
                 FROM olap_i_month_product_store WHERE year = ? LIMIT 500"""
        return execute_query(sql, (year,))
    else:
        sql = "SELECT year, quarter, month, product_key, store_key, total_quantity_on_hand FROM olap_i_month_product_store LIMIT 500"
        return execute_query(sql)

# ============================================================
# SUMMARY APIs (Apex Cuboids)
# ============================================================

@app.get("/api/summary/sales-total")
def sales_total():
    """Tổng doanh thu toàn bộ"""
    sql = "SELECT total_quantity, sum_amount FROM olap_s_all"
    result = execute_query(sql)
    return result[0] if result else {"total_quantity": 0, "sum_amount": 0}

@app.get("/api/summary/inventory-total")
def inventory_total():
    """Tổng tồn kho toàn bộ"""
    sql = "SELECT total_quantity_on_hand FROM olap_i_all"
    result = execute_query(sql)
    return result[0] if result else {"total_quantity_on_hand": 0}

# Lệnh chạy server
if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="127.0.0.1", port=8000)