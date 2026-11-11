import React from 'react';

// The canonical dashboard and all API requests share the FastAPI origin.
export default function OLAPDashboard() {
  const base = (process.env.REACT_APP_API_URL || 'http://127.0.0.1:8017').replace(/\/$/, '');
  return <iframe title="Kho dữ liệu — OLAP và 9 báo cáo" src={`${base}/`}
    style={{ width: '100%', height: '100vh', border: 0, display: 'block' }} />;
}
