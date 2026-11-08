"""
Web app OLAP Quản Lý Bán Hàng — FastAPI backend.
Chạy: uvicorn main:app --reload --port 8000
"""
import os
from contextlib import contextmanager
from typing import Optional

import pyodbc
from dotenv import load_dotenv
from fastapi import FastAPI, HTTPException, Query
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse
from fastapi.staticfiles import StaticFiles

load_dotenv()

DB_SERVER = os.getenv("DB_SERVER", "localhost")
DB_USER = os.getenv("DB_USER", "sa")
DB_PASSWORD = os.getenv("DB_PASSWORD", "123456")
DB_DRIVER = os.getenv("DB_DRIVER", "ODBC Driver 17 for SQL Server")
DB_OLAP = os.getenv("DB_OLAP", "OLAP_QuanLyBanHang")
DB_DW = os.getenv("DB_DW", "DW_Core")


def _conn_str(database: str) -> str:
    return (
        f"DRIVER={{{DB_DRIVER}}};"
        f"SERVER={DB_SERVER};"
        f"DATABASE={database};"
        f"UID={DB_USER};"
        f"PWD={DB_PASSWORD};"
        "TrustServerCertificate=yes;"
    )


@contextmanager
def get_cursor(database: str):
    conn = pyodbc.connect(_conn_str(database))
    try:
        yield conn.cursor()
    finally:
        conn.close()


def query_all(database: str, sql: str, params: list | None = None) -> list[dict]:
    with get_cursor(database) as cur:
        cur.execute(sql, params or [])
        cols = [c[0] for c in cur.description]
        return [dict(zip(cols, row)) for row in cur.fetchall()]


def query_one(database: str, sql: str, params: list | None = None) -> dict | None:
    rows = query_all(database, sql, params)
    return rows[0] if rows else None


# =====================================================================
# Cuboid routing
# =====================================================================
def chon_cuboid_ds(nhom: str, co_loai_kh: bool, co_kh: bool, co_mh: bool) -> str:
    is_time = nhom in ("nam", "quy", "thang")
    if is_time:
        if co_kh and co_mh:
            return f"olap_ds_{nhom}_mh_kh"
        if co_loai_kh and co_mh:
            return f"olap_ds_{nhom}_mh_loai_kh"
        if co_kh:
            return f"olap_ds_{nhom}_kh"
        if co_loai_kh:
            return f"olap_ds_{nhom}_loai_kh"
        if co_mh:
            return f"olap_ds_{nhom}_mh"
        return f"olap_ds_{nhom}"
    if nhom == "mh":
        if co_kh:
            return "olap_ds_mh_kh"
        if co_loai_kh:
            return "olap_ds_mh_loai_kh"
        return "olap_ds_mh"
    if nhom == "loai_kh":
        return "olap_ds_loai_kh_kh" if co_kh else "olap_ds_loai_kh"
    if nhom == "kh":
        return "olap_ds_kh"
    raise HTTPException(400, f"nhom không hợp lệ cho sales cube: {nhom}")


def chon_cuboid_tk(nhom: str, co_mh: bool, co_tinh: bool, co_tp: bool, co_ch: bool) -> str:
    is_time = nhom in ("nam", "quy", "thang")
    if is_time:
        if co_mh and co_ch:
            return f"olap_tk_{nhom}_mh_ch"
        if co_mh and co_tp:
            return f"olap_tk_{nhom}_mh_tp"
        if co_mh and co_tinh:
            return f"olap_tk_{nhom}_mh_tinh"
        if co_mh:
            return f"olap_tk_{nhom}_mh"
        if co_ch:
            return f"olap_tk_{nhom}_ch"
        if co_tp:
            return f"olap_tk_{nhom}_tp"
        if co_tinh:
            return f"olap_tk_{nhom}_tinh"
        return f"olap_tk_{nhom}"
    if nhom == "mh":
        if co_ch:
            return "olap_tk_mh_ch"
        if co_tp:
            return "olap_tk_mh_tp"
        if co_tinh:
            return "olap_tk_mh_tinh"
        return "olap_tk_mh"
    if nhom in ("tinh", "tp", "ch"):
        return f"olap_tk_{nhom}"
    raise HTTPException(400, f"nhom không hợp lệ cho inventory cube: {nhom}")


