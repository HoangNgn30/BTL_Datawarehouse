/* Exact formatting for decimal strings returned by the SQL/API layer. */
(() => {
  window.formatNumber = value => {
    if (value == null) return '—';
    const text = String(value);
    const match = /^([+-]?)(\d+)(?:\.(\d+))?$/.exec(text);
    if (!match) return typeof value === 'number' ? value.toLocaleString('vi-VN') : text;
    const fraction = (match[3] || '').replace(/0+$/, '');
    const integer = BigInt(match[2]).toLocaleString('vi-VN');
    return (match[1] === '-' ? '-' : '') + integer + (fraction ? ',' + fraction : '');
  };
  window.formatMoney = value => value == null ? '—' : window.formatNumber(value) + ' ₫';
})();
