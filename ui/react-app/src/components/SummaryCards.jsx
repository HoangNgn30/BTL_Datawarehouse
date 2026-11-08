import React from 'react';

export const SummaryCards = ({ 
  salesTotal = null, 
  inventoryTotal = null,
  selectedCube = 'sales'
}) => {
  const formatCurrency = (value) => {
    if (!value && value !== 0) return '—';
    if (value >= 1e9) return (value / 1e9).toFixed(2) + ' Tỷ VNĐ';
    if (value >= 1e6) return (value / 1e6).toFixed(2) + ' Triệu VNĐ';
    return new Intl.NumberFormat('vi-VN').format(value) + ' VNĐ';
  };

  const formatQuantity = (value) => {
    if (!value && value !== 0) return '—';
    return new Intl.NumberFormat('vi-VN').format(value);
  };

  return (
    <div style={{
      display: 'grid',
      gridTemplateColumns: 'repeat(auto-fit, minmax(250px, 1fr))',
      gap: '20px',
      marginBottom: '30px',
    }}>
      {selectedCube === 'sales' && salesTotal && (
        <>
          <div style={{
            backgroundColor: 'white',
            padding: '25px',
            borderRadius: '12px',
            boxShadow: '0 4px 6px rgba(0, 0, 0, 0.1)',
            borderLeft: '5px solid #667eea',
            textAlign: 'center',
            transition: 'transform 0.3s',
          }}
          onMouseEnter={(e) => e.currentTarget.style.transform = 'translateY(-5px)'}
          onMouseLeave={(e) => e.currentTarget.style.transform = 'translateY(0)'}
          >
            <h3 style={{ color: '#667eea', margin: '0 0 10px 0', fontSize: '0.9em', textTransform: 'uppercase', letterSpacing: '1px' }}>
              💰 Tổng Doanh Thu
            </h3>
            <div style={{ fontSize: '1.8em', fontWeight: 'bold', color: '#333', marginBottom: '5px' }}>
              {formatCurrency(salesTotal.sum_amount)}
            </div>
            <div style={{ color: '#999', fontSize: '0.9em' }}>Từ tất cả đơn bán hàng</div>
          </div>

          <div style={{
            backgroundColor: 'white',
            padding: '25px',
            borderRadius: '12px',
            boxShadow: '0 4px 6px rgba(0, 0, 0, 0.1)',
            borderLeft: '5px solid #764ba2',
            textAlign: 'center',
            transition: 'transform 0.3s',
          }}
          onMouseEnter={(e) => e.currentTarget.style.transform = 'translateY(-5px)'}
          onMouseLeave={(e) => e.currentTarget.style.transform = 'translateY(0)'}
          >
            <h3 style={{ color: '#764ba2', margin: '0 0 10px 0', fontSize: '0.9em', textTransform: 'uppercase', letterSpacing: '1px' }}>
              📦 Tổng Số Lượng Bán
            </h3>
            <div style={{ fontSize: '1.8em', fontWeight: 'bold', color: '#333', marginBottom: '5px' }}>
              {formatQuantity(salesTotal.total_quantity)}
            </div>
            <div style={{ color: '#999', fontSize: '0.9em' }}>Sản phẩm đã bán</div>
          </div>
        </>
      )}

      {selectedCube === 'inventory' && inventoryTotal && (
        <div style={{
          backgroundColor: 'white',
          padding: '25px',
          borderRadius: '12px',
          boxShadow: '0 4px 6px rgba(0, 0, 0, 0.1)',
          borderLeft: '5px solid #4facfe',
          textAlign: 'center',
          transition: 'transform 0.3s',
        }}
        onMouseEnter={(e) => e.currentTarget.style.transform = 'translateY(-5px)'}
        onMouseLeave={(e) => e.currentTarget.style.transform = 'translateY(0)'}
        >
          <h3 style={{ color: '#4facfe', margin: '0 0 10px 0', fontSize: '0.9em', textTransform: 'uppercase', letterSpacing: '1px' }}>
            📦 Tổng Tồn Kho
          </h3>
          <div style={{ fontSize: '1.8em', fontWeight: 'bold', color: '#333', marginBottom: '5px' }}>
            {formatQuantity(inventoryTotal.total_quantity_on_hand)}
          </div>
          <div style={{ color: '#999', fontSize: '0.9em' }}>Sản phẩm còn lại trong hệ thống</div>
        </div>
      )}
    </div>
  );
};

export default SummaryCards;
