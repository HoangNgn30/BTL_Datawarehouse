import React, { useState } from 'react';
import DataTable from './DataTable';

export const DrillThroughModal = ({ 
  isOpen, 
  onClose, 
  data = [], 
  pagination = {},
  onPageChange = null,
  title = 'Drill Through - Raw Data'
}) => {
  const [pageSize, setPageSize] = useState(pagination.pageSize || 50);

  if (!isOpen) return null;

  const handlePreviousPage = () => {
    if (onPageChange && pagination.offset >= pageSize) {
      onPageChange(pagination.offset - pageSize);
    }
  };

  const handleNextPage = () => {
    if (onPageChange && pagination.offset + pageSize < pagination.total) {
      onPageChange(pagination.offset + pageSize);
    }
  };

  const currentPage = Math.floor((pagination.offset || 0) / pageSize) + 1;
  const totalPages = Math.ceil((pagination.total || 0) / pageSize);

  return (
    <div style={{
      position: 'fixed',
      top: 0,
      left: 0,
      right: 0,
      bottom: 0,
      backgroundColor: 'rgba(0, 0, 0, 0.6)',
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center',
      zIndex: 1000,
      padding: '20px',
    }}>
      <div style={{
        backgroundColor: 'white',
        borderRadius: '8px',
        maxWidth: '90vw',
        maxHeight: '90vh',
        overflow: 'auto',
        padding: '20px',
        boxShadow: '0 8px 32px rgba(0, 0, 0, 0.2)',
      }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '20px' }}>
          <h2 style={{ color: '#667eea', margin: 0 }}>{title}</h2>
          <button
            onClick={onClose}
            style={{
              background: 'none',
              border: 'none',
              fontSize: '24px',
              cursor: 'pointer',
              color: '#999',
            }}
          >
            ✕
          </button>
        </div>

        {/* Data Table */}
        <div style={{ marginBottom: '20px', maxHeight: '60vh', overflowY: 'auto' }}>
          <DataTable data={data} />
        </div>

        {/* Pagination */}
        <div style={{
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'center',
          padding: '15px',
          backgroundColor: '#f9f9f9',
          borderRadius: '6px',
          borderTop: '1px solid #eee',
        }}>
          <div style={{ color: '#666', fontSize: '0.9em' }}>
            <strong>Trang {currentPage} / {totalPages}</strong> | Tổng: {pagination.total} records
          </div>

          <div style={{ display: 'flex', gap: '10px' }}>
            <button
              onClick={handlePreviousPage}
              disabled={pagination.offset === 0}
              style={{
                padding: '8px 16px',
                backgroundColor: pagination.offset === 0 ? '#ccc' : '#667eea',
                color: 'white',
                border: 'none',
                borderRadius: '4px',
                cursor: pagination.offset === 0 ? 'not-allowed' : 'pointer',
              }}
            >
              ← Trang Trước
            </button>

            <button
              onClick={handleNextPage}
              disabled={pagination.offset + pageSize >= pagination.total}
              style={{
                padding: '8px 16px',
                backgroundColor: pagination.offset + pageSize >= pagination.total ? '#ccc' : '#667eea',
                color: 'white',
                border: 'none',
                borderRadius: '4px',
                cursor: pagination.offset + pageSize >= pagination.total ? 'not-allowed' : 'pointer',
              }}
            >
              Trang Sau →
            </button>

            <select
              value={pageSize}
              onChange={(e) => setPageSize(parseInt(e.target.value))}
              style={{
                padding: '8px',
                border: '1px solid #ddd',
                borderRadius: '4px',
              }}
            >
              <option value={10}>10 / page</option>
              <option value={25}>25 / page</option>
              <option value={50}>50 / page</option>
              <option value={100}>100 / page</option>
            </select>
          </div>
        </div>
      </div>
    </div>
  );
};

export default DrillThroughModal;