def build_where(filters: dict) -> tuple[str, list]:
    clauses, params = [], []
    for col, val in filters.items():
        if val is not None and val != "":
            clauses.append(f"{col} = ?")
            params.append(val)
    where = ("WHERE " + " AND ".join(clauses)) if clauses else ""
    return where, params


# Cột dimension theo nhóm để build SELECT/ORDER BY/GROUP BY
DIM_COLS_DS = {
    "nam": ["nam"],
    "quy": ["nam", "quy"],
    "thang": ["nam", "quy", "thang"],
    "mh": ["mh_key", "mo_ta"],
    "loai_kh": ["loai_kh"],
    "kh": ["kh_key", "ten", "loai_kh"],
}

DIM_COLS_TK = {
    "nam": ["nam"],
    "quy": ["nam", "quy"],
    "thang": ["nam", "quy", "thang"],
    "mh": ["mh_key", "mo_ta"],
    "tinh": ["bang"],
    "tp": ["bang", "ten_tp"],
    "ch": ["ch_key"],
}


# =====================================================================
# App
# =====================================================================
app = FastAPI(title="OLAP Quản Lý Bán Hàng")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)


# =====================================================================
# Metadata
# =====================================================================
@app.get("/api/metadata/nam")
def get_nam():
    rows = query_all(DB_OLAP, "SELECT DISTINCT nam FROM olap_ds_nam ORDER BY nam")
    return [r["nam"] for r in rows]


@app.get("/api/metadata/loai-kh")
def get_loai_kh():
    rows = query_all(DB_OLAP, "SELECT DISTINCT loai_kh FROM olap_ds_loai_kh ORDER BY loai_kh")
    return [r["loai_kh"] for r in rows]


@app.get("/api/metadata/mat-hang")
def get_mat_hang():
    return query_all(DB_OLAP, "SELECT mh_key, mo_ta FROM olap_ds_mh ORDER BY mo_ta")


@app.get("/api/metadata/tinh")
def get_tinh():
    rows = query_all(DB_OLAP, "SELECT DISTINCT bang FROM olap_tk_tinh ORDER BY bang")
    return [r["bang"] for r in rows]


# =====================================================================
# Sales Cube
# =====================================================================
@app.get("/api/doanh-so/tong")
def get_doanh_so_tong():
    row = query_one(DB_OLAP, "SELECT tong_so_luong, tong_doanh_thu FROM olap_ds_all")
    return row or {"tong_so_luong": 0, "tong_doanh_thu": 0}


@app.get("/api/doanh-so")
def get_doanh_so(
    nhom: str = Query(..., description="nam | quy | thang | mh | loai_kh | kh"),
    loc_nam: Optional[int] = None,
    loc_quy: Optional[int] = None,
    loc_loai_kh: Optional[str] = None,
    loc_mh: Optional[str] = None,
    loc_kh: Optional[str] = None,
):
    table = chon_cuboid_ds(
        nhom,
        co_loai_kh=loc_loai_kh is not None,
        co_kh=loc_kh is not None,
        co_mh=loc_mh is not None,
    )
    filters = {
        "nam": loc_nam,
        "quy": loc_quy,
        "loai_kh": loc_loai_kh,
        "mh_key": loc_mh,
        "kh_key": loc_kh,
    }
    where, params = build_where(filters)
    dims = DIM_COLS_DS[nhom]
    select_cols = ", ".join(dims) + ", tong_so_luong, tong_doanh_thu"
    order_by = ", ".join(dims)
    sql = f"SELECT {select_cols} FROM {table} {where} ORDER BY {order_by}"
    return {"cuboid": table, "data": query_all(DB_OLAP, sql, params)}


# =====================================================================
# Inventory Cube
# =====================================================================
@app.get("/api/ton-kho/tong")
def get_ton_kho_tong():
    row = query_one(DB_OLAP, "SELECT tong_ton_kho FROM olap_tk_all")
    return row or {"tong_ton_kho": 0}


