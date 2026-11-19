"""
Web app OLAP Quản Lý Bán Hàng — FastAPI backend.
Chạy: uvicorn main:app --reload --port 8000
"""
import os
from contextlib import contextmanager
from datetime import date
from decimal import Decimal
from pathlib import Path
from cube_queries import sales_query, inventory_query, TOTAL_COLUMN
from cube_schema import HIERARCHIES
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
DB_IDB = os.getenv("DB_IDB", "IDB_TichHop")
CUSTOMER_TYPE = ("CASE WHEN dl.MaKH IS NOT NULL AND bd.MaKH IS NOT NULL THEN N'CaHai' "
                 "WHEN dl.MaKH IS NOT NULL THEN N'DuLich' WHEN bd.MaKH IS NOT NULL THEN N'BuuDien' ELSE N'Khac' END")


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


def decimal_text(value: Decimal) -> str:
    text = format(value, 'f')
    return text.rstrip('0').rstrip('.') if '.' in text else text


def query_all(database: str, sql: str, params: list | None = None) -> list[dict]:
    with get_cursor(database) as cur:
        cur.execute(sql, params or [])
        cols = [c[0] for c in cur.description]
        # JSON numbers are parsed as binary floats in the browser. Keep SQL DECIMAL
        # as a decimal string across the API boundary, including catalogue prices.
        return [dict(zip(cols, (decimal_text(value) if isinstance(value, Decimal) else value
                                for value in row))) for row in cur.fetchall()]


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
# Sales Cube (4 chiều) và Inventory Cube (3 chiều)
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
    rows = query_all(DB_OLAP, sql, params)
    total = len(rows)
    for row in rows:
        total = row.pop(TOTAL_COLUMN, total)
    return {"cuboid": table, "dim_cols": dims, "lattice": lattice, "data": rows,
            "tong_so_dong": total, "bi_cat_bot": total > len(rows)}


MAX_ROWS = 200000
SALES_GROUPS = {"nam": "time", "quy": "time", "thang": "time", "ngay": "time", "mh": "mh",
                "loai_kh": "kh", "kh": "kh", "tinh": "loc", "tp": "loc", "ch": "loc"}
INVENTORY_GROUPS = {key: axis for key, axis in SALES_GROUPS.items() if axis != "kh" and key != "ngay"}


@app.get("/api/doanh-so/v2")
def get_sales_v2(time_axis: str = "none", mh_axis: str = "none", kh_axis: str = "none",
                 loc_axis: str = "none",
                 loc_nam: Optional[int] = None, loc_quy: Optional[int] = None,
                 loc_thang: Optional[int] = None, loc_loai_kh: Optional[str] = None,
                 loc_mh: Optional[str] = None, loc_kh: Optional[str] = None,
                 loc_bang: Optional[str] = None, loc_tp: Optional[str] = None,
                 loc_ch: Optional[str] = None, limit: int = Query(2000, ge=1, le=MAX_ROWS)):
    return cube_response(sales_query, time_axis=time_axis, mh_axis=mh_axis, kh_axis=kh_axis,
                         loc_axis=loc_axis, limit=limit, nam=loc_nam, quy=loc_quy, thang=loc_thang,
                         loai_kh=loc_loai_kh, mh_key=loc_mh, kh_key=loc_kh,
                         bang=loc_bang, ten_tp=loc_tp, ch_key=loc_ch)


@app.get("/api/doanh-so")
def get_doanh_so(nhom: str, loc_nam: Optional[int] = None, loc_quy: Optional[int] = None,
                loc_loai_kh: Optional[str] = None, loc_mh: Optional[str] = None,
                loc_kh: Optional[str] = None, loc_thang: Optional[int] = None,
                loc_bang: Optional[str] = None, loc_tp: Optional[str] = None,
                loc_ch: Optional[str] = None, limit: int = Query(2000, ge=1, le=MAX_ROWS)):
    if nhom not in SALES_GROUPS:
        raise HTTPException(400, "Nhóm doanh số không hợp lệ")
    axes = {"time_axis": "none", "mh_axis": "none", "kh_axis": "none", "loc_axis": "none"}
    axes[SALES_GROUPS[nhom] + "_axis"] = nhom
    return get_sales_v2(**axes, loc_nam=loc_nam, loc_quy=loc_quy, loc_thang=loc_thang,
                        loc_loai_kh=loc_loai_kh, loc_mh=loc_mh, loc_kh=loc_kh,
                        loc_bang=loc_bang, loc_tp=loc_tp, loc_ch=loc_ch, limit=limit)


