"""Build parameterized ROLAP queries for the supported display axes and filters."""

TIME_COLS = {"none": [], "nam": ["nam"], "quy": ["nam", "quy"], "thang": ["nam", "quy", "thang"]}
PRODUCT_COLS = {"none": [], "mh": ["mh_key", "mo_ta"]}
CUSTOMER_COLS = {"none": [], "loai_kh": ["loai_kh"], "kh": ["kh_key", "ten", "loai_kh"]}
LOCATION_COLS = {"none": [], "tinh": ["bang"], "tp": ["bang", "ten_tp"], "ch": ["ch_key"]}
DIM_COLS_DS = {**TIME_COLS, **PRODUCT_COLS, **CUSTOMER_COLS}
DIM_COLS_TK = {**TIME_COLS, **PRODUCT_COLS, **LOCATION_COLS}
TIME_LEVELS = ["none", "nam", "quy", "thang"]


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


def aggregate_sql(table, dims, measures, where):
    selection = dims + [f"SUM({measure}) AS {measure}" for measure in measures]
    sql = f"SELECT {', '.join(selection)} FROM {table} {where}"
    if dims:
        sql += f" GROUP BY {', '.join(dims)} ORDER BY {', '.join(dims)}"
    return sql


def sales_query(time_axis="none", mh_axis="none", kh_axis="none", **filters):
    dims = axis_columns(time_axis, TIME_COLS) + axis_columns(mh_axis, PRODUCT_COLS) + axis_columns(kh_axis, CUSTOMER_COLS)
    where, params = filter_clause(filters, {"nam", "quy", "thang", "mh_key", "kh_key", "loai_kh"})
    active = {key for key, value in filters.items() if value is not None and value != ""}
    needed_time = max([TIME_LEVELS.index(time_axis)] + [TIME_LEVELS.index(key) for key in active & {"nam", "quy", "thang"}])
    product = "mh" if mh_axis == "mh" or "mh_key" in active else "none"
    customer = "kh" if kh_axis == "kh" or "kh_key" in active else "loai_kh" if kh_axis == "loai_kh" or "loai_kh" in active else "none"
    levels = [TIME_LEVELS[needed_time], product, customer]
    suffix = "_".join(level for level in levels if level != "none") or "all"
    table = "olap_ds_" + suffix
    sql = aggregate_sql(table, dims, ["tong_so_luong", "tong_doanh_thu"], where)
    return table, dims, sum(level != "none" for level in (time_axis, mh_axis, kh_axis)), sql, params


def inventory_query(dw_database, time_axis="none", mh_axis="none", loc_axis="none", **filters):
    dims = axis_columns(time_axis, TIME_COLS) + axis_columns(mh_axis, PRODUCT_COLS) + axis_columns(loc_axis, LOCATION_COLS)
    where, params = filter_clause(filters, {"nam", "quy", "thang", "mh_key", "bang", "ten_tp", "ch_key"})
    if not params:
        suffix = "_".join(x for x in (time_axis, mh_axis, loc_axis) if x != "none") or "all"
        table = "olap_tk_" + suffix
        sql = "SELECT " + ", ".join(dims + ["tong_ton_kho"]) + " FROM " + table
        if dims:
            sql += " ORDER BY " + ", ".join(dims)
        return table, dims, sum(x != "none" for x in (time_axis, mh_axis, loc_axis)), sql, params
    # Select the last monthly balance per store/product inside the filtered period.
    # Keeping store and product until after ranking prevents sums across snapshots.
    partitions = ["ch_key", "mh_key"] + TIME_COLS[time_axis]
    table = "olap_tk_thang_mh_ch"
    sql = f"""
        WITH enriched AS (
            SELECT b.*, v.bang, v.ten_tp
            FROM {table} b
            JOIN [{dw_database}].dbo.Dim_CuaHang c ON c.ch_key = b.ch_key
            JOIN [{dw_database}].dbo.Dim_VPDD v ON v.vp_key = c.vp_key
        ), filtered AS (
            SELECT * FROM enriched {where}
        ), ranked AS (
            SELECT *, ROW_NUMBER() OVER (
                PARTITION BY {', '.join(partitions)} ORDER BY nam DESC, thang DESC
            ) AS snapshot_rank FROM filtered
        )
        {aggregate_sql('ranked', dims, ['tong_ton_kho'], 'WHERE snapshot_rank = 1')}
    """
    return table, dims, sum(level != "none" for level in (time_axis, mh_axis, loc_axis)), sql, params
