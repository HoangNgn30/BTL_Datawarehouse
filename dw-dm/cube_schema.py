"""Single definition of the two cubes: dimensions, hierarchy levels and cuboid names.

Number of cuboids of a cube = product over its dimensions of (number of levels + 1 for ALL).
  Sales     : Time(5) x Product(2) x Customer(3) x Location(4) = 120
  Inventory : Time(4) x Product(2) x Location(4)               =  32
"""
from itertools import product

# Columns kept for each level (coarser keys are kept so every row is unambiguous).
TIME_COLS = {"none": [], "nam": ["nam"], "quy": ["nam", "quy"], "thang": ["nam", "quy", "thang"],
             "ngay": ["nam", "quy", "thang", "ngay"]}
PRODUCT_COLS = {"none": [], "mh": ["mh_key", "mo_ta"]}
CUSTOMER_COLS = {"none": [], "loai_kh": ["loai_kh"], "kh": ["kh_key", "ten", "loai_kh"]}
LOCATION_COLS = {"none": [], "tinh": ["bang"], "tp": ["bang", "ten_tp"], "ch": ["bang", "ten_tp", "ch_key"]}

# (axis name, column map, levels from ALL to the finest level)
SALES_AXES = [("time", TIME_COLS, ["none", "nam", "quy", "thang", "ngay"]),
              ("mh", PRODUCT_COLS, ["none", "mh"]),
              ("kh", CUSTOMER_COLS, ["none", "loai_kh", "kh"]),
              ("loc", LOCATION_COLS, ["none", "tinh", "tp", "ch"])]
# Inventory snapshots are monthly, so month is the finest time level.
INVENTORY_AXES = [("time", TIME_COLS, ["none", "nam", "quy", "thang"]),
                  ("mh", PRODUCT_COLS, ["none", "mh"]),
                  ("loc", LOCATION_COLS, ["none", "tinh", "tp", "ch"])]
CUBES = {"ds": SALES_AXES, "tk": INVENTORY_AXES}
MEASURES = {"ds": ["tong_so_luong", "tong_doanh_thu"], "tk": ["tong_ton_kho"]}

# Hierarchies used by roll-up / drill-down (coarse -> fine).
HIERARCHIES = {"time": ["nam", "quy", "thang", "ngay"], "loc": ["tinh", "tp", "ch"],
               "kh": ["loai_kh", "kh"], "mh": ["mh"]}
KEY_COLUMNS = {"nam", "quy", "thang", "ngay", "mh_key", "kh_key", "loai_kh", "bang", "ten_tp", "ch_key"}


def cuboid_name(cube, levels):
    return f"olap_{cube}_" + ("_".join(level for level in levels if level != "none") or "all")


def cuboid_columns(cube, levels):
    columns = []
    for (_, mapping, _), level in zip(CUBES[cube], levels):
        columns += mapping[level]
    return columns


def all_cuboids(cube):
    """Yield the level tuple of every cuboid of a cube (the full lattice)."""
    yield from product(*(levels for _, _, levels in CUBES[cube]))


def cuboid_count(cube):
    count = 1
    for _, _, levels in CUBES[cube]:
        count *= len(levels)
    return count
