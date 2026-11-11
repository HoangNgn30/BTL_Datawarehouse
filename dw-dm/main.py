"""
Web app OLAP Quản Lý Bán Hàng — FastAPI backend.
Chạy: uvicorn main:app --reload --port 8000
"""
import os
from contextlib import contextmanager
from pathlib import Path
from cube_queries import sales_query, inventory_query, DIM_COLS_DS, DIM_COLS_TK
from typing import Optional

import pyodbc
from dotenv import load_dotenv
from fastapi import FastAPI, HTTPException, Query
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse
from fastapi.staticfiles import StaticFiles

BASE_DIR = Path(__file__).resolve().parent
load_dotenv(BASE_DIR / ".env")

DB_SERVER = os.getenv("DB_SERVER", r".\MSSQLSERVER01")
DB_USER = os.getenv("DB_USER", "")
DB_PASSWORD = os.getenv("DB_PASSWORD", "")
DB_DRIVER = os.getenv("DB_DRIVER", "ODBC Driver 17 for SQL Server")
DB_OLAP = os.getenv("DB_OLAP", "OLAP_QuanLyBanHang")
DB_DW = os.getenv("DB_DW", "DW_Core")


def _conn_str(database: str) -> str:
    trusted = os.getenv("DB_TRUSTED", "yes").lower() in ("1", "true", "yes")
    if not trusted and (not DB_USER or not DB_PASSWORD):
        raise RuntimeError("SQL Authentication requires DB_USER and DB_PASSWORD.")
    authentication = "Trusted_Connection=yes;" if trusted else f"UID={DB_USER};PWD={DB_PASSWORD};"
    return (
        f"DRIVER={{{DB_DRIVER}}};"
        f"SERVER={DB_SERVER};"
        f"DATABASE={database};"
        + authentication
        + "TrustServerCertificate=yes;"
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
# App
# =====================================================================
app = FastAPI(title="OLAP Quản Lý Bán Hàng")

app.add_middleware(
    CORSMiddleware,
    allow_origins=[origin.strip() for origin in os.getenv("CORS_ORIGINS", "http://localhost:3000,http://127.0.0.1:3000").split(",") if origin.strip() and origin.strip() != "*"],
    allow_methods=["GET"],
    allow_headers=["Accept", "Content-Type"],
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


def cube_response(builder, **kwargs):
    try:
        table, dims, lattice, sql, params = builder(**kwargs)
    except ValueError as error:
        raise HTTPException(400, str(error)) from error
    return {"cuboid": table, "dim_cols": dims, "lattice": lattice, "data": query_all(DB_OLAP, sql, params)}


@app.get("/api/doanh-so/v2")
def get_sales_v2(time_axis: str = "none", mh_axis: str = "none", kh_axis: str = "none",
                 loc_nam: Optional[int] = None, loc_quy: Optional[int] = None,
                 loc_thang: Optional[int] = None, loc_loai_kh: Optional[str] = None,
                 loc_mh: Optional[str] = None, loc_kh: Optional[str] = None):
    return cube_response(sales_query, time_axis=time_axis, mh_axis=mh_axis, kh_axis=kh_axis,
                         nam=loc_nam, quy=loc_quy, thang=loc_thang,
                         loai_kh=loc_loai_kh, mh_key=loc_mh, kh_key=loc_kh)


@app.get("/api/doanh-so")
def get_doanh_so(nhom: str, loc_nam: Optional[int] = None, loc_quy: Optional[int] = None,
                loc_loai_kh: Optional[str] = None, loc_mh: Optional[str] = None,
                loc_kh: Optional[str] = None, loc_thang: Optional[int] = None):
    if nhom not in {"nam", "quy", "thang", "mh", "loai_kh", "kh"}:
        raise HTTPException(400, "Nhóm doanh số không hợp lệ")
    return get_sales_v2(time_axis=nhom if nhom in {"nam", "quy", "thang"} else "none",
                        mh_axis="mh" if nhom == "mh" else "none",
                        kh_axis=nhom if nhom in {"kh", "loai_kh"} else "none",
                        loc_nam=loc_nam, loc_quy=loc_quy, loc_thang=loc_thang,
                        loc_loai_kh=loc_loai_kh, loc_mh=loc_mh, loc_kh=loc_kh)


@app.get("/api/ton-kho/tong")
def get_ton_kho_tong():
    return query_one(DB_OLAP, "SELECT tong_ton_kho FROM olap_tk_all") or {"tong_ton_kho": 0}


@app.get("/api/ton-kho/v2")
def get_inventory_v2(time_axis: str = "none", mh_axis: str = "none", loc_axis: str = "none",
                     loc_nam: Optional[int] = None, loc_quy: Optional[int] = None,
                     loc_thang: Optional[int] = None, loc_bang: Optional[str] = None,
                     loc_mh: Optional[str] = None, loc_ch: Optional[str] = None,
                     loc_tp: Optional[str] = None):
    return cube_response(inventory_query, dw_database=DB_DW, time_axis=time_axis,
                         mh_axis=mh_axis, loc_axis=loc_axis, nam=loc_nam, quy=loc_quy,
                         thang=loc_thang, bang=loc_bang, mh_key=loc_mh, ch_key=loc_ch, ten_tp=loc_tp)


@app.get("/api/ton-kho")
def get_ton_kho(nhom: str, loc_nam: Optional[int] = None, loc_quy: Optional[int] = None,
               loc_bang: Optional[str] = None, loc_mh: Optional[str] = None,
               loc_ch: Optional[str] = None, loc_thang: Optional[int] = None):
    if nhom not in {"nam", "quy", "thang", "mh", "tinh", "tp", "ch"}:
        raise HTTPException(400, "Nhóm tồn kho không hợp lệ")
    return get_inventory_v2(time_axis=nhom if nhom in {"nam", "quy", "thang"} else "none",
                            mh_axis="mh" if nhom == "mh" else "none",
                            loc_axis=nhom if nhom in {"tinh", "tp", "ch"} else "none",
                            loc_nam=loc_nam, loc_quy=loc_quy, loc_thang=loc_thang,
                            loc_bang=loc_bang, loc_mh=loc_mh, loc_ch=loc_ch)


# =====================================================================
# 7 OLAP operations
# =====================================================================
@app.get("/api/olap/roll-up")
def olap_roll_up(cube: str, tu: str, len_: str = Query(..., alias="len")):
    """Roll-up: chuyển sang cuboid level cao hơn."""
    hierarchy = {"nam": 0, "quy": 1, "thang": 2}
    if tu not in hierarchy or len_ not in hierarchy or hierarchy[tu] <= hierarchy[len_]:
        raise HTTPException(400, "Roll-up chỉ hỗ trợ tháng → quý, tháng → năm hoặc quý → năm")
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
    if chieu == "nam":
        try:
            int(gia_tri)
        except ValueError:
            raise HTTPException(400, "Năm phải là số nguyên")
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
        hang_field = "mh_key" if hang == "mh" else hang
        cot_field = "mh_key" if cot == "mh" else cot
        def natural_key(value):
            return (0, int(value)) if value.lstrip('-').isdigit() else (1, value)
        labels_hang = sorted({str(r[hang_field]) for r in rows}, key=natural_key)
        labels_cot = sorted({str(r[cot_field]) for r in rows}, key=natural_key)
        idx_h = {v: i for i, v in enumerate(labels_hang)}
        idx_c = {v: i for i, v in enumerate(labels_cot)}
        matrix = [[0 for _ in labels_cot] for _ in labels_hang]
        for r in rows:
            h = str(r[hang_field])
            c = str(r[cot_field])
            if h in idx_h and c in idx_c:
                matrix[idx_h[h]][idx_c[c]] += float(r["tong_doanh_thu"] or 0)
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
    limit: int = Query(200, ge=1, le=2000),
    quy: Optional[int] = None,
    thang: Optional[int] = None,
    loai_kh: Optional[str] = None,
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
    for column, value in (("t.quy", quy), ("t.thang", thang), ("kh.loai_kh", loai_kh)):
        if value is not None:
            clauses.append(f"{column} = ?")
            params.append(value)
    where = ("WHERE " + " AND ".join(clauses)) if clauses else ""
    sql = f"""
        SELECT TOP {int(limit)}
            f.ma_don, n.ngay, f.time_key, t.nam, t.quy, t.thang,
            kh.ten AS ten_kh, mh.mo_ta AS mo_ta_mh,
            f.so_luong, f.tong_tien
        FROM Fact_BanHang f
        JOIN Dim_Ngay n ON n.ngay_key = f.ngay_key
        JOIN Dim_ThoiGian t  ON f.time_key = t.time_key
        JOIN Dim_KhachHang kh ON f.kh_key = kh.kh_key
        JOIN Dim_MatHang mh   ON f.mh_key = mh.mh_key
        {where}
        ORDER BY f.time_key DESC
    """
    return query_all(DB_DW, sql, params)


# =====================================================================
# 9 báo cáo OLAP theo đề bài (truy vấn galaxy schema DW_Core)
# =====================================================================
LATEST_KHO = "k.time_key = (SELECT MAX(k2.time_key) FROM Fact_Kho k2 WHERE k2.ch_key = k.ch_key AND k2.mh_key = k.mh_key)"


@app.get("/api/bao-cao/1")
def bc1(ch: Optional[str] = None):
    """YC1: cửa hàng + thành phố, bang, SĐT + mô tả, kích cỡ, trọng lượng, đơn giá các mặt hàng ở kho đó."""
    where, params = ("WHERE ch.ch_key = ?", [ch]) if ch else ("", [])
    return query_all(DB_DW, f"""
        SELECT ch.ch_key, v.ten_tp, v.bang, ch.so_dt, mh.mh_key, mh.mo_ta, mh.kich_co, mh.trong_luong, mh.gia
        FROM Dim_CuaHang ch JOIN Dim_VPDD v ON v.vp_key = ch.vp_key
        JOIN (SELECT DISTINCT ch_key, mh_key FROM Fact_Kho) k ON k.ch_key = ch.ch_key
        JOIN Dim_MatHang mh ON mh.mh_key = k.mh_key {where}
        ORDER BY TRY_CONVERT(BIGINT,ch.ch_key), ch.ch_key, TRY_CONVERT(BIGINT,mh.mh_key), mh.mh_key""", params)


@app.get("/api/bao-cao/2")
def bc2(kh: str):
    """YC2: các đơn đặt hàng với tên KH và ngày đặt của khách đó."""
    return query_all(DB_DW, """
        SELECT * FROM (SELECT DISTINCT f.ma_don, kh.kh_key, kh.ten, n.ngay
        FROM Fact_BanHang f JOIN Dim_KhachHang kh ON kh.kh_key = f.kh_key
        JOIN Dim_Ngay n ON n.ngay_key = f.ngay_key
        WHERE f.kh_key = ?) ordered_data ORDER BY ngay, TRY_CONVERT(BIGINT,ma_don), ma_don""", [kh])


@app.get("/api/bao-cao/3")
def bc3(kh: str):
    """YC3: các cửa hàng (tên TP, SĐT) có bán các mặt hàng do một KH đặt."""
    return query_all(DB_DW, """
        SELECT * FROM (SELECT DISTINCT ch.ch_key, v.ten_tp, ch.so_dt
        FROM Fact_BanHang f
        JOIN (SELECT DISTINCT ch_key, mh_key FROM Fact_Kho) k ON k.mh_key = f.mh_key
        JOIN Dim_CuaHang ch ON ch.ch_key = k.ch_key JOIN Dim_VPDD v ON v.vp_key = ch.vp_key
        WHERE f.kh_key = ?) ordered_data ORDER BY TRY_CONVERT(BIGINT,ch_key), ch_key""", [kh])


@app.get("/api/bao-cao/4")
def bc4(mh: str, muc: int = 100):
    """YC4: địa chỉ VPĐD, TP, bang của các cửa hàng lưu kho một mặt hàng với số lượng > mức."""
    return query_all(DB_DW, f"""
        SELECT DISTINCT ch.ch_key, v.dia_chi_vp, v.ten_tp, v.bang, k.so_luong
        FROM Fact_Kho k JOIN Dim_CuaHang ch ON ch.ch_key = k.ch_key JOIN Dim_VPDD v ON v.vp_key = ch.vp_key
        WHERE k.mh_key = ? AND k.so_luong > ? AND {LATEST_KHO}
        ORDER BY k.so_luong DESC""", [mh, muc])


@app.get("/api/bao-cao/5")
def bc5(ma_don: str):
    """YC5: với mỗi đơn, mặt hàng đặt + mô tả, cửa hàng đáp ứng, TP và các cửa hàng có bán mặt hàng đó."""
    return query_all(DB_DW, """
        SELECT f.ma_don, f.mh_key, mh.mo_ta, pb.ch_key AS ch_dap_ung, pb.so_luong_cap, v.ten_tp AS tp_dap_ung,
               k.ch_key AS ch_co_ban, v2.ten_tp AS tp_ch_co_ban
        FROM Fact_BanHang f JOIN Dim_MatHang mh ON mh.mh_key = f.mh_key
        LEFT JOIN Fact_PhanBo pb ON pb.ma_don = f.ma_don AND pb.mh_key = f.mh_key
        LEFT JOIN Dim_CuaHang c ON c.ch_key = pb.ch_key LEFT JOIN Dim_VPDD v ON v.vp_key = c.vp_key
        LEFT JOIN (SELECT DISTINCT ch_key, mh_key FROM Fact_Kho) k ON k.mh_key = f.mh_key
        LEFT JOIN Dim_CuaHang c2 ON c2.ch_key = k.ch_key LEFT JOIN Dim_VPDD v2 ON v2.vp_key = c2.vp_key
        WHERE f.ma_don = ? ORDER BY TRY_CONVERT(BIGINT,f.mh_key), f.mh_key, TRY_CONVERT(BIGINT,k.ch_key), k.ch_key""", [ma_don])


@app.get("/api/bao-cao/6")
def bc6(kh: str):
    """YC6: thành phố và bang nơi một KH sinh sống."""
    return query_all(DB_DW, """
        SELECT kh.kh_key, kh.ten, v.ten_tp, v.bang
        FROM Dim_KhachHang kh JOIN Dim_VPDD v ON v.vp_key = kh.vp_key WHERE kh.kh_key = ?""", [kh])


@app.get("/api/bao-cao/7")
def bc7(mh: str, tp: str):
    """YC7: mức tồn kho một mặt hàng tại tất cả cửa hàng của một thành phố (snapshot mới nhất)."""
    return query_all(DB_DW, f"""
        SELECT ch.ch_key, v.ten_tp, k.mh_key, k.so_luong AS ton_kho
        FROM Fact_Kho k JOIN Dim_CuaHang ch ON ch.ch_key = k.ch_key JOIN Dim_VPDD v ON v.vp_key = ch.vp_key
        WHERE k.mh_key = ? AND ch.vp_key = ? AND {LATEST_KHO}
        ORDER BY TRY_CONVERT(BIGINT,ch.ch_key), ch.ch_key""", [mh, tp])


@app.get("/api/bao-cao/8")
def bc8(ma_don: str):
    """YC8: mặt hàng, số lượng đặt, khách hàng, cửa hàng và thành phố của một đơn."""
    return query_all(DB_DW, """
        SELECT f.ma_don, f.mh_key, mh.mo_ta, f.so_luong, f.gia_dat, kh.ten AS khach_hang, pb.ch_key, pb.so_luong_cap, v.ten_tp
        FROM Fact_BanHang f JOIN Dim_MatHang mh ON mh.mh_key = f.mh_key
        JOIN Dim_KhachHang kh ON kh.kh_key = f.kh_key
        LEFT JOIN Fact_PhanBo pb ON pb.ma_don = f.ma_don AND pb.mh_key = f.mh_key
        LEFT JOIN Dim_CuaHang c ON c.ch_key = pb.ch_key LEFT JOIN Dim_VPDD v ON v.vp_key = c.vp_key
        WHERE f.ma_don = ? ORDER BY TRY_CONVERT(BIGINT,f.mh_key), f.mh_key""", [ma_don])


@app.get("/api/bao-cao/9")
def bc9(loai: str = Query("du_lich", description="du_lich | buu_dien | ca_hai")):
    """YC9: khách hàng du lịch / bưu điện / thuộc cả hai loại."""
    cond = {
        "du_lich": "la_du_lich = 1",
        "buu_dien": "la_buu_dien = 1",
        "ca_hai": "la_du_lich = 1 AND la_buu_dien = 1",
    }.get(loai)
    if cond is None:
        raise HTTPException(400, "loai phải là du_lich | buu_dien | ca_hai")
    return query_all(DB_DW, f"""
        SELECT kh_key, ten, loai_kh, huong_dan_vien, dia_chi_buu_dien
        FROM Dim_KhachHang WHERE {cond} ORDER BY TRY_CONVERT(BIGINT,kh_key), kh_key""")


@app.get("/api/bao-cao/meta")
def bc_meta():
    return {
        "khach_hang": query_all(DB_DW, "SELECT kh_key, ten FROM Dim_KhachHang ORDER BY TRY_CONVERT(BIGINT,kh_key), kh_key"),
        "mat_hang": query_all(DB_DW, "SELECT mh_key, mo_ta FROM Dim_MatHang ORDER BY TRY_CONVERT(BIGINT,mh_key), mh_key"),
        "cua_hang": query_all(DB_DW, "SELECT ch_key FROM Dim_CuaHang ORDER BY TRY_CONVERT(BIGINT,ch_key), ch_key"),
        "thanh_pho": query_all(DB_DW, "SELECT vp_key, ten_tp, bang FROM Dim_VPDD ORDER BY TRY_CONVERT(BIGINT,vp_key), vp_key"),
        "don_hang": [r["ma_don"] for r in query_all(DB_DW, "SELECT ma_don FROM (SELECT DISTINCT ma_don FROM Fact_BanHang) orders ORDER BY TRY_CONVERT(BIGINT,ma_don), ma_don")],
    }


@app.get("/api/olap/drill-through-kho")
def olap_drill_through_kho(ch_key: Optional[str] = None, mh_key: Optional[str] = None, nam: Optional[int] = None, quy: Optional[int] = None, thang: Optional[int] = None, limit: int = Query(200, ge=1, le=2000)):
    """Drill-through xuống Fact_Kho (cube tồn kho)."""
    clauses, params = [], []
    if ch_key:
        clauses.append("f.ch_key = ?"); params.append(ch_key)
    if mh_key:
        clauses.append("f.mh_key = ?"); params.append(mh_key)
    for column, value in (("t.nam", nam), ("t.quy", quy), ("t.thang", thang)):
        if value is not None:
            clauses.append(f"{column} = ?")
            params.append(value)
    where = ("WHERE " + " AND ".join(clauses)) if clauses else ""
    return query_all(DB_DW, f"""
        SELECT TOP {int(limit)} f.time_key, f.ch_key, v.ten_tp, v.bang, f.mh_key, mh.mo_ta, f.so_luong
        FROM Fact_Kho f JOIN Dim_ThoiGian t ON t.time_key = f.time_key JOIN Dim_CuaHang c ON c.ch_key = f.ch_key JOIN Dim_VPDD v ON v.vp_key = c.vp_key
        JOIN Dim_MatHang mh ON mh.mh_key = f.mh_key {where} ORDER BY f.time_key DESC""", params)


# =====================================================================
# Frontend tĩnh
# =====================================================================
app.mount("/static", StaticFiles(directory=BASE_DIR / "static"), name="static")


@app.get("/")
def root():
    return FileResponse(BASE_DIR / "static/index.html")


@app.get("/bao-cao")
def trang_bao_cao():
    return FileResponse(BASE_DIR / "static/bao_cao.html")