@app.get("/api/ton-kho/tong")
def get_ton_kho_tong():
    return query_one(DB_OLAP, "SELECT tong_ton_kho FROM olap_tk_all") or {"tong_ton_kho": 0}


@app.get("/api/ton-kho/v2")
def get_inventory_v2(time_axis: str = "none", mh_axis: str = "none", loc_axis: str = "none",
                     loc_nam: Optional[int] = None, loc_quy: Optional[int] = None,
                     loc_thang: Optional[int] = None, loc_bang: Optional[str] = None,
                     loc_mh: Optional[str] = None, loc_ch: Optional[str] = None,
                     loc_tp: Optional[str] = None, limit: int = Query(2000, ge=1, le=MAX_ROWS)):
    return cube_response(inventory_query, time_axis=time_axis, mh_axis=mh_axis, loc_axis=loc_axis,
                         limit=limit, nam=loc_nam, quy=loc_quy, thang=loc_thang, bang=loc_bang,
                         mh_key=loc_mh, ch_key=loc_ch, ten_tp=loc_tp)


@app.get("/api/ton-kho")
def get_ton_kho(nhom: str, loc_nam: Optional[int] = None, loc_quy: Optional[int] = None,
               loc_bang: Optional[str] = None, loc_mh: Optional[str] = None,
               loc_ch: Optional[str] = None, loc_thang: Optional[int] = None,
               loc_tp: Optional[str] = None, limit: int = Query(2000, ge=1, le=MAX_ROWS)):
    if nhom not in INVENTORY_GROUPS:
        raise HTTPException(400, "Nhóm tồn kho không hợp lệ")
    axes = {"time_axis": "none", "mh_axis": "none", "loc_axis": "none"}
    axes[INVENTORY_GROUPS[nhom] + "_axis"] = nhom
    return get_inventory_v2(**axes, loc_nam=loc_nam, loc_quy=loc_quy, loc_thang=loc_thang,
                            loc_bang=loc_bang, loc_mh=loc_mh, loc_ch=loc_ch, loc_tp=loc_tp, limit=limit)


# =====================================================================
# Các thao tác OLAP
# =====================================================================
@app.get("/api/olap/roll-up")
def olap_roll_up(cube: str, tu: str, len_: str = Query(..., alias="len")):
    """Roll-up: đi lên trong cùng một phân cấp (ngày → tháng → quý → năm; cửa hàng → thành phố → bang)."""
    if cube not in ("ds", "tk"):
        raise HTTPException(400, "cube phải là 'ds' hoặc 'tk'")
    hierarchy = next((h for h in (HIERARCHIES["time"], HIERARCHIES["loc"]) if tu in h and len_ in h), None)
    if hierarchy is None or hierarchy.index(tu) <= hierarchy.index(len_) or (cube == "tk" and tu == "ngay"):
        raise HTTPException(400, "Roll-up phải đi từ cấp chi tiết lên cấp tổng hợp hơn trong cùng một phân cấp")
    return get_doanh_so(nhom=len_, limit=2000) if cube == "ds" else get_ton_kho(nhom=len_, limit=2000)


@app.get("/api/olap/drill-down")
def olap_drill_down(cube: str, xuong: str, loc_nam: Optional[int] = None, loc_quy: Optional[int] = None,
                    loc_bang: Optional[str] = None, loc_tp: Optional[str] = None):
    """Drill-down: xuống cấp chi tiết hơn, giữ điều kiện của cấp trên (năm, quý, bang, thành phố)."""
    if cube == "ds":
        return get_doanh_so(nhom=xuong, loc_nam=loc_nam, loc_quy=loc_quy, loc_bang=loc_bang, loc_tp=loc_tp, limit=2000)
    if cube == "tk":
        return get_ton_kho(nhom=xuong, loc_nam=loc_nam, loc_quy=loc_quy, loc_bang=loc_bang, loc_tp=loc_tp, limit=2000)
    raise HTTPException(400, "cube phải là 'ds' hoặc 'tk'")


