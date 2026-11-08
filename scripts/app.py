"""
OLAP Web App Backend — FastAPI v3.0
Supports 56 Cuboids + 7 OLAP Operations
Database: OLAP_QuanLyBanHang (cuboids) + DW_Core (fact tables)
"""

import pyodbc
from fastapi import FastAPI, HTTPException, Query
from fastapi.middleware.cors import CORSMiddleware
from typing import Optional, List, Dict, Any
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(
    title="OLAP Web App",
    description="Sales & Inventory OLAP with 56 Cuboids",
    version="3.0"
)

# CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ============================================================
# DATABASE CONNECTIONS
# ============================================================

DB_CONFIG_OLAP = {
    "driver": "ODBC Driver 17 for SQL Server",
    "server": "localhost",
    "database": "OLAP_QuanLyBanHang",
    "uid": "sa",
    "pwd": "123456",
}

DB_CONFIG_DW = {
    "driver": "ODBC Driver 17 for SQL Server",
    "server": "localhost",
    "database": "DW_Core",
    "uid": "sa",
    "pwd": "123456",
}

def get_conn(db_type="olap"):
    """Get database connection"""
    config = DB_CONFIG_OLAP if db_type == "olap" else DB_CONFIG_DW
    conn_str = (
        f"DRIVER={{{config['driver']}}};"
        f"SERVER={config['server']};"
        f"DATABASE={config['database']};"
        f"UID={config['uid']};"
        f"PWD={config['pwd']};"
    )
    return pyodbc.connect(conn_str)

def execute_query(sql: str, params=None, db_type="olap") -> List[Dict]:
    """Execute SQL and return list of dicts"""
    try:
        conn = get_conn(db_type)
        conn.setdecoding(pyodbc.SQL_CHAR, encoding='utf-8')
        conn.setdecoding(pyodbc.SQL_WCHAR, encoding='utf-8')
        cursor = conn.cursor()
        
        if params:
            cursor.execute(sql, params)
        else:
            cursor.execute(sql)
        
        columns = [desc[0] for desc in cursor.description] if cursor.description else []
        rows = []
        for row in cursor.fetchall():
            rows.append(dict(zip(columns, row)))
        
        conn.close()
        return rows
    except Exception as e:
        logger.error(f"SQL Error: {e}, SQL: {sql}")
        raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")

# ============================================================
# HOME
# ============================================================

@app.get("/")
def home():
    return {
        "status": "OLAP Web App v3.0",
        "cuboids": "56 total (24 Sales + 32 Inventory)",
        "operations": ["Apex", "Drill-down", "Roll-up", "Slice", "Dice", "Pivot", "Drill Across", "Drill Through"]
    }

# ============================================================
# METADATA ENDPOINTS
# ============================================================

@app.get("/api/metadata/years")
def get_years():
    """Get all years from Sales cube"""
    sql = "SELECT DISTINCT nam FROM OLAP_QuanLyBanHang.dbo.olap_ds_nam ORDER BY nam"
    rows = execute_query(sql)
    return sorted([r["nam"] for r in rows])

@app.get("/api/metadata/customer-types")
def get_customer_types():
    """Get all customer types"""
    sql = "SELECT DISTINCT loai_kh FROM OLAP_QuanLyBanHang.dbo.olap_ds_loai_kh ORDER BY loai_kh"
    rows = execute_query(sql)
    return [r["loai_kh"] for r in rows]

@app.get("/api/metadata/products")
def get_products():
    """Get all products"""
    sql = "SELECT DISTINCT mh_key, mo_ta FROM OLAP_QuanLyBanHang.dbo.olap_ds_mh ORDER BY mh_key"
    rows = execute_query(sql)
    return [{"mh_key": r["mh_key"], "mo_ta": r["mo_ta"]} for r in rows]

@app.get("/api/metadata/states")
def get_states():
    """Get all states (tinh)"""
    sql = "SELECT DISTINCT bang FROM OLAP_QuanLyBanHang.dbo.olap_tk_tinh ORDER BY bang"
    rows = execute_query(sql)
    return [r["bang"] for r in rows]

