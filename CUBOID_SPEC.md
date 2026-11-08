# CUBOID STRUCTURE SPEC - OLAP API v2.0

## SALES CUBE (3D: Time × Product × Customer)
**Dimensions:** Time (year → quarter → month), Product, Customer Type
**Measures:** total_quantity (số lượng), sum_amount (doanh thu)

---

### SALES: 0-D (Apex) - 1 cuboid
**Purpose:** Tổng toàn hệ thống (không phân theo chiều nào)
**Endpoint:** `GET /api/sales/apex`
**Cuboid Table:** `olap_s_all`
**Fields Returned:**
```
{
  "total_quantity": <int>,      # Tổng số lượng bán
  "sum_amount": <float>         # Tổng doanh thu
}
```

---

### SALES: 1-D - 6 cuboids (phân theo từng chiều riêng)

#### 1D-1: Time (Drill-down hierarchy)
**Endpoints:**
- `GET /api/sales/time/year` → `olap_s_year`
  ```
  {
    "year": <int>,
    "total_quantity": <int>,
    "sum_amount": <float>
  }
  ```
  
- `GET /api/sales/time/quarter?year=2023` → `olap_s_quarter`
  ```
  {
    "year": <int>,
    "quarter": <int>,
    "total_quantity": <int>,
    "sum_amount": <float>
  }
  ```
  
- `GET /api/sales/time/month?year=2023` → `olap_s_month`
  ```
  {
    "year": <int>,
    "quarter": <int>,
    "month": <int>,
    "total_quantity": <int>,
    "sum_amount": <float>
  }
  ```

#### 1D-2: Product (Slice by product)
**Endpoint:** `GET /api/sales/product` → `olap_s_product`
**Fields:**
```
{
  "product_key": <int>,
  "description": <string>,
  "total_quantity": <int>,
  "sum_amount": <float>
}
```

#### 1D-3: Customer Type (Slice by customer)
**Endpoint:** `GET /api/sales/customer-type` → `olap_s_custtype`
**Fields:**
```
{
  "customer_type": <string>,
  "total_quantity": <int>,
  "sum_amount": <float>
}
```

---

### SALES: 2-D - 9 cuboids (kết hợp 2 chiều)

#### 2D-1: Time × Product
**Endpoints:**
- `GET /api/sales/time-product/year-product` → `olap_s_year_product`
  ```
  {
    "year": <int>,
    "product_key": <int>,
    "description": <string>,
    "total_quantity": <int>,
    "sum_amount": <float>
  }
  ```
  
- `GET /api/sales/time-product/quarter-product?year=2023` → `olap_s_quarter_product`
  ```
  {
    "year": <int>,
    "quarter": <int>,
    "product_key": <int>,
    "description": <string>,
    "total_quantity": <int>,
    "sum_amount": <float>
  }
  ```
  
- `GET /api/sales/time-product/month-product?year=2023` → `olap_s_month_product`
  ```
  {
    "year": <int>,
    "quarter": <int>,
    "month": <int>,
    "product_key": <int>,
    "description": <string>,
    "total_quantity": <int>,
    "sum_amount": <float>
  }
  ```

#### 2D-2: Time × Customer
**Endpoints:**
- `GET /api/sales/time-customer/year-custtype` → `olap_s_year_custtype`
  ```
  {
    "year": <int>,
    "customer_type": <string>,
    "total_quantity": <int>,
    "sum_amount": <float>
  }
  ```
  
- `GET /api/sales/time-customer/quarter-custtype?year=2023` → `olap_s_quarter_custtype`
  ```
  {
    "year": <int>,
    "quarter": <int>,
    "customer_type": <string>,
    "total_quantity": <int>,
    "sum_amount": <float>
  }
  ```
  
- `GET /api/sales/time-customer/month-custtype?year=2023` → `olap_s_month_custtype` ✓ (Đã có)
  ```
  {
    "year": <int>,
    "quarter": <int>,
    "month": <int>,
    "customer_type": <string>,
    "total_quantity": <int>,
    "sum_amount": <float>
  }
  ```

#### 2D-3: Product × Customer
**Endpoint:** `GET /api/sales/product-customer` → `olap_s_product_custtype`
**Fields:**
```
{
  "product_key": <int>,
  "description": <string>,
  "customer_type": <string>,
  "total_quantity": <int>,
  "sum_amount": <float>
}
```

**Với filter year:**
- `GET /api/sales/product-customer?year=2023` → `olap_s_year_product_custtype` ✓ (Đã có)

---

### SALES: 3-D - 8 cuboids (chi tiết nhất: Time × Product × Customer)

#### 3D-1: Year × Product × Customer
**Endpoint:** `GET /api/sales/3d/year-product-customer?year=2023`
**Cuboid:** `olap_s_year_product_custtype` ✓ (Có)
**Fields:**
```
{
  "year": <int>,
  "product_key": <int>,
  "description": <string>,
  "customer_type": <string>,
  "total_quantity": <int>,
  "sum_amount": <float>
}
```

#### 3D-2: Quarter × Product × Customer
**Endpoint:** `GET /api/sales/3d/quarter-product-customer?year=2023&quarter=1`
**Cuboid:** `olap_s_quarter_product_custtype`
**Fields:**
```
{
  "year": <int>,
  "quarter": <int>,
  "product_key": <int>,
  "description": <string>,
  "customer_type": <string>,
  "total_quantity": <int>,
  "sum_amount": <float>
}
```