@app.get("/api/ton-kho")
def get_ton_kho(
    nhom: str = Query(..., description="nam | quy | thang | mh | tinh | tp | ch"),
    loc_nam: Optional[int] = None,
    loc_quy: Optional[int] = None,
    loc_bang: Optional[str] = None,
    loc_mh: Optional[str] = None,
    loc_ch: Optional[str] = None,
):
    table = chon_cuboid_tk(
        nhom,
        co_mh=loc_mh is not None,
        co_tinh=loc_bang is not None,
        co_tp=False,
        co_ch=loc_ch is not None,
    )
    filters = {
        "nam": loc_nam,
        "quy": loc_quy,
        "bang": loc_bang,
        "mh_key": loc_mh,
        "ch_key": loc_ch,
    }
    where, params = build_where(filters)
    dims = DIM_COLS_TK[nhom]
    select_cols = ", ".join(dims) + ", tong_ton_kho"
    order_by = ", ".join(dims)
    sql = f"SELECT {select_cols} FROM {table} {where} ORDER BY {order_by}"
    return {"cuboid": table, "data": query_all(DB_OLAP, sql, params)}


# =====================================================================
# 7 OLAP operations
# =====================================================================
@app.get("/api/olap/roll-up")
def olap_roll_up(cube: str, tu: str, len_: str = Query(..., alias="len")):
    """Roll-up: chuyển sang cuboid level cao hơn."""
    if cube == "ds":
        return get_doanh_so(nhom=len_)
    if cube == "tk":
        return get_ton_kho(nhom=len_)
    raise HTTPException(400, "cube phải là 'ds' hoặc 'tk'")


@app.get("/api/olap/drill-down")
def olap_drill_down(
    cube: str,
    xuong: str,
    loc_nam: Optional[int] = None,
    loc_quy: Optional[int] = None,
    loc_bang: Optional[str] = None,
):
    if cube == "ds":
        return get_doanh_so(nhom=xuong, loc_nam=loc_nam, loc_quy=loc_quy)
    if cube == "tk":
        return get_ton_kho(nhom=xuong, loc_nam=loc_nam, loc_quy=loc_quy, loc_bang=loc_bang)
    raise HTTPException(400, "cube phải là 'ds' hoặc 'tk'")


@app.get("/api/olap/slice")
def olap_slice(cube: str, chieu: str, gia_tri: str):
    """Slice: cố định 1 chiều = 1 giá trị, group theo chiều khác."""
    if cube == "ds":
        if chieu == "nam":
            return get_doanh_so(nhom="loai_kh", loc_nam=int(gia_tri))
        if chieu == "loai_kh":
            return get_doanh_so(nhom="nam", loc_loai_kh=gia_tri)
        if chieu == "mh":
            return get_doanh_so(nhom="nam", loc_mh=gia_tri)
    if cube == "tk":
        if chieu == "nam":
            return get_ton_kho(nhom="tinh", loc_nam=int(gia_tri))
        if chieu == "bang":
            return get_ton_kho(nhom="nam", loc_bang=gia_tri)
    raise HTTPException(400, "Tham số slice không hợp lệ")


@app.get("/api/olap/dice")
def olap_dice(
    cube: str,
    nhom: str = "nam",
    loc_nam: Optional[int] = None,
    loc_quy: Optional[int] = None,
    loc_loai_kh: Optional[str] = None,
    loc_bang: Optional[str] = None,
    loc_mh: Optional[str] = None,
):
    if cube == "ds":
        return get_doanh_so(
            nhom=nhom, loc_nam=loc_nam, loc_quy=loc_quy,
            loc_loai_kh=loc_loai_kh, loc_mh=loc_mh,
        )
    if cube == "tk":
        return get_ton_kho(
            nhom=nhom, loc_nam=loc_nam, loc_quy=loc_quy,
            loc_bang=loc_bang, loc_mh=loc_mh,
        )
    raise HTTPException(400, "cube phải là 'ds' hoặc 'tk'")


