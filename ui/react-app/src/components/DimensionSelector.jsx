import React, { useState, useEffect } from 'react';
import { useOLAPStore } from '../store/olap-store';
import { olap } from '../api/olap-client';

export const DimensionSelector = ({ onDimensionChange }) => {
  const selectedYear = useOLAPStore((state) => state.selectedYear);
  const selectedQuarter = useOLAPStore((state) => state.selectedQuarter);
  const selectedMonth = useOLAPStore((state) => state.selectedMonth);
  const setSelectedYear = useOLAPStore((state) => state.setSelectedYear);
  const setSelectedQuarter = useOLAPStore((state) => state.setSelectedQuarter);
  const setSelectedMonth = useOLAPStore((state) => state.setSelectedMonth);

  const [years, setYears] = useState([2020, 2021, 2022, 2023, 2024]);
  const [quarters, setQuarters] = useState([1, 2, 3, 4]);
  const [months, setMonths] = useState([]);

  useEffect(() => {
    setMonths(Array.from({ length: 12 }, (_, i) => i + 1));
  }, []);

  const handleYearChange = (e) => {
    const year = parseInt(e.target.value);
    setSelectedYear(year);
    if (onDimensionChange) onDimensionChange();
  };

  const handleQuarterChange = (e) => {
    const quarter = parseInt(e.target.value);
    setSelectedQuarter(quarter);
    if (onDimensionChange) onDimensionChange();
  };

  const handleMonthChange = (e) => {
    const month = parseInt(e.target.value);
    setSelectedMonth(month);
    if (onDimensionChange) onDimensionChange();
  };

  const breadcrumb = [
    <span key="year" onClick={() => setSelectedYear(selectedYear)} style={{ cursor: 'pointer', color: '#667eea', fontWeight: 'bold' }}>
      📅 {selectedYear}
    </span>,
  ];

  if (selectedQuarter) {
    breadcrumb.push(
      <span key="sep1"> → </span>,
      <span key="quarter" onClick={() => setSelectedQuarter(null)} style={{ cursor: 'pointer', color: '#764ba2' }}>
        Q{selectedQuarter}
      </span>
    );
  }

  if (selectedMonth) {
    breadcrumb.push(
      <span key="sep2"> → </span>,
      <span key="month" onClick={() => setSelectedMonth(null)} style={{ cursor: 'pointer', color: '#f093fb' }}>
        Tháng {selectedMonth}
      </span>
    );
  }

  return (
    <div className="dimension-selector" style={{ padding: '15px', backgroundColor: '#f9f9f9', borderRadius: '6px', marginBottom: '15px' }}>
      <h3 style={{ marginBottom: '10px', color: '#333' }}>🔍 Drill-Down Navigator</h3>
      
      <div style={{ marginBottom: '10px', fontStyle: 'italic', color: '#667eea', fontSize: '0.95em' }}>
        Breadcrumb: {breadcrumb}
      </div>

      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: '10px' }}>
        <div>
          <label style={{ fontWeight: '600', color: '#667eea', display: 'block', marginBottom: '5px' }}>
            Năm
          </label>
          <select value={selectedYear} onChange={handleYearChange} style={{ width: '100%', padding: '8px', border: '2px solid #ddd', borderRadius: '4px' }}>
            {years.map((y) => (
              <option key={y} value={y}>
                {y}
              </option>
            ))}
          </select>
        </div>

        <div>
          <label style={{ fontWeight: '600', color: '#764ba2', display: 'block', marginBottom: '5px' }}>
            Quý
          </label>
          <select
            value={selectedQuarter || ''}
            onChange={handleQuarterChange}
            style={{ width: '100%', padding: '8px', border: '2px solid #ddd', borderRadius: '4px' }}
          >
            <option value="">-- Chọn Quý --</option>
            {quarters.map((q) => (
              <option key={q} value={q}>
                Quý {q}
              </option>
            ))}
          </select>
        </div>

        <div>
          <label style={{ fontWeight: '600', color: '#f093fb', display: 'block', marginBottom: '5px' }}>
            Tháng
          </label>
          <select
            value={selectedMonth || ''}
            onChange={handleMonthChange}
            disabled={!selectedQuarter}
            style={{ width: '100%', padding: '8px', border: '2px solid #ddd', borderRadius: '4px', opacity: selectedQuarter ? 1 : 0.5 }}
          >
            <option value="">-- Chọn Tháng --</option>
            {months.map((m) => (
              <option key={m} value={m}>
                Tháng {m}
              </option>
            ))}
          </select>
        </div>
      </div>
    </div>
  );
};

export default DimensionSelector;
