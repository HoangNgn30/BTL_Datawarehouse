import React, { useMemo } from 'react';

export const PivotTable = ({ data = [], rowDimension, colDimension, valueDimension }) => {
  const pivotData = useMemo(() => {
    if (!data.length || !rowDimension || !colDimension || !valueDimension) {
      return { rows: [], columns: [], table: {} };
    }

    const rows = new Set();
    const columns = new Set();
    const table = {};

    // Build pivot table structure
    data.forEach((row) => {
      const rowKey = row[rowDimension];
      const colKey = row[colDimension];
      const value = row[valueDimension];

      rows.add(rowKey);
      columns.add(colKey);

      const key = `${rowKey}|${colKey}`;
      table[key] = value;
    });

    return {
      rows: Array.from(rows).sort(),
      columns: Array.from(columns).sort(),
      table,
    };
  }, [data, rowDimension, colDimension, valueDimension]);

  if (pivotData.rows.length === 0) {
    return (
      <div style={{ padding: '20px', textAlign: 'center', color: '#999' }}>
        📭 Không có dữ liệu để Pivot
      </div>
    );
  }

  const formatValue = (val) => {
    if (!val) return '—';
    if (typeof val === 'number') {
      if (val > 1e6) return (val / 1e6).toFixed(1) + 'M';
      if (val > 1e3) return (val / 1e3).toFixed(1) + 'K';
      return val.toFixed(0);
    }
    return val;
  };

  return (
    <div style={{ overflowX: 'auto', marginBottom: '20px' }}>
      <table style={{
        width: '100%',
        borderCollapse: 'collapse',
        backgroundColor: 'white',
        borderRadius: '6px',
      }}>
        <thead>
          <tr style={{ backgroundColor: '#667eea', color: 'white' }}>
            <th style={{ padding: '12px', textAlign: 'left', fontWeight: '600', borderBottom: '2px solid #667eea', minWidth: '150px' }}>
              {rowDimension}
            </th>
            {pivotData.columns.map((col) => (
              <th
                key={col}
                style={{
                  padding: '12px',
                  textAlign: 'center',
                  fontWeight: '600',
                  borderBottom: '2px solid #667eea',
                  minWidth: '100px',
                }}
              >
                {col}
              </th>
            ))}
          </tr>
        </thead>
        <tbody>
          {pivotData.rows.map((row, idx) => (
            <tr
              key={row}
              style={{
                backgroundColor: idx % 2 === 0 ? '#f9f9f9' : '#fff',
                borderBottom: '1px solid #eee',
              }}
            >
              <td style={{ padding: '12px', textAlign: 'left', fontWeight: '600', color: '#667eea' }}>
                {row}
              </td>
              {pivotData.columns.map((col) => {
                const key = `${row}|${col}`;
                const value = pivotData.table[key];
                return (
                  <td
                    key={key}
                    style={{
                      padding: '12px',
                      textAlign: 'center',
                      color: value ? '#333' : '#999',
                    }}
                  >
                    {formatValue(value)}
                  </td>
                );
              })}
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
};

export default PivotTable;
