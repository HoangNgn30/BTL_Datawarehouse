import React, { useEffect, useState } from 'react';
import axios from 'axios';

const OLAPDashboard = () => {
  const API = 'http://localhost:8000/api';
  
  const [cube, setCube] = useState('sales');
  const [selectedYear, setSelectedYear] = useState(2023);
  const [viewMode, setViewMode] = useState('year');
  const [data, setData] = useState([]);
  const [loading, setLoading] = useState(false);
  const [years, setYears] = useState([]);
  const [error, setError] = useState(null);

  // Load metadata
  useEffect(() => {
    const loadMetadata = async () => {
      try {
        const yearsRes = await axios.get(`${API}/metadata/years`);
        setYears(yearsRes.data || []);
        if (yearsRes.data && yearsRes.data.length > 0) {
          setSelectedYear(yearsRes.data[0]);
        }
      } catch (err) {
        setError(`Error loading metadata: ${err.message}`);
      }
    };
    loadMetadata();
  }, []);

  // Load cuboid data
  useEffect(() => {
    const loadData = async () => {
      setLoading(true);
      setError(null);
      try {
        let endpoint = '';
        
        if (cube === 'sales') {
          if (viewMode === 'year') endpoint = `${API}/sales/by-year`;
          else if (viewMode === 'quarter') endpoint = `${API}/sales/by-quarter?nam=${selectedYear}`;
          else if (viewMode === 'month') endpoint = `${API}/sales/by-month?nam=${selectedYear}`;
          else if (viewMode === 'product') endpoint = `${API}/sales/by-product`;
          else if (viewMode === 'type') endpoint = `${API}/sales/by-customer-type`;
        } else if (cube === 'inventory') {
          if (viewMode === 'year') endpoint = `${API}/inventory/by-year`;
          else if (viewMode === 'quarter') endpoint = `${API}/inventory/by-quarter?nam=${selectedYear}`;
          else if (viewMode === 'month') endpoint = `${API}/inventory/by-month?nam=${selectedYear}`;
          else if (viewMode === 'product') endpoint = `${API}/inventory/by-product`;
          else if (viewMode === 'state') endpoint = `${API}/inventory/by-state`;
        }

        if (endpoint) {
          const res = await axios.get(endpoint);
          setData(res.data || []);
        }
      } catch (err) {
        setError(`Error loading data: ${err.message}`);
        setData([]);
      }
      setLoading(false);
    };

    loadData();
  }, [cube, viewMode, selectedYear]);

  const formatNum = (num) => {
    if (!num && num !== 0) return '-';
    if (num >= 1000000000) return (num / 1000000000).toFixed(2) + 'B';
    if (num >= 1000000) return (num / 1000000).toFixed(2) + 'M';
    if (num >= 1000) return (num / 1000).toFixed(2) + 'K';
    return num.toLocaleString();
  };

  const columns = data.length > 0 ? Object.keys(data[0]) : [];

  return (
    <div style={{ fontFamily: 'Arial, sans-serif', backgroundColor: '#f5f5f5', minHeight: '100vh', padding: '20px' }}>
      <header style={{ textAlign: 'center', marginBottom: '30px', color: '#333' }}>
        <h1>📊 OLAP Dashboard — Sales & Inventory</h1>
        <p>56 Cuboid Tables • 7 OLAP Operations</p>
      </header>

      <div style={{ maxWidth: '1200px', margin: '0 auto' }}>
        {/* Controls */}
        <div style={{ display: 'grid', gridTemplateColumns: 'auto auto auto', gap: '15px', marginBottom: '20px', backgroundColor: 'white', padding: '15px', borderRadius: '8px' }}>
          <div>
            <label style={{ marginRight: '10px', fontWeight: 'bold' }}>Cube:</label>
            <select value={cube} onChange={(e) => setCube(e.target.value)} style={{ padding: '5px' }}>
              <option value="sales">📈 Sales</option>
              <option value="inventory">📦 Inventory</option>
            </select>
          </div>

          <div>
            <label style={{ marginRight: '10px', fontWeight: 'bold' }}>View:</label>
            <select value={viewMode} onChange={(e) => setViewMode(e.target.value)} style={{ padding: '5px' }}>
              {cube === 'sales' ? (
                <>
                  <option value="year">By Year</option>
                  <option value="quarter">By Quarter</option>
                  <option value="month">By Month</option>
                  <option value="product">By Product</option>
                  <option value="type">By Customer Type</option>
                </>
              ) : (
                <>
                  <option value="year">By Year</option>
                  <option value="quarter">By Quarter</option>
                  <option value="month">By Month</option>
                  <option value="product">By Product</option>
                  <option value="state">By State</option>
                </>
              )}
            </select>
          </div>

          {(viewMode === 'quarter' || viewMode === 'month') && (
            <div>
              <label style={{ marginRight: '10px', fontWeight: 'bold' }}>Year:</label>
              <select value={selectedYear} onChange={(e) => setSelectedYear(parseInt(e.target.value))} style={{ padding: '5px' }}>
                {years.map((y) => (
                  <option key={y} value={y}>{y}</option>
                ))}
              </select>
            </div>
          )}
        </div>

        {/* Error */}
        {error && <div style={{ backgroundColor: '#fee', padding: '15px', borderRadius: '8px', color: '#c33', marginBottom: '20px' }}>❌ {error}</div>}

        {/* Loading */}
        {loading && <div style={{ textAlign: 'center', padding: '40px', color: '#999' }}>⏳ Loading...</div>}

        {/* Data Table */}
        {!loading && data.length > 0 && (
          <div style={{ backgroundColor: 'white', padding: '20px', borderRadius: '8px', marginBottom: '20px' }}>
            <h2>📋 Results ({data.length} rows)</h2>
            <div style={{ overflowX: 'auto' }}>
              <table style={{ width: '100%', borderCollapse: 'collapse' }}>
                <thead>
                  <tr style={{ backgroundColor: '#f0f0f0', borderBottom: '2px solid #ddd' }}>
                    {columns.map((col) => (
                      <th key={col} style={{ padding: '10px', textAlign: 'left', fontWeight: 'bold' }}>{col}</th>
                    ))}
                  </tr>
                </thead>
                <tbody>
                  {data.map((row, idx) => (
                    <tr key={idx} style={{ borderBottom: '1px solid #eee', backgroundColor: idx % 2 === 0 ? '#fafafa' : 'white' }}>
                      {columns.map((col) => (
                        <td key={`${idx}-${col}`} style={{ padding: '10px' }}>
                          {typeof row[col] === 'number' ? formatNum(row[col]) : row[col]}
                        </td>
                      ))}
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>
        )}

        {!loading && data.length === 0 && !error && (
          <div style={{ textAlign: 'center', padding: '40px', color: '#999' }}>
            🔍 No data to display
          </div>
        )}

        {/* OLAP Operations */}
        <div style={{ backgroundColor: 'white', padding: '20px', borderRadius: '8px' }}>
          <h2>🔄 7 OLAP Operations</h2>
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(250px, 1fr))', gap: '15px' }}>
            <div style={{ border: '1px solid #ddd', padding: '15px', borderRadius: '8px' }}>
              <h3>1️⃣ Drill-Down</h3>
              <p>Navigate year → quarter → month</p>
              <button onClick={() => { setCube('sales'); setViewMode('year'); }} style={{ marginRight: '5px', padding: '5px 10px' }}>Year</button>
              <button onClick={() => { setCube('sales'); setViewMode('quarter'); }} style={{ marginRight: '5px', padding: '5px 10px' }}>Quarter</button>
              <button onClick={() => { setCube('sales'); setViewMode('month'); }} style={{ padding: '5px 10px' }}>Month</button>
            </div>

            <div style={{ border: '1px solid #ddd', padding: '15px', borderRadius: '8px' }}>
              <h3>2️⃣ Roll-Up</h3>
              <p>Aggregate to summary level</p>
              <p style={{ color: '#999', fontSize: '12px' }}>Automatic aggregation in results</p>
            </div>

            <div style={{ border: '1px solid #ddd', padding: '15px', borderRadius: '8px' }}>
              <h3>3️⃣ Slice</h3>
              <p>Filter single dimension</p>
              <button disabled style={{ padding: '5px 10px' }}>Coming Soon</button>
            </div>

            <div style={{ border: '1px solid #ddd', padding: '15px', borderRadius: '8px' }}>
              <h3>4️⃣ Dice</h3>
              <p>Filter multiple dimensions</p>
              <button disabled style={{ padding: '5px 10px' }}>Coming Soon</button>
            </div>

            <div style={{ border: '1px solid #ddd', padding: '15px', borderRadius: '8px' }}>
              <h3>5️⃣ Pivot</h3>
              <p>Transpose rows/columns</p>
              <button disabled style={{ padding: '5px 10px' }}>Coming Soon</button>
            </div>

            <div style={{ border: '1px solid #ddd', padding: '15px', borderRadius: '8px' }}>
              <h3>6️⃣ Drill Across</h3>
              <p>Compare Sales vs Inventory</p>
              <button disabled style={{ padding: '5px 10px' }}>Coming Soon</button>
            </div>

            <div style={{ border: '1px solid #ddd', padding: '15px', borderRadius: '8px' }}>
              <h3>7️⃣ Drill Through</h3>
              <p>View raw transactions</p>
              <button disabled style={{ padding: '5px 10px' }}>Coming Soon</button>
            </div>
          </div>
        </div>
      </div>

      <footer style={{ textAlign: 'center', marginTop: '40px', color: '#999', fontSize: '12px' }}>
        💾 Backend: FastAPI v3.0 | 🎨 Frontend: React 18 | 🗄️ Database: SQL Server
      </footer>
    </div>
  );
};

export default OLAPDashboard;
      <DrillThroughModal
        isOpen={showDrillThrough}
        onClose={() => setShowDrillThrough(false)}
        data={drillThroughData}
        pagination={drillThroughPagination}
        title="Drill Through - Raw Transaction Data"
      />

      {/* Footer */}
      <footer style={{ textAlign: 'center', color: '#999', marginTop: '40px', fontSize: '0.9em' }}>
        © 2026 PTIT - Data Warehouse & Data Mining | React + FastAPI + 56 Cuboid OLAP
      </footer>
    </div>
  );
};

export default OLAPDashboard;