#### 3D-3: Month × Product × Customer
**Endpoint:** `GET /api/sales/3d/month-product-customer?year=2023&month=1`
**Cuboid:** `olap_s_month_product_custtype`
**Fields:**
```
{
  "year": <int>,
  "quarter": <int>,
  "month": <int>,
  "product_key": <int>,
  "description": <string>,
  "customer_type": <string>,
  "total_quantity": <int>,
  "sum_amount": <float>
}
```

---

## INVENTORY CUBE (3D: Time × Product × Store)
**Dimensions:** Time (year → quarter → month), Product, Store
**Measures:** total_quantity_on_hand (số lượng hàng tồn)

---

### INVENTORY: 0-D (Apex) - 1 cuboid
**Purpose:** Tổng toàn hệ thống
**Endpoint:** `GET /api/inventory/apex`
**Cuboid Table:** `olap_i_all`
**Fields Returned:**
```
{
  "total_quantity_on_hand": <int>   # Tổng hàng tồn kho
}
```

---

### INVENTORY: 1-D - 6 cuboids

#### 1D-1: Time (Drill-down hierarchy)
**Endpoints:**
- `GET /api/inventory/time/year` → `olap_i_year`
  ```
  {
    "year": <int>,
    "total_quantity_on_hand": <int>
  }
  ```
  
- `GET /api/inventory/time/quarter?year=2023` → `olap_i_quarter` ✓ (Đã có)
  ```
  {
    "year": <int>,
    "quarter": <int>,
    "total_quantity_on_hand": <int>
  }
  ```
  
- `GET /api/inventory/time/month?year=2023` → `olap_i_month` ✓ (Đã có)
  ```
  {
    "year": <int>,
    "quarter": <int>,
    "month": <int>,
    "total_quantity_on_hand": <int>
  }
  ```

#### 1D-2: Product (Slice by product)
**Endpoint:** `GET /api/inventory/product` → `olap_i_product`
**Fields:**
```
{
  "product_key": <int>,
  "total_quantity_on_hand": <int>
}
```

#### 1D-3: Store (Slice by store)
**Endpoint:** `GET /api/inventory/store` → `olap_i_store` ✓ (Đã có)
**Fields:**
```
{
  "store_key": <int>,
  "total_quantity_on_hand": <int>
}
```

---

### INVENTORY: 2-D - 9 cuboids

#### 2D-1: Time × Product
**Endpoints:**
- `GET /api/inventory/time-product/year-product` → `olap_i_year_product`
  ```
  {
    "year": <int>,
    "product_key": <int>,
    "total_quantity_on_hand": <int>
  }
  ```
  
- `GET /api/inventory/time-product/quarter-product?year=2023` → `olap_i_quarter_product`
  ```
  {
    "year": <int>,
    "quarter": <int>,
    "product_key": <int>,
    "total_quantity_on_hand": <int>
  }
  ```
  
- `GET /api/inventory/time-product/month-product?year=2023` → `olap_i_month_product`
  ```
  {
    "year": <int>,
    "quarter": <int>,
    "month": <int>,
    "product_key": <int>,
    "total_quantity_on_hand": <int>
  }
  ```

#### 2D-2: Time × Store
**Endpoints:**
- `GET /api/inventory/time-store/year-store` → `olap_i_year_store`
  ```
  {
    "year": <int>,
    "store_key": <int>,
    "total_quantity_on_hand": <int>
  }
  ```
  
- `GET /api/inventory/time-store/quarter-store?year=2023` → `olap_i_quarter_store`
  ```
  {
    "year": <int>,
    "quarter": <int>,
    "store_key": <int>,
    "total_quantity_on_hand": <int>
  }
  ```
  
- `GET /api/inventory/time-store/month-store?year=2023` → `olap_i_month_store`
  ```
  {
    "year": <int>,
    "quarter": <int>,
    "month": <int>,
    "store_key": <int>,
    "total_quantity_on_hand": <int>
  }
  ```

#### 2D-3: Product × Store
**Endpoint:** `GET /api/inventory/product-store` → `olap_i_product_store`
**Fields:**
```
{
  "product_key": <int>,
  "store_key": <int>,
  "total_quantity_on_hand": <int>
}
```

---

### INVENTORY: 3-D - 8 cuboids (chi tiết nhất: Time × Product × Store)

#### 3D-1: Year × Product × Store
**Endpoint:** `GET /api/inventory/3d/year-product-store?year=2023`
**Cuboid:** `olap_i_year_product_store`
**Fields:**
```
{
  "year": <int>,
  "product_key": <int>,
  "store_key": <int>,
  "total_quantity_on_hand": <int>
}
```

#### 3D-2: Quarter × Product × Store
**Endpoint:** `GET /api/inventory/3d/quarter-product-store?year=2023&quarter=1`
**Cuboid:** `olap_i_quarter_product_store`
**Fields:**
```
{
  "year": <int>,
  "quarter": <int>,
  "product_key": <int>,
  "store_key": <int>,
  "total_quantity_on_hand": <int>
}
```

#### 3D-3: Month × Product × Store
**Endpoint:** `GET /api/inventory/3d/month-product-store?year=2023&month=1`
**Cuboid:** `olap_i_month_product_store` ✓ (Đã có)
**Fields:**
```
{
  "year": <int>,
  "quarter": <int>,
  "month": <int>,
  "product_key": <int>,
  "store_key": <int>,
  "total_quantity_on_hand": <int>
}
```

---

## SUMMARY
- **Total Cuboids:** 56 (24 Sales + 32 Inventory)
  - Sales: 0-D(1) + 1-D(6) + 2-D(9) + 3-D(8) = 24
  - Inventory: 0-D(1) + 1-D(6) + 2-D(9) + 3-D(8) = 32

- **Marks:** ✓ = endpoint đã có, blank = cần thêm