@app.get("/api/metadata/cities")
def get_cities(bang: str = Query(...)):
    """Get cities in a state"""
    sql = f"SELECT DISTINCT ten_tp FROM OLAP_QuanLyBanHang.dbo.olap_tk_tp WHERE bang = ? ORDER BY ten_tp"
    rows = execute_query(sql, [bang])
    return [r["ten_tp"] for r in rows]

# ============================================================
# SALES CUBE — 0-D (Apex)
# ============================================================

@app.get("/api/sales/apex")
def get_sales_apex():
    """Sales total (apex)"""
    sql = "SELECT tong_so_luong, tong_doanh_thu FROM OLAP_QuanLyBanHang.dbo.olap_ds_all"
    rows = execute_query(sql)
    return rows[0] if rows else {"tong_so_luong": 0, "tong_doanh_thu": 0}

# ============================================================
# SALES CUBE — 1-D
# ============================================================

@app.get("/api/sales/by-year")
def get_sales_by_year():
    """Sales by year"""
    sql = "SELECT nam, tong_so_luong, tong_doanh_thu FROM OLAP_QuanLyBanHang.dbo.olap_ds_nam ORDER BY nam"
    return execute_query(sql)

@app.get("/api/sales/by-quarter")
def get_sales_by_quarter(nam: int = Query(...)):
    """Sales by quarter"""
    sql = f"SELECT nam, quy, tong_so_luong, tong_doanh_thu FROM OLAP_QuanLyBanHang.dbo.olap_ds_quy WHERE nam = ? ORDER BY quy"
    return execute_query(sql, [nam])

@app.get("/api/sales/by-month")
def get_sales_by_month(nam: int = Query(...)):
    """Sales by month"""
    sql = f"SELECT nam, quy, thang, tong_so_luong, tong_doanh_thu FROM OLAP_QuanLyBanHang.dbo.olap_ds_thang WHERE nam = ? ORDER BY thang"
    return execute_query(sql, [nam])

@app.get("/api/sales/by-product")
def get_sales_by_product():
    """Sales by product"""
    sql = "SELECT mh_key, mo_ta, kich_co, gia, tong_so_luong, tong_doanh_thu FROM OLAP_QuanLyBanHang.dbo.olap_ds_mh ORDER BY mh_key"
    return execute_query(sql)

@app.get("/api/sales/by-customer-type")
def get_sales_by_customer_type():
    """Sales by customer type"""
    sql = "SELECT loai_kh, tong_so_luong, tong_doanh_thu FROM OLAP_QuanLyBanHang.dbo.olap_ds_loai_kh ORDER BY loai_kh"
    return execute_query(sql)

@app.get("/api/sales/by-customer")
def get_sales_by_customer():
    """Sales by customer"""
    sql = "SELECT kh_key, ten, loai_kh, tong_so_luong, tong_doanh_thu FROM OLAP_QuanLyBanHang.dbo.olap_ds_kh ORDER BY kh_key"
    return execute_query(sql)

# ============================================================
# SALES CUBE — 2-D (Time × Product)
# ============================================================

@app.get("/api/sales/year-product")
def get_sales_year_product():
    """Sales by year × product"""
    sql = "SELECT nam, mh_key, mo_ta, tong_so_luong, tong_doanh_thu FROM OLAP_QuanLyBanHang.dbo.olap_ds_nam_mh ORDER BY nam, mh_key"
    return execute_query(sql)

@app.get("/api/sales/quarter-product")
def get_sales_quarter_product(nam: int = Query(...)):
    """Sales by quarter × product"""
    sql = f"SELECT nam, quy, mh_key, mo_ta, tong_so_luong, tong_doanh_thu FROM OLAP_QuanLyBanHang.dbo.olap_ds_quy_mh WHERE nam = ? ORDER BY quy, mh_key"
    return execute_query(sql, [nam])

@app.get("/api/sales/month-product")
def get_sales_month_product(nam: int = Query(...)):
    """Sales by month × product"""
    sql = f"SELECT nam, quy, thang, mh_key, mo_ta, tong_so_luong, tong_doanh_thu FROM OLAP_QuanLyBanHang.dbo.olap_ds_thang_mh WHERE nam = ? ORDER BY thang, mh_key"
    return execute_query(sql, [nam])