@app.get("/api/olap/slice")
def olap_slice(cube: str, chieu: str, gia_tri: str):
    """Slice: cố định 1 chiều = 1 giá trị, nhóm theo chiều khác."""
    if chieu == "nam":
        try:
            int(gia_tri)
        except ValueError:
            raise HTTPException(400, "Năm phải là số nguyên")
    if cube == "ds":
        if chieu == "nam":
            return get_doanh_so(nhom="loai_kh", loc_nam=int(gia_tri), limit=2000)
        if chieu == "loai_kh":
            return get_doanh_so(nhom="nam", loc_loai_kh=gia_tri, limit=2000)
        if chieu == "mh":
            return get_doanh_so(nhom="nam", loc_mh=gia_tri, limit=2000)
        if chieu == "bang":
            return get_doanh_so(nhom="nam", loc_bang=gia_tri, limit=2000)
    if cube == "tk":
        if chieu == "nam":
            return get_ton_kho(nhom="tinh", loc_nam=int(gia_tri), limit=2000)
        if chieu == "bang":
            return get_ton_kho(nhom="nam", loc_bang=gia_tri, limit=2000)
        if chieu == "mh":
            return get_ton_kho(nhom="nam", loc_mh=gia_tri, limit=2000)
        if chieu == "loai_kh":
            raise HTTPException(400, "Cube tồn kho không có chiều loại khách hàng")
    raise HTTPException(400, "Tham số slice không hợp lệ")


@app.get("/api/olap/dice")
def olap_dice(cube: str, nhom: str = "nam", loc_nam: Optional[int] = None, loc_quy: Optional[int] = None,
              loc_loai_kh: Optional[str] = None, loc_bang: Optional[str] = None,
              loc_mh: Optional[str] = None, loc_tp: Optional[str] = None):
    if cube == "ds":
        return get_doanh_so(nhom=nhom, loc_nam=loc_nam, loc_quy=loc_quy, loc_loai_kh=loc_loai_kh,
                            loc_mh=loc_mh, loc_bang=loc_bang, loc_tp=loc_tp, limit=2000)
    if cube == "tk":
        if loc_loai_kh:
            raise HTTPException(400, "Cube tồn kho không có chiều loại khách hàng")
        return get_ton_kho(nhom=nhom, loc_nam=loc_nam, loc_quy=loc_quy, loc_bang=loc_bang,
                           loc_mh=loc_mh, loc_tp=loc_tp, limit=2000)
    raise HTTPException(400, "cube phải là 'ds' hoặc 'tk'")


# Pivot dimension -> (axis argument, level, label column)
PIVOT_DIMS = {"nam": ("time_axis", "nam", "nam"), "loai_kh": ("kh_axis", "loai_kh", "loai_kh"),
              "mh": ("mh_axis", "mh", "mh_key"), "bang": ("loc_axis", "tinh", "bang")}


@app.get("/api/olap/pivot")
def olap_pivot(cube: str, hang: str, cot: str):
    """Pivot: ma trận doanh thu hàng × cột; đảo hàng/cột cho ma trận chuyển vị."""
    if cube != "ds":
        raise HTTPException(400, "Pivot hiện chỉ hỗ trợ cube='ds'")
    if hang not in PIVOT_DIMS or cot not in PIVOT_DIMS or hang == cot:
        raise HTTPException(400, f"Cặp hang/cot không hỗ trợ: {hang}/{cot}")
    axes = {PIVOT_DIMS[hang][0]: PIVOT_DIMS[hang][1], PIVOT_DIMS[cot][0]: PIVOT_DIMS[cot][1]}
    rows = cube_response(sales_query, limit=None, **axes)["data"]
    hang_field, cot_field = PIVOT_DIMS[hang][2], PIVOT_DIMS[cot][2]

    def natural_key(value):
        return (0, int(value)) if value.lstrip('-').isdigit() else (1, value)
    labels_hang = sorted({str(r[hang_field]) for r in rows}, key=natural_key)
    labels_cot = sorted({str(r[cot_field]) for r in rows}, key=natural_key)
    idx_h = {v: i for i, v in enumerate(labels_hang)}
    idx_c = {v: i for i, v in enumerate(labels_cot)}
    matrix = [[Decimal(0) for _ in labels_cot] for _ in labels_hang]
    for r in rows:
        value = r["tong_doanh_thu"]
        if value is not None:
            matrix[idx_h[str(r[hang_field])]][idx_c[str(r[cot_field])]] += Decimal(str(value))
    return {"labels_hang": labels_hang, "labels_cot": labels_cot,
            "matrix": [[format(value, 'f') for value in row] for row in matrix]}


