import axios from 'axios';

const API_BASE = 'http://127.0.0.1:8000/api';

const client = axios.create({
  baseURL: API_BASE,
  timeout: 10000,
});

export const olap = {
  // Metadata
  getCustomerTypes: () => client.get('/metadata/customer-types'),
  getCustomers: () => client.get('/metadata/customers'),
  getProducts: (limit = 100) => client.get('/metadata/products', { params: { limit } }),
  getStores: () => client.get('/metadata/stores'),
  getCities: () => client.get('/metadata/cities'),

  // SALES CUBE - Apex (0-D)
  getSalesApex: () => client.get('/sales/apex'),

  // SALES CUBE - Time Hierarchy (1-D)
  getSalesByYear: () => client.get('/sales/time/year'),
  getSalesByQuarter: (year) => client.get('/sales/time/quarter', { params: { year } }),
  getSalesByMonth: (year) => client.get('/sales/time/month', { params: { year } }),

  // SALES CUBE - Slice/Dice (1-D)
  getSalesByProduct: () => client.get('/sales/product'),
  getSalesByCustomerType: () => client.get('/sales/customer-type'),

  // SALES CUBE - 2-D (Time × Product)
  getSalesYearProduct: () => client.get('/sales/time-product/year-product'),
  getSalesQuarterProduct: (year) => client.get('/sales/time-product/quarter-product', { params: { year } }),
  getSalesMonthProduct: (year) => client.get('/sales/time-product/month-product', { params: { year } }),

  // SALES CUBE - 2-D (Time × Customer)
  getSalesYearCustType: () => client.get('/sales/time-customer/year-custtype'),
  getSalesQuarterCustType: (year) => client.get('/sales/time-customer/quarter-custtype', { params: { year } }),
  getSalesMonthByCustType: (year) => client.get('/sales/time-customer/month-custtype', { params: { year } }),
  getSalesMonthByCustomer: (year) => client.get('/sales/time-customer/month-customer', { params: { year } }),

  // SALES CUBE - 2-D (Product × Customer)
  getSalesProductCustType: (year) => client.get('/sales/product-customer', { params: { year } }),

  // SALES CUBE - 3-D
  getSales3dYearProductCustType: (year) => client.get('/sales/3d/year-product-custtype', { params: { year } }),
  getSales3dQuarterProductCustType: (year, quarter) => client.get('/sales/3d/quarter-product-custtype', { params: { year, quarter } }),
  getSales3dMonthProductCustType: (year, month) => client.get('/sales/3d/month-product-custtype', { params: { year, month } }),
  getSales3dMonthProductCustomer: (year, month) => client.get('/sales/3d/month-product-customer', { params: { year, month } }),

  // INVENTORY CUBE - Apex (0-D)
  getInventoryApex: () => client.get('/inventory/apex'),

  // INVENTORY CUBE - Time Hierarchy (1-D)
  getInventoryByYear: () => client.get('/inventory/time/year'),
  getInventoryByQuarter: (year) => client.get('/inventory/time/quarter', { params: { year } }),
  getInventoryByMonth: (year) => client.get('/inventory/time/month', { params: { year } }),

  // INVENTORY CUBE - Slice/Dice (1-D)
  getInventoryByProduct: () => client.get('/inventory/product'),
  getInventoryByStore: () => client.get('/inventory/store'),

  // INVENTORY CUBE - 2-D (Time × Product)
  getInventoryYearProduct: () => client.get('/inventory/time-product/year-product'),
  getInventoryQuarterProduct: (year) => client.get('/inventory/time-product/quarter-product', { params: { year } }),
  getInventoryMonthProduct: (year) => client.get('/inventory/time-product/month-product', { params: { year } }),

  // INVENTORY CUBE - 2-D (Time × Store)
  getInventoryYearStore: () => client.get('/inventory/time-store/year-store'),
  getInventoryQuarterStore: (year) => client.get('/inventory/time-store/quarter-store', { params: { year } }),
  getInventoryMonthStore: (year) => client.get('/inventory/time-store/month-store', { params: { year } }),

  // INVENTORY CUBE - 2-D (Product × Store)
  getInventoryProductStore: () => client.get('/inventory/product-store'),

  // INVENTORY CUBE - 3-D
  getInventory3dYearProductStore: (year) => client.get('/inventory/3d/year-product-store', { params: { year } }),
  getInventory3dQuarterProductStore: (year, quarter) => client.get('/inventory/3d/quarter-product-store', { params: { year, quarter } }),
  getInventoryMonthProductStore: (year, month, store_key) => client.get('/inventory/3d/month-product-store', { params: { year, month, store_key } }),

  // Drill Across
  getCrossAnalysisSalesVsInventoryByProduct: () => client.get('/cross-analysis/sales-vs-inventory-by-product'),
  getCrossAnalysisSalesVsInventoryByMonth: (year) => client.get('/cross-analysis/sales-vs-inventory-by-month', { params: { year } }),

  // Drill Through
  drillThroughSales: (year, month, customer_type, product_key, limit = 50, offset = 0) => 
    client.get('/drill-through/sales', { 
      params: { year, month, customer_type, product_key, limit, offset } 
    }),
  drillThroughInventory: (year, month, store_key, product_key, limit = 50, offset = 0) => 
    client.get('/drill-through/inventory', { 
      params: { year, month, store_key, product_key, limit, offset } 
    }),

  // Summary
  getSalesTotal: () => client.get('/summary/sales-total'),
  getInventoryTotal: () => client.get('/summary/inventory-total'),
};

export default client;