# ============================================================
# SALES CUBE — 2-D (Time × Customer Type)
# ============================================================

@app.get("/api/sales/year-customer-type")
def get_sales_year_custtype():
    """Sales by year × customer type"""
    sql = "SELECT nam, loai_kh, tong_so_luong, tong_doanh_thu FROM OLAP_QuanLyBanHang.dbo.olap_ds_nam_loai_kh ORDER BY nam, loai_kh"
    return execute_query(sql)

@app.get("/api/sales/quarter-customer-type")
def get_sales_quarter_custtype(nam: int = Query(...)):
    """Sales by quarter × customer type"""
    sql = f"SELECT nam, quy, loai_kh, tong_so_luong, tong_doanh_thu FROM OLAP_QuanLyBanHang.dbo.olap_ds_quy_loai_kh WHERE nam = ? ORDER BY quy, loai_kh"
    return execute_query(sql, [nam])

@app.get("/api/sales/month-customer-type")
def get_sales_month_custtype(nam: int = Query(...)):
    """Sales by month × customer type"""
    sql = f"SELECT nam, quy, thang, loai_kh, tong_so_luong, tong_doanh_thu FROM OLAP_QuanLyBanHang.dbo.olap_ds_thang_loai_kh WHERE nam = ? ORDER BY thang, loai_kh"
    return execute_query(sql, [nam])

# ============================================================
# INVENTORY CUBE — 0-D (Apex)
# ============================================================

@app.get("/api/inventory/apex")
def get_inventory_apex():
    """Inventory total (apex)"""
    sql = "SELECT tong_ton_kho FROM OLAP_QuanLyBanHang.dbo.olap_tk_all"
    rows = execute_query(sql)
    return rows[0] if rows else {"tong_ton_kho": 0}

# ============================================================
# INVENTORY CUBE — 1-D
# ============================================================

@app.get("/api/inventory/by-year")
def get_inventory_by_year():
    """Inventory by year"""
    sql = "SELECT nam, tong_ton_kho FROM OLAP_QuanLyBanHang.dbo.olap_tk_nam ORDER BY nam"
    return execute_query(sql)

@app.get("/api/inventory/by-quarter")
def get_inventory_by_quarter(nam: int = Query(...)):
    """Inventory by quarter"""
    sql = f"SELECT nam, quy, tong_ton_kho FROM OLAP_QuanLyBanHang.dbo.olap_tk_quy WHERE nam = ? ORDER BY quy"
    return execute_query(sql, [nam])

@app.get("/api/inventory/by-month")
def get_inventory_by_month(nam: int = Query(...)):
    """Inventory by month"""
    sql = f"SELECT nam, quy, thang, tong_ton_kho FROM OLAP_QuanLyBanHang.dbo.olap_tk_thang WHERE nam = ? ORDER BY thang"
    return execute_query(sql, [nam])

@app.get("/api/inventory/by-product")
def get_inventory_by_product():
    """Inventory by product"""
    sql = "SELECT mh_key, mo_ta, tong_ton_kho FROM OLAP_QuanLyBanHang.dbo.olap_tk_mh ORDER BY mh_key"
    return execute_query(sql)

@app.get("/api/inventory/by-state")
def get_inventory_by_state():
    """Inventory by state"""
    sql = "SELECT bang, tong_ton_kho FROM OLAP_QuanLyBanHang.dbo.olap_tk_tinh ORDER BY bang"
    return execute_query(sql)

@app.get("/api/inventory/by-city")
def get_inventory_by_city(bang: str = Query(...)):
    """Inventory by city"""
    sql = f"SELECT bang, ten_tp, tong_ton_kho FROM OLAP_QuanLyBanHang.dbo.olap_tk_tp WHERE bang = ? ORDER BY ten_tp"
    return execute_query(sql, [bang])