@app.get("/api/olap/drill-across")
def olap_drill_across(nhom: str = "nam", vi_tri: str = "none"):
    """Drill-across: ghép doanh số và tồn kho trên các chiều dùng chung (thời gian, vị trí)."""
    if nhom not in ("none", "nam", "quy", "thang"):
        raise HTTPException(400, "nhom phải là none | nam | quy | thang")
    if vi_tri not in ("none", "tinh", "tp", "ch"):
        raise HTTPException(400, "vi_tri phải là none | tinh | tp | ch")
    ds = cube_response(sales_query, time_axis=nhom, loc_axis=vi_tri, limit=None)
    tk = cube_response(inventory_query, time_axis=nhom, loc_axis=vi_tri, limit=None)
    dims = ds["dim_cols"]
    key = lambda r: tuple(r.get(c) for c in dims)
    tk_map = {key(r): r["tong_ton_kho"] for r in tk["data"]}
    out, seen = [], set()
    for r in ds["data"]:
        item = {c: r.get(c) for c in dims}
        revenue = r["tong_doanh_thu"]
        item["tong_doanh_thu"] = None if revenue is None else format(Decimal(str(revenue)), 'f')
        # Missing period != a recorded zero balance. Chart.js keeps null as a gap.
        item["tong_ton_kho"] = tk_map.get(key(r))
        out.append(item)
        seen.add(key(r))
    for r in tk["data"]:
        if key(r) not in seen:
            out.append({**{c: r.get(c) for c in dims}, "tong_doanh_thu": None, "tong_ton_kho": r["tong_ton_kho"]})
    return out


def int_or_none(value: Optional[str]):
    """Business keys are integers in IDB; a non-numeric key matches nothing."""
    if value is None or value == "":
        return None
    try:
        return int(value)
    except ValueError:
        return -1


@app.get("/api/olap/drill-through")
def olap_drill_through(
    kh_key: Optional[str] = None,
    mh_key: Optional[str] = None,
    ch_key: Optional[str] = None,
    nam: Optional[int] = None,
    limit: int = Query(200, ge=1, le=2000),
    quy: Optional[int] = None,
    thang: Optional[int] = None,
    ngay: Optional[date] = None,
    loai_kh: Optional[str] = None,
    bang: Optional[str] = None,
    ten_tp: Optional[str] = None,
):
    """Drill-through: từ một ô tổng hợp xuống từng lần cấp hàng của dòng đơn gốc trong IDB."""
    clauses, params = [], []
    for column, value in (("o.MaKH", int_or_none(kh_key)), ("p.MaMH", int_or_none(mh_key)),
                          ("p.MaCuaHang", int_or_none(ch_key)), ("YEAR(o.NgayDatHang)", nam),
                          ("DATEPART(QUARTER, o.NgayDatHang)", quy), ("MONTH(o.NgayDatHang)", thang),
                          ("o.NgayDatHang", ngay), ("v.Bang", bang), ("v.TenThanhPho", ten_tp)):
        if value is not None and value != "":
            clauses.append(f"{column} = ?")
            params.append(value)
    if loai_kh:
        clauses.append(f"{CUSTOMER_TYPE} = ?")
        params.append(loai_kh)
    where = ("WHERE " + " AND ".join(clauses)) if clauses else ""
    sql = f"""
        SELECT TOP {int(limit)}
            CAST(o.MaDon AS NVARCHAR(20)) AS ma_don, o.NgayDatHang AS ngay,
            YEAR(o.NgayDatHang) AS nam, DATEPART(QUARTER, o.NgayDatHang) AS quy, MONTH(o.NgayDatHang) AS thang,
            k.TenKH AS ten_kh, {CUSTOMER_TYPE} AS loai_kh, m.MoTa AS mo_ta_mh,
            CAST(p.MaCuaHang AS NVARCHAR(20)) AS ch_key, v.TenThanhPho AS ten_tp, v.Bang AS bang,
            p.SoLuongCap AS so_luong, p.SoLuongCap * d.GiaDat AS tong_tien
        FROM dbo.PhanBoDonHang p
        JOIN dbo.MatHangDuocDat d ON d.MaDon = p.MaDon AND d.MaMH = p.MaMH
        JOIN dbo.DonDatHang o ON o.MaDon = p.MaDon
        JOIN dbo.KhachHang k ON k.MaKH = o.MaKH
        LEFT JOIN dbo.KhachHangDuLich dl ON dl.MaKH = k.MaKH
        LEFT JOIN dbo.KhachHangBuuDien bd ON bd.MaKH = k.MaKH
        JOIN dbo.MatHang m ON m.MaMH = p.MaMH
        JOIN dbo.CuaHang c ON c.MaCuaHang = p.MaCuaHang
        JOIN dbo.VanPhongDaiDien v ON v.MaThanhPho = c.MaThanhPho
        {where}
        ORDER BY o.NgayDatHang DESC, o.MaDon, p.MaMH, p.MaCuaHang
    """
    return query_all(DB_IDB, sql, params)