@app.get("/api/olap/pivot")
def olap_pivot(cube: str, hang: str, cot: str):
    """Pivot: trả ma trận hàng × cột."""
    if cube == "ds":
        # Map hang+cot -> nhom thích hợp
        valid = {("nam", "loai_kh"), ("loai_kh", "nam"), ("nam", "mh"), ("mh", "nam")}
        if (hang, cot) not in valid:
            raise HTTPException(400, f"Cặp hang/cot không hỗ trợ: {hang}/{cot}")
        if {hang, cot} == {"nam", "loai_kh"}:
            table = "olap_ds_nam_loai_kh"
            sql = f"SELECT nam, loai_kh, tong_doanh_thu FROM {table}"
        else:
            table = "olap_ds_nam_mh"
            sql = f"SELECT nam, mh_key, mo_ta, tong_doanh_thu FROM {table}"
        rows = query_all(DB_OLAP, sql)
        labels_hang = sorted({str(r[hang]) for r in rows})
        cot_field = "mo_ta" if cot == "mh" else cot
        if hang == "mh":
            hang_field = "mo_ta"
            labels_hang = sorted({r["mo_ta"] for r in rows})
        else:
            hang_field = hang
        labels_cot = sorted({str(r[cot_field]) for r in rows})
        idx_h = {v: i for i, v in enumerate(labels_hang)}
        idx_c = {v: i for i, v in enumerate(labels_cot)}
        matrix = [[0 for _ in labels_cot] for _ in labels_hang]
        for r in rows:
            h = str(r[hang_field])
            c = str(r[cot_field])
            if h in idx_h and c in idx_c:
                matrix[idx_h[h]][idx_c[c]] = float(r["tong_doanh_thu"] or 0)
        return {"labels_hang": labels_hang, "labels_cot": labels_cot, "matrix": matrix}
    raise HTTPException(400, "Pivot hiện chỉ hỗ trợ cube='ds'")


@app.get("/api/olap/drill-across")
def olap_drill_across(nhom: str = "nam"):
    """Kết hợp doanh-so + ton-kho theo cùng chiều thời gian."""
    if nhom not in ("nam", "quy", "thang"):
        raise HTTPException(400, "nhom phải là nam | quy | thang")
    ds = query_all(DB_OLAP, f"SELECT {', '.join(DIM_COLS_DS[nhom])}, tong_doanh_thu FROM olap_ds_{nhom}")
    tk = query_all(DB_OLAP, f"SELECT {', '.join(DIM_COLS_TK[nhom])}, tong_ton_kho FROM olap_tk_{nhom}")
    key = lambda r: tuple(r[c] for c in DIM_COLS_DS[nhom])
    tk_map = {key(r): r["tong_ton_kho"] for r in tk}
    out = []
    for r in ds:
        item = {c: r[c] for c in DIM_COLS_DS[nhom]}
        item["tong_doanh_thu"] = float(r["tong_doanh_thu"] or 0)
        item["tong_ton_kho"] = float(tk_map.get(key(r), 0) or 0)
        out.append(item)
    return out


@app.get("/api/olap/drill-through")
def olap_drill_through(
    kh_key: Optional[str] = None,
    mh_key: Optional[str] = None,
    nam: Optional[int] = None,
    limit: int = 200,
):
    """Query thẳng DW_Core.Fact_BanHang — KHÔNG qua cuboid."""
    clauses, params = [], []
    if kh_key:
        clauses.append("f.kh_key = ?")
        params.append(kh_key)
    if mh_key:
        clauses.append("f.mh_key = ?")
        params.append(mh_key)
    if nam:
        clauses.append("t.nam = ?")
        params.append(nam)
    where = ("WHERE " + " AND ".join(clauses)) if clauses else ""
    sql = f"""
        SELECT TOP {int(limit)}
            f.time_key, t.nam, t.quy, t.thang,
            kh.ten AS ten_kh, mh.mo_ta AS mo_ta_mh,
            f.so_luong, f.tong_tien
        FROM Fact_BanHang f
        JOIN Dim_ThoiGian t  ON f.time_key = t.time_key
        JOIN Dim_KhachHang kh ON f.kh_key = kh.kh_key
        JOIN Dim_MatHang mh   ON f.mh_key = mh.mh_key
        {where}
        ORDER BY f.time_key DESC
    """
    return query_all(DB_DW, sql, params)


# =====================================================================
# Frontend tĩnh
# =====================================================================
app.mount("/static", StaticFiles(directory="static"), name="static")


@app.get("/")
def root():
    return FileResponse("static/index.html")