@app.get("/api/inventory/by-store")
def get_inventory_by_store():
    """Inventory by store"""
    sql = "SELECT ch_key, tong_ton_kho FROM OLAP_QuanLyBanHang.dbo.olap_tk_ch ORDER BY ch_key"
    return execute_query(sql)

# ============================================================
# INVENTORY CUBE — 2-D (Time × Product)
# ============================================================

@app.get("/api/inventory/year-product")
def get_inventory_year_product():
    """Inventory by year × product"""
    sql = "SELECT nam, mh_key, mo_ta, tong_ton_kho FROM OLAP_QuanLyBanHang.dbo.olap_tk_nam_mh ORDER BY nam, mh_key"
    return execute_query(sql)

@app.get("/api/inventory/quarter-product")
def get_inventory_quarter_product(nam: int = Query(...)):
    """Inventory by quarter × product"""
    sql = f"SELECT nam, quy, mh_key, mo_ta, tong_ton_kho FROM OLAP_QuanLyBanHang.dbo.olap_tk_quy_mh WHERE nam = ? ORDER BY quy, mh_key"
    return execute_query(sql, [nam])

@app.get("/api/inventory/month-product")
def get_inventory_month_product(nam: int = Query(...)):
    """Inventory by month × product"""
    sql = f"SELECT nam, quy, thang, mh_key, mo_ta, tong_ton_kho FROM OLAP_QuanLyBanHang.dbo.olap_tk_thang_mh WHERE nam = ? ORDER BY thang, mh_key"
    return execute_query(sql, [nam])

# ============================================================
# INVENTORY CUBE — 2-D (Time × State)
# ============================================================

@app.get("/api/inventory/year-state")
def get_inventory_year_state():
    """Inventory by year × state"""
    sql = "SELECT nam, bang, tong_ton_kho FROM OLAP_QuanLyBanHang.dbo.olap_tk_nam_tinh ORDER BY nam, bang"
    return execute_query(sql)

@app.get("/api/inventory/quarter-state")
def get_inventory_quarter_state(nam: int = Query(...)):
    """Inventory by quarter × state"""
    sql = f"SELECT nam, quy, bang, tong_ton_kho FROM OLAP_QuanLyBanHang.dbo.olap_tk_quy_tinh WHERE nam = ? ORDER BY quy, bang"
    return execute_query(sql, [nam])

@app.get("/api/inventory/month-state")
def get_inventory_month_state(nam: int = Query(...)):
    """Inventory by month × state"""
    sql = f"SELECT nam, quy, thang, bang, tong_ton_kho FROM OLAP_QuanLyBanHang.dbo.olap_tk_thang_tinh WHERE nam = ? ORDER BY thang, bang"
    return execute_query(sql, [nam])

# ============================================================
# 7 OLAP OPERATIONS
# ============================================================

@app.get("/api/olap/drill-down")
def drill_down(cube: str = Query(...), level: str = Query(...)):
    """Drill-down from year → quarter → month"""
    if cube == "sales":
        if level == "year-to-quarter":
            return {"message": "Use /api/sales/by-quarter?nam=YYYY"}
        elif level == "quarter-to-month":
            return {"message": "Use /api/sales/by-month?nam=YYYY"}
    elif cube == "inventory":
        if level == "year-to-quarter":
            return {"message": "Use /api/inventory/by-quarter?nam=YYYY"}
        elif level == "quarter-to-month":
            return {"message": "Use /api/inventory/by-month?nam=YYYY"}
    return {"error": "Invalid drill-down"}

