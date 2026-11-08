import React, { useState, useEffect } from 'react';
import { useOLAPStore } from '../store/olap-store';
import { olap } from '../api/olap-client';

export const FilterPanel = ({ onApply, selectedCube = 'sales' }) => {
  const [customerTypes, setCustomerTypes] = useState([]);
  const [customers, setCustomers] = useState([]);
  const [products, setProducts] = useState([]);
  const [stores, setStores] = useState([]);
  const [cities, setCities] = useState([]);
  const [loading, setLoading] = useState(false);

  const filters = useOLAPStore((state) => state.filters);
  const setFilters = useOLAPStore((state) => state.setFilters);
  const clearFilters = useOLAPStore((state) => state.clearFilters);

  useEffect(() => {
    loadMetadata();
  }, []);

  const loadMetadata = async () => {
    try {
      setLoading(true);
      const results = await Promise.all([
        olap.getCustomerTypes().catch(e => ({ data: [] })),
        olap.getCustomers().catch(e => ({ data: [] })),
        olap.getProducts(100).catch(e => ({ data: [] })),
        olap.getStores().catch(e => ({ data: [] })),
        olap.getCities().catch(e => ({ data: [] })),
      ]);

      const ctypes = results[0];
      const custs = results[1];
      const prods = results[2];
      const strs = results[3];
      const cts = results[4];

      console.log('🔍 Customer Types raw:', ctypes.data);
      console.log('🔍 Customers raw (first 5):', custs.data?.slice(0, 5));
      console.log('🔍 Products raw:', prods.data);
      console.log('🔍 Stores raw (first 5):', strs.data?.slice(0, 5));

      // Transform data if needed
      const transformList = (items, fieldName = '') => {
        if (!items || items.length === 0) {
          console.warn(`⚠️ ${fieldName} is empty`);
          return [];
        }

        // If already has value/label, return as-is
        if (items[0]?.value !== undefined && items[0]?.label !== undefined) {
          return items;
        }

        // Otherwise, transform based on structure
        return items.map((item, idx) => {
          if (typeof item === 'string') {
            return { value: item, label: item };
          }
          if (typeof item === 'number') {
            return { value: item, label: item.toString() };
          }

          // Log first item to understand structure
          if (idx === 0) {
            console.log(`🔍 ${fieldName} first item structure:`, item);
          }

          // Try to extract value/label from object
          const keys = Object.keys(item);
          const valueKey = keys[0]; // First key as value
          const labelKey = keys[1] || keys[0]; // Second or first key as label

          return {
            value: item[valueKey],
            label: item[labelKey]?.toString() || item[valueKey]?.toString(),
          };
        });
      };

      setCustomerTypes(transformList(ctypes.data, 'Customer Types'));
      setCustomers(transformList(custs.data, 'Customers'));
      
      const productsList = transformList(prods.data, 'Products');
      console.log('✅ Products loaded:', {
        count: productsList.length,
        first3: productsList.slice(0, 3),
        last3: productsList.slice(-3),
      });
      setProducts(productsList);
      
      const storesList = transformList(strs.data, 'Stores');
      console.log('✅ Stores loaded:', {
        count: storesList.length,
        first5: storesList.slice(0, 5),
      });
      setStores(storesList);
      
      setCities(transformList(cts.data, 'Cities'));
    } catch (error) {
      console.error('❌ Error loading metadata:', error);
      alert('Lỗi tải metadata: ' + error.message);
    } finally {
      setLoading(false);
    }
  };

  const handleFilterChange = (field, value) => {
    setFilters({ ...filters, [field]: value || null });
  };

  const handleApply = () => {
    if (onApply) onApply();
  };

  return (
    <div className="filter-panel" style={{ padding: '15px', backgroundColor: '#f9f9f9', borderRadius: '6px', marginBottom: '15px' }}>
      <h3 style={{ marginBottom: '15px', color: '#333' }}>🔎 Slice & Dice (Filter)</h3>

      {loading && <p style={{ color: '#999' }}>Đang tải metadata...</p>}

      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))', gap: '15px' }}>
        {selectedCube === 'sales' && (
          <>
            <div>
              <label style={{ fontWeight: '600', color: '#667eea', display: 'block', marginBottom: '5px' }}>
                Loại Khách Hàng
              </label>
              <select
                value={filters.customerType || ''}
                onChange={(e) => handleFilterChange('customerType', e.target.value)}
                style={{ width: '100%', padding: '8px', border: '2px solid #ddd', borderRadius: '4px' }}
              >
                <option value="">-- Tất cả --</option>
                {customerTypes.map((ct) => (
                  <option key={ct.value} value={ct.value}>
                    {ct.label}
                  </option>
                ))}
              </select>
            </div>

            <div>
              <label style={{ fontWeight: '600', color: '#667eea', display: 'block', marginBottom: '5px' }}>
                Khách Hàng
              </label>
              <select
                value={filters.customerKey || ''}
                onChange={(e) => handleFilterChange('customerKey', e.target.value)}
                style={{ width: '100%', padding: '8px', border: '2px solid #ddd', borderRadius: '4px' }}
              >
                <option value="">-- Tất cả --</option>
                {customers.map((c) => (
                  <option key={c.value} value={c.value}>
                    {c.label}
                  </option>
                ))}
              </select>
            </div>
          </>
        )}

        <div>
          <label style={{ fontWeight: '600', color: '#667eea', display: 'block', marginBottom: '5px' }}>
            Sản Phẩm
          </label>
          <select
            value={filters.productKey || ''}
            onChange={(e) => handleFilterChange('productKey', e.target.value)}
            style={{ width: '100%', padding: '8px', border: '2px solid #ddd', borderRadius: '4px' }}
          >
            <option value="">-- Tất cả --</option>
            {products.map((p) => (
              <option key={p.value} value={p.value}>
                {p.label}
              </option>
            ))}
          </select>
        </div>

        {selectedCube === 'inventory' && (
          <div>
            <label style={{ fontWeight: '600', color: '#667eea', display: 'block', marginBottom: '5px' }}>
              Cửa Hàng
            </label>
            <select
              value={filters.storeKey || ''}
              onChange={(e) => handleFilterChange('storeKey', e.target.value)}
              style={{ width: '100%', padding: '8px', border: '2px solid #ddd', borderRadius: '4px' }}
            >
              <option value="">-- Tất cả --</option>
              {stores.map((s) => (
                <option key={s.value} value={s.value}>
                  {s.label}
                </option>
              ))}
            </select>
          </div>
        )}

        <div style={{ display: 'flex', gap: '10px', alignItems: 'flex-end' }}>
          <button
            onClick={handleApply}
            style={{
              flex: 1,
              padding: '8px',
              backgroundColor: '#667eea',
              color: 'white',
              border: 'none',
              borderRadius: '4px',
              fontWeight: '600',
              cursor: 'pointer',
            }}
          >
            Áp Dụng
          </button>
          <button
            onClick={clearFilters}
            style={{
              flex: 1,
              padding: '8px',
              backgroundColor: '#ccc',
              color: '#333',
              border: 'none',
              borderRadius: '4px',
              fontWeight: '600',
              cursor: 'pointer',
            }}
          >
            Xóa Bộ Lọc
          </button>
        </div>
      </div>
    </div>
  );
};

export default FilterPanel;