# =====================================================================
# 9 báo cáo OLAP theo đề bài (truy vấn galaxy schema DW_Core)
# =====================================================================
def latest_kho(den_thang: Optional[int]) -> tuple[str, list]:
    """Snapshot tồn kho mới nhất của mỗi (cửa hàng, mặt hàng), tính đến tháng den_thang (YYYYMM) nếu có.

    Tồn kho là semi-additive nên báo cáo theo thời gian lấy số dư cuối kỳ, không cộng các tháng.
    """
    if den_thang is None:
        return "k.time_key = (SELECT MAX(k2.time_key) FROM Fact_Kho k2 WHERE k2.ch_key = k.ch_key AND k2.mh_key = k.mh_key)", []
    if not (190001 <= den_thang <= 999912 and 1 <= den_thang % 100 <= 12):
        raise HTTPException(400, "den_thang phải có dạng YYYYMM, ví dụ 202206")
    return ("k.time_key = (SELECT MAX(k2.time_key) FROM Fact_Kho k2 WHERE k2.ch_key = k.ch_key "
            "AND k2.mh_key = k.mh_key AND k2.time_key <= ?)"), [den_thang]


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
def bc2(kh: str, tu_ngay: Optional[date] = None, den_ngay: Optional[date] = None):
    """YC2: các đơn đặt hàng với tên KH và ngày đặt của khách đó (có thể giới hạn khoảng ngày)."""
    if tu_ngay and den_ngay and tu_ngay > den_ngay:
        raise HTTPException(400, "tu_ngay phải trước hoặc bằng den_ngay")
    # Mã đơn là thông tin giao dịch, không phải chiều phân tích: fact lưu ở khóa ngày-khách-mặt hàng-cửa hàng,
    # nên báo cáo theo từng đơn đọc tầng IDB tích hợp (cùng nguồn mà ETL dùng để nạp kho).
    clauses, params = ["o.MaKH = ?"], [int_or_none(kh)]
    if tu_ngay:
        clauses.append("o.NgayDatHang >= ?"); params.append(tu_ngay)
    if den_ngay:
        clauses.append("o.NgayDatHang <= ?"); params.append(den_ngay)
    return query_all(DB_IDB, f"""
        SELECT CAST(o.MaDon AS NVARCHAR(20)) AS ma_don, CAST(k.MaKH AS NVARCHAR(20)) AS kh_key,
               k.TenKH AS ten, o.NgayDatHang AS ngay
        FROM dbo.DonDatHang o JOIN dbo.KhachHang k ON k.MaKH = o.MaKH
        WHERE {' AND '.join(clauses)} ORDER BY o.NgayDatHang, o.MaDon""", params)


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
def bc4(mh: str, muc: int = 100, den_thang: Optional[int] = None):
    """YC4: địa chỉ VPĐD, TP, bang của các cửa hàng lưu kho một mặt hàng với số lượng > mức (tại tháng den_thang)."""
    snapshot, snapshot_params = latest_kho(den_thang)
    return query_all(DB_DW, f"""
        SELECT DISTINCT ch.ch_key, v.dia_chi_vp, v.ten_tp, v.bang, k.so_luong
        FROM Fact_Kho k JOIN Dim_CuaHang ch ON ch.ch_key = k.ch_key JOIN Dim_VPDD v ON v.vp_key = ch.vp_key
        WHERE k.mh_key = ? AND k.so_luong > ? AND {snapshot}
        ORDER BY k.so_luong DESC""", [mh, muc] + snapshot_params)


