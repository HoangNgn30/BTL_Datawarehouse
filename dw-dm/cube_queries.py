"""Build parameterized ROLAP queries for the supported display axes and filters.

Each query reads the smallest materialized cuboid that still contains every displayed axis
and every filtered column, then groups to the displayed axes.
"""
from cube_schema import (TIME_COLS, PRODUCT_COLS, CUSTOMER_COLS, LOCATION_COLS,
                         SALES_AXES, INVENTORY_AXES, cuboid_name)

DIM_COLS_DS = {**TIME_COLS, **PRODUCT_COLS, **CUSTOMER_COLS, **LOCATION_COLS}
DIM_COLS_TK = {**TIME_COLS, **PRODUCT_COLS, **LOCATION_COLS}
TOTAL_COLUMN = "_tong_dong"

# Filter column -> (axis, minimal level that contains it)
FILTER_LEVEL = {"nam": ("time", "nam"), "quy": ("time", "quy"), "thang": ("time", "thang"),
                "ngay": ("time", "ngay"), "mh_key": ("mh", "mh"), "loai_kh": ("kh", "loai_kh"),
                "kh_key": ("kh", "kh"), "bang": ("loc", "tinh"), "ten_tp": ("loc", "tp"),
                "ch_key": ("loc", "ch")}


def axis_columns(value, allowed):
    if value not in allowed:
        raise ValueError(f"Chiều không hợp lệ: {value}")
    return allowed[value]


def filter_clause(filters, allowed):
    selected = [(key, value) for key, value in filters.items() if value is not None and value != ""]
    if any(key not in allowed for key, _ in selected):
        raise ValueError("Bộ lọc không thuộc khối dữ liệu")
    values = dict(selected)
    for field, maximum in (("quy", 4), ("thang", 12)):
        if field in values and not 1 <= values[field] <= maximum:
            raise ValueError(f"{field} phải nằm trong 1..{maximum}")
    if "quy" in values and "thang" in values and (values["thang"] - 1) // 3 + 1 != values["quy"]:
        raise ValueError("Tháng không thuộc quý đã chọn")
    clauses = [f"{key} = ?" for key, _ in selected]
    return ("WHERE " + " AND ".join(clauses) if clauses else ""), [value for _, value in selected]


def aggregate_sql(table, dims, measures, where, limit=None):
    selection = dims + [f"SUM({measure}) AS {measure}" for measure in measures]
    if not dims:
        return f"SELECT {', '.join(selection)} FROM {table} {where}", []
    # COUNT(*) OVER() counts grouped rows before paging, so the API can report truncation.
    sql = (f"SELECT {', '.join(selection)}, COUNT(*) OVER() AS {TOTAL_COLUMN} FROM {table} {where} "
           f"GROUP BY {', '.join(dims)} ORDER BY {', '.join(dims)}")
    if limit is None:
        return sql, []
    return sql + " OFFSET 0 ROWS FETCH NEXT ? ROWS ONLY", [int(limit)]


def required_levels(axes, chosen, active):
    """Finest level per axis needed by the displayed axis and the filters."""
    levels = []
    for name, _, order in axes:
        needed = [chosen[name]] + [FILTER_LEVEL[key][1] for key in active if FILTER_LEVEL[key][0] == name]
        if any(level not in order for level in needed):
            raise ValueError(f"Chiều không hợp lệ: {chosen[name]}")
        levels.append(max(needed, key=order.index))
    return levels


def sales_query(time_axis="none", mh_axis="none", kh_axis="none", loc_axis="none", limit=None, **filters):
    chosen = {"time": time_axis, "mh": mh_axis, "kh": kh_axis, "loc": loc_axis}
    dims = (axis_columns(time_axis, TIME_COLS) + axis_columns(mh_axis, PRODUCT_COLS)
            + axis_columns(kh_axis, CUSTOMER_COLS) + axis_columns(loc_axis, LOCATION_COLS))
    where, params = filter_clause(filters, {"nam", "quy", "thang", "mh_key", "kh_key", "loai_kh",
                                            "bang", "ten_tp", "ch_key"})
    active = {key for key, value in filters.items() if value is not None and value != ""}
    table = cuboid_name("ds", required_levels(SALES_AXES, chosen, active))
    sql, extra = aggregate_sql(table, dims, ["tong_so_luong", "tong_doanh_thu"], where, limit)
    return table, dims, sum(level != "none" for level in chosen.values()), sql, params + extra


def inventory_query(time_axis="none", mh_axis="none", loc_axis="none", limit=None, **filters):
    chosen = {"time": time_axis, "mh": mh_axis, "loc": loc_axis}
    if time_axis == "ngay":
        raise ValueError("Tồn kho chỉ có snapshot theo tháng, không có cấp ngày")
    dims = axis_columns(time_axis, TIME_COLS) + axis_columns(mh_axis, PRODUCT_COLS) + axis_columns(loc_axis, LOCATION_COLS)
    where, params = filter_clause(filters, {"nam", "quy", "thang", "mh_key", "bang", "ten_tp", "ch_key"})
    lattice = sum(level != "none" for level in chosen.values())
    if not params:
        table = cuboid_name("tk", [time_axis, mh_axis, loc_axis])
        sql, extra = aggregate_sql(table, dims, ["tong_ton_kho"], "", limit)
        return table, dims, lattice, sql, extra
    # Semi-additive: select the last monthly balance per store/product inside the filtered
    # period on the finest cuboid, then add across stores/products. Never add months together.
    partitions = ["ch_key", "mh_key"] + TIME_COLS[time_axis]
    table = "olap_tk_thang_mh_ch"
    ranked = f"""(
            SELECT *, ROW_NUMBER() OVER (PARTITION BY {', '.join(partitions)} ORDER BY nam DESC, thang DESC) AS snapshot_rank
            FROM {table} {where}
        ) ranked"""
    sql, extra = aggregate_sql(ranked, dims, ["tong_ton_kho"], "WHERE snapshot_rank = 1", limit)
    return table, dims, lattice, sql, params + extra
