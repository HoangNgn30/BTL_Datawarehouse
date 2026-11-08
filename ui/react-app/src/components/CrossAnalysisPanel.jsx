import React from 'react';
import DataTable from './DataTable';
import ChartRenderer from './ChartRenderer';

export const CrossAnalysisPanel = ({ data, title = 'Drill Across Analysis' }) => {
  if (!data || data.length === 0) {
    return (
      <div style={{ padding: '20px', textAlign: 'center', color: '#999', backgroundColor: 'white', borderRadius: '6px' }}>
        📭 Không có dữ liệu Cross-Analysis
      </div>
    );
  }

  const chartData = data.slice(0, 20); // Top 20 for chart

  return (
    <div style={{ backgroundColor: 'white', padding: '20px', borderRadius: '6px', marginBottom: '20px' }}>
      <h3 style={{ marginBottom: '15px', color: '#667eea' }}>🔀 {title}</h3>
      
      <div style={{ marginBottom: '20px' }}>
        <h4 style={{ marginBottom: '10px', color: '#333', fontSize: '1em' }}>📊 Biểu Đồ</h4>
        <ChartRenderer data={chartData} type="bar" yKey="total_sales" xKey="product_key" />
      </div>

      <div>
        <h4 style={{ marginBottom: '10px', color: '#333', fontSize: '1em' }}>📋 Bảng Chi Tiết</h4>
        <DataTable data={data} />
      </div>
    </div>
  );
};

export default CrossAnalysisPanel;