@app.get("/api/bao-cao/5")
def bc5(ma_don: str):
    """YC5: với mỗi đơn, mặt hàng đặt + mô tả, cửa hàng đáp ứng, TP và các cửa hàng có bán mặt hàng đó.

    Mỗi dòng = một (dòng đơn, cửa hàng cấp hàng). Danh sách cửa hàng có bán được gộp vào một cột
    để không nhân bản số lượng cấp theo số cửa hàng có bán.
    """
    return query_all(DB_IDB, """
        SELECT CAST(d.MaDon AS NVARCHAR(20)) AS ma_don, CAST(d.MaMH AS NVARCHAR(20)) AS mh_key, m.MoTa AS mo_ta,
               d.SoLuongDat AS so_luong, CAST(p.MaCuaHang AS NVARCHAR(20)) AS ch_dap_ung, p.SoLuongCap AS so_luong_cap,
               v.TenThanhPho AS tp_dap_ung, cb.cac_ch_co_ban
        FROM dbo.MatHangDuocDat d JOIN dbo.MatHang m ON m.MaMH = d.MaMH
        JOIN dbo.PhanBoDonHang p ON p.MaDon = d.MaDon AND p.MaMH = d.MaMH
        JOIN dbo.CuaHang c ON c.MaCuaHang = p.MaCuaHang JOIN dbo.VanPhongDaiDien v ON v.MaThanhPho = c.MaThanhPho
        OUTER APPLY (
            SELECT STRING_AGG(CONCAT(CAST(l.MaCuaHang AS NVARCHAR(20)), N' (', v2.TenThanhPho, N')'), N', ')
                   WITHIN GROUP (ORDER BY l.MaCuaHang) AS cac_ch_co_ban
            FROM dbo.MatHangLuuTru l JOIN dbo.CuaHang c2 ON c2.MaCuaHang = l.MaCuaHang
            JOIN dbo.VanPhongDaiDien v2 ON v2.MaThanhPho = c2.MaThanhPho
            WHERE l.MaMH = d.MaMH
        ) cb
        WHERE d.MaDon = ? ORDER BY d.MaMH, p.MaCuaHang""", [int_or_none(ma_don)])


@app.get("/api/bao-cao/6")
def bc6(kh: str):
    """YC6: thành phố và bang nơi một KH sinh sống."""
    return query_all(DB_DW, """
        SELECT kh.kh_key, kh.ten, v.ten_tp, v.bang
        FROM Dim_KhachHang kh JOIN Dim_VPDD v ON v.vp_key = kh.vp_key WHERE kh.kh_key = ?""", [kh])


@app.get("/api/bao-cao/7")
def bc7(mh: str, tp: str, den_thang: Optional[int] = None):
    """YC7: mức tồn kho một mặt hàng tại tất cả cửa hàng của một thành phố (snapshot mới nhất hoặc tại tháng den_thang)."""
    snapshot, snapshot_params = latest_kho(den_thang)
    return query_all(DB_DW, f"""
        SELECT ch.ch_key, v.ten_tp, k.mh_key, k.so_luong AS ton_kho
        FROM Fact_Kho k JOIN Dim_CuaHang ch ON ch.ch_key = k.ch_key JOIN Dim_VPDD v ON v.vp_key = ch.vp_key
        WHERE k.mh_key = ? AND ch.vp_key = ? AND {snapshot}
        ORDER BY TRY_CONVERT(BIGINT,ch.ch_key), ch.ch_key""", [mh, tp] + snapshot_params)


@app.get("/api/bao-cao/8")
def bc8(ma_don: str):
    """YC8: mặt hàng, số lượng đặt, khách hàng, cửa hàng và thành phố của một đơn."""
    return query_all(DB_IDB, """
        SELECT CAST(d.MaDon AS NVARCHAR(20)) AS ma_don, CAST(d.MaMH AS NVARCHAR(20)) AS mh_key, m.MoTa AS mo_ta,
               d.SoLuongDat AS so_luong, d.GiaDat AS gia_dat, k.TenKH AS khach_hang,
               CAST(p.MaCuaHang AS NVARCHAR(20)) AS ch_key, p.SoLuongCap AS so_luong_cap, v.TenThanhPho AS ten_tp
        FROM dbo.MatHangDuocDat d JOIN dbo.DonDatHang o ON o.MaDon = d.MaDon
        JOIN dbo.MatHang m ON m.MaMH = d.MaMH JOIN dbo.KhachHang k ON k.MaKH = o.MaKH
        JOIN dbo.PhanBoDonHang p ON p.MaDon = d.MaDon AND p.MaMH = d.MaMH
        JOIN dbo.CuaHang c ON c.MaCuaHang = p.MaCuaHang JOIN dbo.VanPhongDaiDien v ON v.MaThanhPho = c.MaThanhPho
        WHERE d.MaDon = ? ORDER BY d.MaMH, p.MaCuaHang""", [int_or_none(ma_don)])


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
        # Hơn 50.000 đơn: trả khoảng mã để giao diện dùng ô nhập số thay vì danh sách chọn.
        "don_hang": query_one(DB_IDB, "SELECT MIN(MaDon) AS min, MAX(MaDon) AS max, COUNT(*) AS so_don FROM dbo.DonDatHang"),
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
