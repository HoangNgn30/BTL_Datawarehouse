import React, { useMemo, useState } from 'react';

const COLUMN_NAMES = {
  year: 'Năm',
  quarter: 'Quý',
  month: 'Tháng',
  customer_type: 'Loại Khách',
  customer_key: 'Khách Hàng',
  product_key: 'Sản Phẩm',
  store_key: 'Cửa Hàng',
  city: 'Thành Phố',
  total_quantity: 'Tổng SL',
  sum_amount: 'Tổng Tiền',
  quantity_on_hand: 'Tồn Kho',
  average_price: 'Giá TB',
  turnover_ratio_percent: 'Tỷ Lệ Quay Hàng (%)',
  sales_qty: 'SL Bán',
  inventory_qty: 'SL Tồn',
};

export const DataTable = ({ data = [], columns = [], onDrillThrough = null }) => {
  const [sortBy, setSortBy] = useState(null);
  const [sortOrder, setSortOrder] = useState('asc');

  const tableColumns = columns.length > 0 ? columns : (data.length > 0 ? Object.keys(data[0]) : []);

  const sortedData = useMemo(() => {
    if (!sortBy || data.length === 0) return data;

    const sorted = [...data].sort((a, b) => {
      const aVal = a[sortBy];
      const bVal = b[sortBy];

      if (typeof aVal === 'number' && typeof bVal === 'number') {
        return sortOrder === 'asc' ? aVal - bVal : bVal - aVal;
      }

      const aStr = String(aVal).toLowerCase();
      const bStr = String(bVal).toLowerCase();
      return sortOrder === 'asc' ? aStr.localeCompare(bStr) : bStr.localeCompare(aStr);
    });

    return sorted;
  }, [data, sortBy, sortOrder]);

  const handleSort = (col) => {
    if (sortBy === col) {
      setSortOrder(sortOrder === 'asc' ? 'desc' : 'asc');
    } else {
      setSortBy(col);
      setSortOrder('asc');
    }
  };

  const formatValue = (col, val) => {
    // Don't format year, quarter, month, customer_key, product_key, store_key (ID columns)
    if (['year', 'quarter', 'month', 'customer_key', 'product_key', 'store_key'].includes(col) && typeof val === 'number') {
      return val.toString();
    }

    if (!val && val !== 0) return '—';
    if (typeof val === 'number') {
      if (val >= 1e9) return (val / 1e9).toFixed(2) + 'T';
      if (val >= 1e6) return (val / 1e6).toFixed(2) + 'M';
      if (val >= 1e3 && !['year', 'quarter', 'month', 'customer_key', 'product_key', 'store_key'].includes(col)) return (val / 1e3).toFixed(2) + 'K';
      return val.toFixed(0);
    }
    return val;
  };

  const getColumnLabel = (col) => COLUMN_NAMES[col] || col;

  if (data.length === 0) {
    return <div style={{ padding: '20px', textAlign: 'center', color: '#999' }}>📭 Không có dữ liệu</div>;
  }

  return (
    <div style={{ overflowX: 'auto' }}>
      <table style={{
        width: '100%',
        borderCollapse: 'collapse',
        backgroundColor: 'white',
      }}>
        <thead>
          <tr style={{ backgroundColor: '#667eea', color: 'white' }}>
            {tableColumns.map((col) => (
              <th
                key={col}
                onClick={() => handleSort(col)}
                style={{
                  padding: '12px',
                  textAlign: 'left',
                  fontWeight: '600',
                  borderBottom: '2px solid #667eea',
                  cursor: 'pointer',
                  userSelect: 'none',
                  minWidth: col === 'customer_type' || col === 'product_key' ? '120px' : '80px',
                  backgroundColor: sortBy === col ? '#764ba2' : '#667eea',
                  transition: 'background-color 0.2s',
                }}
                title="Click để sắp xếp"
              >
                {getColumnLabel(col)} {sortBy === col && (sortOrder === 'asc' ? '↑' : '↓')}
              </th>
            ))}
            {onDrillThrough && (
              <th
                style={{
                  padding: '12px',
                  textAlign: 'center',
                  fontWeight: '600',
                  borderBottom: '2px solid #667eea',
                  minWidth: '120px',
                }}
              >
                Hành Động
              </th>
            )}
          </tr>
        </thead>
        <tbody>
          {sortedData.map((row, idx) => (
            <tr
              key={idx}
              style={{
                backgroundColor: idx % 2 === 0 ? '#f9f9f9' : '#fff',
                borderBottom: '1px solid #eee',
                transition: 'background-color 0.2s',
              }}
              onMouseEnter={(e) => (e.currentTarget.style.backgroundColor = '#f0f0f0')}
              onMouseLeave={(e) => (e.currentTarget.style.backgroundColor = idx % 2 === 0 ? '#f9f9f9' : '#fff')}
            >
              {tableColumns.map((col) => (
                <td
                  key={`${idx}-${col}`}
                  style={{
                    padding: '10px 12px',
                    textAlign: col.includes('quantity') || col.includes('amount') ? 'right' : 'left',
                    color: '#333',
                    fontSize: '0.95em',
                  }}
                >
                  {formatValue(col, row[col])}
                </td>
              ))}
              {onDrillThrough && (
                <td style={{ padding: '10px 12px', textAlign: 'center' }}>
                  <button
                    onClick={() => onDrillThrough(row)}
                    style={{
                      padding: '6px 12px',
                      backgroundColor: '#667eea',
                      color: 'white',
                      border: 'none',
                      borderRadius: '4px',
                      cursor: 'pointer',
                      fontSize: '0.85em',
                      fontWeight: '600',
                      transition: 'background-color 0.2s',
                    }}
                    onMouseEnter={(e) => (e.currentTarget.style.backgroundColor = '#764ba2')}
                    onMouseLeave={(e) => (e.currentTarget.style.backgroundColor = '#667eea')}
                  >
                    Drill Through
                  </button>
                </td>
              )}
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
};

export default DataTable;
