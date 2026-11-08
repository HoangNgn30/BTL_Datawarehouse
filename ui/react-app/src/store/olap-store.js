import { create } from 'zustand';

export const useOLAPStore = create((set, get) => ({
  // Selected Dimensions (Drill-down state)
  selectedYear: 2023,
  selectedQuarter: null,
  selectedMonth: null,
  selectedCube: 'sales', // 'sales' or 'inventory'

  // View Mode
  viewMode: 'drilldown', // 'drilldown', 'pivot', 'crossanalysis'

  // Filters (Slice/Dice)
  filters: {
    customerType: null,
    customerKey: null,
    productKey: null,
    storeKey: null,
  },

  // Pivot settings
  pivotRows: [],
  pivotCols: [],

  // Data
  cuboidData: [],
  drillThroughData: [],
  drillThroughPagination: { page: 0, pageSize: 50, total: 0 },
  metadata: {
    customerTypes: [],
    products: [],
    stores: [],
    cities: [],
  },

  // UI State
  loading: false,
  error: null,
  selectedDrillThroughRecord: null,
  showDrillThroughModal: false,

  // Actions
  setSelectedYear: (year) => set({ selectedYear: year, selectedMonth: null }),
  setSelectedQuarter: (quarter) => set({ selectedQuarter: quarter, selectedMonth: null }),
  setSelectedMonth: (month) => set({ selectedMonth: month }),
  setSelectedCube: (cube) => set({ selectedCube: cube }),
  setViewMode: (mode) => set({ viewMode: mode }),
  
  setFilters: (filters) => set({ filters }),
  clearFilters: () => set({ filters: { customerType: null, customerKey: null, productKey: null, storeKey: null } }),
  
  setPivot: (rows, cols) => set({ pivotRows: rows, pivotCols: cols }),
  
  setCuboidData: (data) => set({ cuboidData: data, loading: false }),
  setDrillThroughData: (data) => set({ drillThroughData: data }),
  setDrillThroughPagination: (pagination) => set({ drillThroughPagination: pagination }),
  
  setMetadata: (metadata) => set({ metadata }),
  
  setLoading: (loading) => set({ loading }),
  setError: (error) => set({ error }),
  
  setShowDrillThroughModal: (show, record = null) => 
    set({ showDrillThroughModal: show, selectedDrillThroughRecord: record }),
  
  reset: () => set({
    selectedYear: 2023,
    selectedQuarter: null,
    selectedMonth: null,
    viewMode: 'drilldown',
    filters: { customerType: null, customerKey: null, productKey: null, storeKey: null },
    cuboidData: [],
    drillThroughData: [],
    loading: false,
    error: null,
  }),
}));
