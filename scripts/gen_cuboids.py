"""Generate dw-dm/create_cuboids_vi.sql: one materialized table per cuboid of both cubes.

The lattice comes from dw-dm/cube_schema.py, so the SQL, the API and the validator share
one definition of dimensions and hierarchy levels. Run: python scripts/gen_cuboids.py
"""
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "dw-dm"))
from cube_schema import all_cuboids, cuboid_columns, cuboid_count, cuboid_name  # noqa: E402

OUTPUT = ROOT / "dw-dm" / "create_cuboids_vi.sql"
HINT = "OPTION (MAXDOP 1, MAX_GRANT_PERCENT = 0)"
EXPRESSION = {
    "nam": "t.nam", "quy": "t.quy", "thang": "t.thang", "ngay": "n.ngay",
    "mh_key": "f.mh_key", "mo_ta": "mh.mo_ta",
    "kh_key": "f.kh_key", "ten": "kh.ten", "loai_kh": "kh.loai_kh",
    "bang": "v.bang", "ten_tp": "v.ten_tp", "ch_key": "f.ch_key",
}


def joins(cube, columns):
    need = {EXPRESSION[c].split(".")[0] for c in columns}
    out = []
    if cube == "ds":
        if need & {"n", "t"}:
            out.append("JOIN DW_Core.dbo.Dim_Ngay n ON n.ngay_key = f.ngay_key")
        if "t" in need:
            out.append("JOIN DW_Core.dbo.Dim_ThoiGian t ON t.time_key = n.time_key")
        if "kh" in need:
            out.append("JOIN DW_Core.dbo.Dim_KhachHang kh ON kh.kh_key = f.kh_key")
    elif "t" in need:
        out.append("JOIN DW_Core.dbo.Dim_ThoiGian t ON t.time_key = f.time_key")
    if "mh" in need:
        out.append("JOIN DW_Core.dbo.Dim_MatHang mh ON mh.mh_key = f.mh_key")
    if "v" in need:
        out.append("JOIN DW_Core.dbo.Dim_CuaHang ch ON ch.ch_key = f.ch_key")
        out.append("JOIN DW_Core.dbo.Dim_VPDD v ON v.vp_key = ch.vp_key")
    return out


def sales_sql(name, columns):
    select = [f"{EXPRESSION[c]} AS {c}" for c in columns]
    select += ["SUM(f.so_luong) AS tong_so_luong", "SUM(f.doanh_thu) AS tong_doanh_thu"]
    lines = ["SELECT " + ",\n       ".join(select), f"INTO dbo.[{name}]", "FROM DW_Core.dbo.Fact_BanHang f"]
    lines += joins("ds", columns)
    if columns:
        lines.append("GROUP BY " + ", ".join(EXPRESSION[c] for c in columns))
    return "\n".join(lines) + f"\n{HINT};"


def inventory_sql(name, columns, time_columns):
    # Semi-additive: keep the last monthly snapshot per store/product inside each period,
    # then add across stores/products. Never add snapshots of different months.
    partition = ", ".join(["f.ch_key", "f.mh_key"] + [EXPRESSION[c] for c in time_columns])
    inner = [f"{EXPRESSION[c]} AS {c}" for c in columns] + ["f.so_luong",
             f"ROW_NUMBER() OVER (PARTITION BY {partition} ORDER BY f.time_key DESC) AS rn"]
    body = ["WITH ranked AS (", "    SELECT " + ",\n           ".join(inner), "    FROM DW_Core.dbo.Fact_Kho f"]
    body += ["    " + j for j in joins("tk", columns + time_columns)]
    body.append(")")
    body.append("SELECT " + ", ".join(columns + ["SUM(so_luong) AS tong_ton_kho"]))
    body += [f"INTO dbo.[{name}]", "FROM ranked WHERE rn = 1"]
    if columns:
        body.append("GROUP BY " + ", ".join(columns))
    return "\n".join(body) + f"\n{HINT};"


def build():
    parts = [
        "-- ============================================================",
        "-- FILE SINH TU DONG boi scripts/gen_cuboids.py. KHONG SUA TAY.",
        f"-- Sales cube    : {cuboid_count('ds')} cuboid (olap_ds_*), Thoi gian(5) x Mat hang(2) x Khach hang(3) x Vi tri(4)",
        f"-- Inventory cube: {cuboid_count('tk')} cuboid (olap_tk_*), Thoi gian(4) x Mat hang(2) x Vi tri(4)",
        "-- Measures: tong_so_luong, tong_doanh_thu (cong duoc); tong_ton_kho (snapshot cuoi ky)",
        "-- ============================================================",
        "USE OLAP_QuanLyBanHang;", "GO", "SET NOCOUNT ON;", "GO",
    ]
    number = 0
    for cube in ("ds", "tk"):
        for levels in all_cuboids(cube):
            number += 1
            name = cuboid_name(cube, levels)
            columns = cuboid_columns(cube, levels)
            dims = sum(level != "none" for level in levels)
            parts.append(f"\n-- [{number}] {name} ({dims}D)")
            if cube == "ds":
                parts.append(sales_sql(name, columns))
            else:
                parts.append(inventory_sql(name, columns, [c for c in columns if c in ("nam", "quy", "thang")]))
            parts.append("GO")
    return "\n".join(parts) + "\n", number


if __name__ == "__main__":
    text, count = build()
    OUTPUT.write_text(text, encoding="utf-8", newline="\n")
    print(f"Wrote {OUTPUT.relative_to(ROOT)}: {count} cuboids")