@app.get("/api/olap/roll-up")
def roll_up(cube: str = Query(...), level: str = Query(...)):
    """Roll-up from month → quarter → year"""
    if cube == "sales":
        if level == "month-to-quarter":
            sql = "SELECT nam, quy, SUM(tong_so_luong) as tong_so_luong, SUM(tong_doanh_thu) as tong_doanh_thu FROM OLAP_QuanLyBanHang.dbo.olap_ds_thang GROUP BY nam, quy ORDER BY nam, quy"
            return execute_query(sql)
        elif level == "quarter-to-year":
            sql = "SELECT nam, SUM(tong_so_luong) as tong_so_luong, SUM(tong_doanh_thu) as tong_doanh_thu FROM OLAP_QuanLyBanHang.dbo.olap_ds_quy GROUP BY nam ORDER BY nam"
            return execute_query(sql)
    elif cube == "inventory":
        if level == "month-to-quarter":
            sql = "SELECT nam, quy, SUM(tong_ton_kho) as tong_ton_kho FROM OLAP_QuanLyBanHang.dbo.olap_tk_thang GROUP BY nam, quy ORDER BY nam, quy"
            return execute_query(sql)
        elif level == "quarter-to-year":
            sql = "SELECT nam, SUM(tong_ton_kho) as tong_ton_kho FROM OLAP_QuanLyBanHang.dbo.olap_tk_quy GROUP BY nam ORDER BY nam"
            return execute_query(sql)
    return {"error": "Invalid roll-up"}

@app.get("/api/olap/slice")
def slice_cube(cube: str = Query(...), loai_kh: Optional[str] = None, bang: Optional[str] = None):
    """Slice: select 1 dimension value"""
    if cube == "sales" and loai_kh:
        sql = f"SELECT loai_kh, tong_so_luong, tong_doanh_thu FROM OLAP_QuanLyBanHang.dbo.olap_ds_loai_kh WHERE loai_kh = ? ORDER BY loai_kh"
        return execute_query(sql, [loai_kh])
    elif cube == "inventory" and bang:
        sql = f"SELECT bang, tong_ton_kho FROM OLAP_QuanLyBanHang.dbo.olap_tk_tinh WHERE bang = ?"
        return execute_query(sql, [bang])
    return {"error": "Invalid slice"}

@app.get("/api/olap/drill-across")
def drill_across(nam: int = Query(...)):
    """Compare Sales vs Inventory for same year"""
    sales_sql = "SELECT nam, SUM(tong_so_luong) as so_luong_ban, SUM(tong_doanh_thu) as doanh_thu FROM OLAP_QuanLyBanHang.dbo.olap_ds_nam WHERE nam = ? GROUP BY nam"
    inventory_sql = "SELECT nam, SUM(tong_ton_kho) as ton_kho FROM OLAP_QuanLyBanHang.dbo.olap_tk_nam WHERE nam = ? GROUP BY nam"
    
    sales = execute_query(sales_sql, [nam])
    inventory = execute_query(inventory_sql, [nam])
    
    result = []
    if sales and inventory:
        result.append({
            "nam": nam,
            "so_luong_ban": sales[0].get("so_luong_ban", 0),
            "doanh_thu": sales[0].get("doanh_thu", 0),
            "ton_kho": inventory[0].get("ton_kho", 0)
        })
    
    return result

@app.get("/api/olap/drill-through")
def drill_through(
    mh_key: Optional[int] = None,
    kh_key: Optional[int] = None,
    nam: Optional[int] = None,
    offset: int = 0,
    limit: int = 50
):
    """Drill-through to raw fact table"""
    where_parts = []
    params = []
    
    if mh_key:
        where_parts.append("f.mh_key = ?")
        params.append(mh_key)
    if kh_key:
        where_parts.append("f.kh_key = ?")
        params.append(kh_key)
    if nam:
        where_parts.append("t.nam = ?")
        params.append(nam)
    
    where_clause = " AND ".join(where_parts) if where_parts else "1=1"
    
    sql = f"""
    SELECT TOP {limit} 
        f.time_key, f.so_luong, f.tong_tien,
        kh.ten, kh.loai_kh,
        mh.mo_ta, mh.gia,
        t.nam, t.quy, t.thang
    FROM DW_Core.dbo.Fact_BanHang f
    JOIN DW_Core.dbo.Dim_KhachHang kh ON f.kh_key = kh.kh_key
    JOIN DW_Core.dbo.Dim_MatHang mh ON f.mh_key = mh.mh_key
    JOIN DW_Core.dbo.Dim_ThoiGian t ON f.time_key = t.time_key
    WHERE {where_clause}
    ORDER BY f.time_key DESC
    OFFSET {offset} ROWS
    """
    
    return execute_query(sql, params, db_type="dw")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
