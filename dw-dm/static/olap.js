
// ============== Helpers ==============
const API = "";
const fmtNum = n => (n == null ? "—" : Number(n).toLocaleString("vi-VN"));
const fmtMoney = n => (n == null ? "—" : Number(n).toLocaleString("vi-VN") + " ₫");

async function api(path) {
  const res = await fetch(API + path);
  if (!res.ok) throw new Error("Không tải được dữ liệu. Vui lòng thử lại hoặc kiểm tra kết nối dữ liệu.");
  return res.json();
}

function el(id) { return document.getElementById(id); }
function mkOption(v, label) { const o = document.createElement("option"); o.value = v; o.textContent = label ?? v; return o; }

// ============== Sidebar nav ==============
document.querySelectorAll(".nav-item[data-tab]").forEach(item => {
  item.addEventListener("click", () => {
    document.querySelectorAll(".nav-item").forEach(i => i.classList.remove("active"));
    document.querySelectorAll(".tab-content").forEach(t => t.classList.remove("active"));
    item.classList.add("active");
    el("tab-" + item.dataset.tab).classList.add("active");
    location.hash=item.dataset.tab;
    el("page-location").textContent=item.textContent.trim();
    document.querySelector(".sidebar").classList.remove("opened");
  });
});

// ============== Charts (singletons) ==============
const charts = {};
const theme = getComputedStyle(document.documentElement);
const chartFont = theme.getPropertyValue('--app-font').trim();
const chartText = theme.getPropertyValue('--muted').trim();
function chart(id, type, labels, datasets, opts = {}) {
  if (charts[id]) charts[id].destroy();
  if (!el(id) || typeof Chart === "undefined") return;
  if (Chart.defaults) {
    Chart.defaults.font.family = chartFont;
    Chart.defaults.font.size = 13;
    Chart.defaults.color = chartText;
  }
  const ctx = el(id).getContext("2d");
  charts[id] = new Chart(ctx, {
    type, data: { labels, datasets },
    options: {
      responsive: true, maintainAspectRatio: false,
      animation: window.matchMedia?.('(prefers-reduced-motion: reduce)')?.matches ? false : { duration: 200 },
      font: { family: chartFont, size: 13 },
      plugins: { legend: { position: "bottom", labels: { color: chartText, boxWidth: 12, padding: 16, font: { size: 13, family: chartFont } } } },
      scales: type === "pie" || type === "doughnut" ? {} : {
        y: { beginAtZero: true, ticks: { color: chartText, font: { size: 13, family: chartFont } }, grid: { color: theme.getPropertyValue('--border').trim() } },
        x: { ticks: { color: chartText, font: { size: 13, family: chartFont } }, grid: { display: false } },
      },
      ...opts,
    },
  });
}

const PALETTE = Array.from({length:9}, (_,i) => theme.getPropertyValue(`--chart-${i+1}`).trim());

// ============== Init metadata ==============
async function loadMetadata() {
  const [nam, loaiKh, mh, tinh] = await Promise.all([
    api("/api/metadata/nam"),
    api("/api/metadata/loai-kh"),
    api("/api/metadata/mat-hang"),
    api("/api/metadata/tinh"),
  ]);
  ["ds-nam", "tk-nam"].forEach(id => {
    const sel = el(id); nam.forEach(n => sel.appendChild(mkOption(n)));
  });
  loaiKh.forEach(v => el("ds-loai-kh").appendChild(mkOption(v)));
  mh.forEach(m => {
    el("ds-mh").appendChild(mkOption(m.mh_key, m.mo_ta));
    el("tk-mh").appendChild(mkOption(m.mh_key, m.mo_ta));
  });
  tinh.forEach(v => el("tk-tinh").appendChild(mkOption(v)));
  el("kpi-namso").textContent = `${Math.min(...nam)} – ${Math.max(...nam)}`;
}

// ============== Dashboard ==============
async function loadDashboard() {
  const [tongDs, tongTk, dsNam, dsLoaiKh, tkTinh, dx] = await Promise.all([
    api("/api/doanh-so/tong"),
    api("/api/ton-kho/tong"),
    api("/api/doanh-so?nhom=nam"),
    api("/api/doanh-so?nhom=loai_kh"),
    api("/api/ton-kho?nhom=tinh"),
    api("/api/olap/drill-across?nhom=nam"),
  ]);

  el("kpi-doanhthu").textContent = fmtMoney(tongDs.tong_doanh_thu);
  el("kpi-soluong").textContent = fmtNum(tongDs.tong_so_luong);
  el("kpi-tonkho").textContent = fmtNum(tongTk.tong_ton_kho);
  buildTable(el("tb-overview"), dsNam.data, [{key:"nam",label:"Năm"},{key:"tong_so_luong",label:"Số lượng bán",fmt:fmtNum},{key:"tong_doanh_thu",label:"Doanh thu",fmt:fmtMoney}]);

  chart("ch-doanhthu-nam", "bar",
    dsNam.data.map(r => r.nam),
    [{ label: "Doanh thu (₫)", data: dsNam.data.map(r => r.tong_doanh_thu), backgroundColor: PALETTE[0] }]);

  chart("ch-drillacross", "line",
    dx.map(r => r.nam),
    [
      { label: "Doanh thu", data: dx.map(r => r.tong_doanh_thu), borderColor: PALETTE[0], backgroundColor: PALETTE[0]+"33", tension: 0.3, yAxisID: "y" },
      { label: "Tồn kho", data: dx.map(r => r.tong_ton_kho), borderColor: PALETTE[2], backgroundColor: PALETTE[2]+"33", tension: 0.3, yAxisID: "y1" },
    ],
    {
      scales: {
        y: { beginAtZero: true, position: "left", title: { display: true, text: "Doanh thu" } },
        y1: { beginAtZero: true, position: "right", grid: { drawOnChartArea: false }, title: { display: true, text: "Tồn kho" } },
      },
    });

  chart("ch-loaikh", "doughnut",
    dsLoaiKh.data.map(r => r.loai_kh),
    [{ data: dsLoaiKh.data.map(r => r.tong_doanh_thu), backgroundColor: PALETTE }]);

  chart("ch-tonkho-tinh", "bar",
    tkTinh.data.map(r => r.bang),
    [{ label: "Tồn kho", data: tkTinh.data.map(r => r.tong_ton_kho), backgroundColor: PALETTE[0] }],
    { indexAxis: "y" });
}

// ============== Sales Cube tab ==============
function buildTable(tableEl, rows, columns) {
  const thead = tableEl.querySelector("thead");
  const tbody = tableEl.querySelector("tbody");
  thead.innerHTML = "<tr>" + columns.map(c => `<th scope="col"${c.fmt ? ' class="numeric"' : ''}>${c.label}</th>`).join("") + "</tr>";
  if (!rows.length) {
    tbody.innerHTML = `<tr><td colspan="${columns.length}" class="empty">Không có dữ liệu</td></tr>`;
    return;
  }
  tbody.innerHTML = rows.map(r =>
    "<tr data-row='" + JSON.stringify(r).replace(/'/g, "&apos;") + "'>" +
    columns.map(c => `<td data-label="${c.label}"${c.fmt ? ' class="numeric"' : ''}>${c.fmt ? c.fmt(r[c.key]) : (r[c.key] ?? "")}</td>`).join("") +
    "</tr>"
  ).join("");
}

// ============== Axis state (Sales + Inventory) ==============
const axisState = {
  ds: { time: "none", mh: "none", kh: "none" },
  tk: { time: "none", mh: "none", loc: "none" },
};

// Map axis value → cột hiển thị bảng
const COL_LABEL = {
  nam: { key: "nam", label: "Năm" },
  quy: { key: "quy", label: "Quý" },
  thang: { key: "thang", label: "Tháng" },
  mh_key: { key: "mh_key", label: "Mã mặt hàng" },
  mo_ta: { key: "mo_ta", label: "Mô tả" },
  kich_co: { key: "kich_co", label: "Kích cỡ" },
  gia: { key: "gia", label: "Giá", fmt: fmtMoney },
  loai_kh: { key: "loai_kh", label: "Loại khách hàng" },
  kh_key: { key: "kh_key", label: "Mã khách hàng" },
  ten: { key: "ten", label: "Khách hàng" },
  bang: { key: "bang", label: "Bang" },
  ten_tp: { key: "ten_tp", label: "Thành phố" },
  ch_key: { key: "ch_key", label: "Cửa hàng" },
};

// Predict cuboid name + lattice level từ state (mirror backend)
function previewDs(s) {
  const parts = [];
  if (s.time !== "none") parts.push(s.time);
  if (s.mh === "mh") parts.push("mh");
  if (s.kh !== "none") parts.push(s.kh);
  const lattice = parts.length;
  const table = parts.length === 0 ? "olap_ds_all" : "olap_ds_" + parts.join("_");
  return { table, lattice };
}
function previewTk(s) {
  const parts = [];
  if (s.time !== "none") parts.push(s.time);
  if (s.mh === "mh") parts.push("mh");
  if (s.loc !== "none") parts.push(s.loc);
  const lattice = parts.length;
  const table = parts.length === 0 ? "olap_tk_all" : "olap_tk_" + parts.join("_");
  return { table, lattice };
}

const HINTS = {
  0: "Tổng hợp toàn bộ dữ liệu, không phân nhóm.",
  1: "Phân nhóm theo một chiều dữ liệu.",
  2: "Phân nhóm theo hai chiều dữ liệu kết hợp.",
  3: "Phân nhóm theo cả ba chiều dữ liệu.",
};

// Tính trước cột dim_cols mà cuboid sẽ có (mirror backend) → dùng show/hide filter
function predictDsCols(s) {
  const cols = [];
  if (s.time === "nam") cols.push("nam");
  else if (s.time === "quy") cols.push("nam", "quy");
  else if (s.time === "thang") cols.push("nam", "quy", "thang");
  if (s.mh === "mh") cols.push("mh_key", "mo_ta");
  if (s.kh === "loai_kh") cols.push("loai_kh");
  else if (s.kh === "kh") cols.push("kh_key", "ten", "loai_kh");
  return cols;
}
function predictTkCols(s) {
  const cols = [];
  if (s.time === "nam") cols.push("nam");
  else if (s.time === "quy") cols.push("nam", "quy");
  else if (s.time === "thang") cols.push("nam", "quy", "thang");
  if (s.mh === "mh") cols.push("mh_key", "mo_ta");
  if (s.loc === "tinh") cols.push("bang");
  else if (s.loc === "tp") cols.push("bang", "ten_tp");
  else if (s.loc === "ch") cols.push("ch_key");
  return cols;
}

// Show/hide filter fields theo cột thực có của cuboid hiện tại
function syncFilterVisibility(cube) {
  const cols = cube === "ds" ? predictDsCols(axisState.ds) : predictTkCols(axisState.tk);
  const tabEl = el("tab-" + (cube === "ds" ? "sales" : "inventory"));
  tabEl.querySelectorAll(".filter-bar .field[data-need]").forEach(f => {
    const need = f.dataset.need;
    const ok = cols.includes(need);
    f.style.display = ok ? "" : "none";
    if (!ok) {
      // reset value khi field bị ẩn để tránh filter "ma"
      const sel = f.querySelector("select"); if (sel) sel.value = "";
    }
  });
}

function refreshAxisPreview(cube) {
  const s = axisState[cube];
  const { table, lattice } = cube === "ds" ? previewDs(s) : previewTk(s);
  el(`${cube}-cuboid`).textContent = table;
  el(`${cube}-lattice`).textContent = lattice + "D";
  el(`${cube}-hint`).textContent = HINTS[lattice];
  syncFilterVisibility(cube);
}

// Bind segment clicks
document.querySelectorAll(".seg").forEach(seg => {
  const cube = seg.dataset.cube;
  const axis = seg.dataset.axis;
  seg.querySelectorAll(".seg-item").forEach(btn => {
    btn.addEventListener("click", () => {
      seg.querySelectorAll(".seg-item").forEach(b => b.classList.remove("active"));
      btn.classList.add("active");
      axisState[cube][axis] = btn.dataset.val;
      refreshAxisPreview(cube);
    });
  });
});

// ============== Sales Cube ==============
async function runDoanhSo() {
  const s = axisState.ds;
  const params = new URLSearchParams({
    time_axis: s.time, mh_axis: s.mh, kh_axis: s.kh,
  });
  const ln = el("ds-nam").value; if (ln) params.set("loc_nam", ln);
  const lq = el("ds-quy").value; if (lq) params.set("loc_quy", lq);
  const lt = el("ds-thang").value; if (lt) params.set("loc_thang", lt);
  const lk = el("ds-loai-kh").value; if (lk) params.set("loc_loai_kh", lk);
  const lm = el("ds-mh").value; if (lm) params.set("loc_mh", lm);

  let res;
  try {
    res = await api("/api/doanh-so/v2?" + params);
  } catch (e) {
    alert("Cuboid không tồn tại với tổ hợp này.\n" + e.message);
    return;
  }
  el("ds-cuboid").textContent = res.cuboid;
  el("ds-lattice").textContent = res.lattice + "D";
  el("ds-hint").textContent = HINTS[res.lattice];

  const dimCols = res.dim_cols.map(k => COL_LABEL[k] || { key: k, label: k });
  const cols = [
    ...dimCols,
    { key: "tong_so_luong", label: "Số lượng", fmt: fmtNum },
    { key: "tong_doanh_thu", label: "Doanh thu", fmt: fmtMoney },
  ];
  buildTable(el("tb-ds"), res.data, cols);

  // Chart: nếu 0D, hiện 1 cột tổng; nếu nhiều dim, ghép label
  const labels = res.lattice === 0
    ? ["Tổng"]
    : res.data.map(r => dimCols.map(c => r[c.key]).join(" / "));
  chart("ch-ds", "bar", labels,
    [{ label: "Doanh thu", data: res.data.map(r => r.tong_doanh_thu), backgroundColor: PALETTE[0] }],
    { indexAxis: labels.length > 12 ? "y" : "x" });

  el("tb-ds").querySelectorAll("tbody tr").forEach(tr => {
    tr.addEventListener("click", () => {
      if (!tr.dataset.row) return;
      const r = JSON.parse(tr.dataset.row.replace(/&apos;/g, "'"));
      const p = new URLSearchParams();
      if (r.kh_key) p.set("kh_key", r.kh_key);
      if (r.mh_key) p.set("mh_key", r.mh_key);
      for (const [field, input] of [["nam", "ds-nam"], ["quy", "ds-quy"], ["thang", "ds-thang"], ["loai_kh", "ds-loai-kh"], ["mh_key", "ds-mh"]]) {
        const value = r[field] ?? el(input).value;
        if (value !== "" && value != null) p.set(field, value);
      }
      openDrillThrough(p);
    });
  });
}

el("ds-run").addEventListener("click", runDoanhSo);
el("ds-reset").addEventListener("click", () => {
  el("ds-nam").value = ""; el("ds-quy").value = ""; el("ds-thang").value = "";
  el("ds-loai-kh").value = ""; el("ds-mh").value = "";
  ["time", "mh", "kh"].forEach(ax => {
    axisState.ds[ax] = "none";
    document.querySelectorAll(`.seg[data-cube="ds"][data-axis="${ax}"] .seg-item`).forEach(b => {
      b.classList.toggle("active", b.dataset.val === "none");
    });
  });
  refreshAxisPreview("ds");
  runDoanhSo();
});

// ============== Inventory Cube ==============
async function runTonKho() {
  const s = axisState.tk;
  const params = new URLSearchParams({
    time_axis: s.time, mh_axis: s.mh, loc_axis: s.loc,
  });
  const ln = el("tk-nam").value; if (ln) params.set("loc_nam", ln);
  const lq = el("tk-quy").value; if (lq) params.set("loc_quy", lq);
  const lth = el("tk-thang").value; if (lth) params.set("loc_thang", lth);
  const lt = el("tk-tinh").value; if (lt) params.set("loc_bang", lt);
  const lm = el("tk-mh").value; if (lm) params.set("loc_mh", lm);

  let res;
  try {
    res = await api("/api/ton-kho/v2?" + params);
  } catch (e) {
    alert("Cuboid không tồn tại với tổ hợp này.\n" + e.message);
    return;
  }
  el("tk-cuboid").textContent = res.cuboid;
  el("tk-lattice").textContent = res.lattice + "D";
  el("tk-hint").textContent = HINTS[res.lattice];

  const dimCols = res.dim_cols.map(k => COL_LABEL[k] || { key: k, label: k });
  const cols = [...dimCols, { key: "tong_ton_kho", label: "Tồn kho", fmt: fmtNum }];
  buildTable(el("tb-tk"), res.data, cols);

  const labels = res.lattice === 0
    ? ["Tổng"]
    : res.data.map(r => dimCols.map(c => r[c.key]).join(" / "));
  chart("ch-tk", "bar", labels,
    [{ label: "Tồn kho", data: res.data.map(r => r.tong_ton_kho), backgroundColor: PALETTE[0] }],
    { indexAxis: labels.length > 12 ? "y" : "x" });
}

el("tk-run").addEventListener("click", runTonKho);
el("tk-reset").addEventListener("click", () => {
  el("tk-nam").value = ""; el("tk-quy").value = ""; el("tk-thang").value = "";
  el("tk-tinh").value = ""; el("tk-mh").value = "";
  ["time", "mh", "loc"].forEach(ax => {
    axisState.tk[ax] = "none";
    document.querySelectorAll(`.seg[data-cube="tk"][data-axis="${ax}"] .seg-item`).forEach(b => {
      b.classList.toggle("active", b.dataset.val === "none");
    });
  });
  refreshAxisPreview("tk");
  runTonKho();
});

// ============== OLAP operations ==============
function tableFromArray(rows) {
  if (!rows || !rows.length) return "<div class='empty'>Không có dữ liệu</div>";
  const keys = Object.keys(rows[0]);
  return "<table><thead><tr>" + keys.map(k => `<th>${k}</th>`).join("") +
    "</tr></thead><tbody>" + rows.map(r =>
      "<tr>" + keys.map(k => {
        const v = r[k];
        return `<td>${typeof v === "number" ? fmtNum(v) : (v ?? "")}</td>`;
      }).join("") + "</tr>"
    ).join("") + "</tbody></table>";
}

// Keep selectors within the combinations implemented by the API.
function syncOlapControls() {
  const sliceCube = document.querySelector('[data-sl="cube"]');
  const sliceAxis = document.querySelector('[data-sl="chieu"]');
  const allowed = sliceCube.value === 'ds' ? ['nam','loai_kh','mh'] : ['nam','bang'];
  for (const option of sliceAxis.options) {
    option.hidden = option.disabled = !allowed.includes(option.value);
  }
  if (!allowed.includes(sliceAxis.value)) sliceAxis.value = 'nam';
  const row = document.querySelector('[data-pv="hang"]');
  const column = document.querySelector('[data-pv="cot"]');
  const columns = row.value === 'nam' ? ['loai_kh','mh'] : ['nam'];
  for (const option of column.options) {
    option.hidden = option.disabled = !columns.includes(option.value);
  }
  if (!columns.includes(column.value)) column.value = columns[0];
  const diceCube = document.querySelector('[data-di="cube"]');
  const customerType = document.querySelector('[data-di="loai_kh"]');
  customerType.disabled = diceCube.value !== 'ds';
  customerType.closest('.field').hidden = customerType.disabled;
  window.upgradeSelects?.();
}
for (const selector of ['[data-sl="cube"]','[data-pv="hang"]','[data-di="cube"]']) {
  document.querySelector(selector).addEventListener('change', syncOlapControls);
}
syncOlapControls();

async function runRollup() {
  const cube = document.querySelector('[data-rl="cube"]').value;
  const lvl = document.querySelector('[data-rl="len"]').value;
  const res = await api(`/api/olap/roll-up?cube=${cube}&tu=thang&len=${lvl}`);
  el("r-rollup").innerHTML = `<span class="cuboid-tag">${res.cuboid}</span>` + tableFromArray(res.data);
}

async function runDrilldown() {
  const cube = document.querySelector('[data-dd="cube"]').value;
  const xuong = document.querySelector('[data-dd="xuong"]').value;
  const nam = document.querySelector('[data-dd="nam"]').value;
  let url = `/api/olap/drill-down?cube=${cube}&xuong=${xuong}`;
  if (nam) url += `&loc_nam=${nam}`;
  const res = await api(url);
  el("r-drilldown").innerHTML = `<span class="cuboid-tag">${res.cuboid}</span>` + tableFromArray(res.data);
}

async function runSlice() {
  const cube = document.querySelector('[data-sl="cube"]').value;
  const chieu = document.querySelector('[data-sl="chieu"]').value;
  const giaTri = document.querySelector('[data-sl="gia_tri"]').value;
  if (!giaTri) return alert("Nhập giá trị slice");
  const res = await api(`/api/olap/slice?cube=${cube}&chieu=${chieu}&gia_tri=${encodeURIComponent(giaTri)}`);
  el("r-slice").innerHTML = `<span class="cuboid-tag">${res.cuboid}</span>` + tableFromArray(res.data);
}

async function runDice() {
  const cube = document.querySelector('[data-di="cube"]').value;
  const nhom = document.querySelector('[data-di="nhom"]').value;
  const nam = document.querySelector('[data-di="nam"]').value;
  const lk = document.querySelector('[data-di="loai_kh"]').value;
  let url = `/api/olap/dice?cube=${cube}&nhom=${nhom}`;
  if (nam) url += `&loc_nam=${nam}`;
  if (cube === "ds" && lk) url += `&loc_loai_kh=${encodeURIComponent(lk)}`;
  const res = await api(url);
  el("r-dice").innerHTML = `<span class="cuboid-tag">${res.cuboid}</span>` + tableFromArray(res.data);
}

async function runPivot() {
  const hang = document.querySelector('[data-pv="hang"]').value;
  const cot = document.querySelector('[data-pv="cot"]').value;
  if (hang === cot) return alert("Hàng và cột phải khác nhau");
  const res = await api(`/api/olap/pivot?cube=ds&hang=${hang}&cot=${cot}`);
  let html = "<table><thead><tr><th>" + ({nam:"Năm",loai_kh:"Loại khách hàng",mh:"Mặt hàng"}[hang]) + " / " + ({nam:"Năm",loai_kh:"Loại khách hàng",mh:"Mặt hàng"}[cot]) + "</th>";
  res.labels_cot.forEach(c => html += `<th>${c}</th>`);
  html += "</tr></thead><tbody>";
  res.labels_hang.forEach((h, i) => {
    html += `<tr><th>${h}</th>` + res.matrix[i].map(v => `<td>${fmtNum(v)}</td>`).join("") + "</tr>";
  });
  html += "</tbody></table>";
  el("r-pivot").innerHTML = html;
}

async function runDrillAcross() {
  const nhom = document.querySelector('[data-da="nhom"]').value;
  const data = await api(`/api/olap/drill-across?nhom=${nhom}`);
  el("r-drillacross").innerHTML = tableFromArray(data);
}

async function runDrillThrough() {
  const params = new URLSearchParams();
  ["kh_key", "mh_key", "nam"].forEach(k => {
    const v = document.querySelector(`[data-dt="${k}"]`).value;
    if (v) params.set(k, v);
  });
  await openDrillThrough(params);
}

// ============== Drill-through modal ==============
async function openDrillThrough(params) {
  el("modal").classList.add("show");
  el("modal-body").innerHTML = "<div class='loading'>Đang tải giao dịch gốc...</div>";
  try {
    const data = await api("/api/olap/drill-through?" + params.toString());
    el("modal-title").textContent = `Drill-through · ${data.length} giao dịch`;
    el("modal-body").innerHTML = tableFromArray(data);
    // copy result to OLAP card too (if triggered from there)
    const r = el("r-drillthrough");
    if (r) r.innerHTML = tableFromArray(data.slice(0, 50));
  } catch (e) {
    el("modal-body").innerHTML = `<div class="empty">Lỗi: ${e.message}</div>`;
  }
}
function closeModal() { el("modal").classList.remove("show"); }
el("modal").addEventListener("click", (e) => { if (e.target === el("modal")) closeModal(); });

// ============== Boot ==============
(async function () {
  try {
    await loadMetadata();
    await loadDashboard();
    // Khởi đầu Sales ở 1D-Năm và Inventory ở 1D-Tỉnh để chart có gì để hiển thị
    axisState.ds.time = "nam";
    document.querySelector('.seg[data-cube="ds"][data-axis="time"] .seg-item[data-val="nam"]').click();
    axisState.tk.loc = "tinh";
    document.querySelector('.seg[data-cube="tk"][data-axis="loc"] .seg-item[data-val="tinh"]').click();
    await runDoanhSo();
    await runTonKho();
    window.upgradeSelects?.();
  } catch (e) {
    console.error(e);
    el("app-error").hidden=false; el("app-error-detail").textContent="Không tải được dữ liệu. Kiểm tra kết nối CSDL rồi tải lại trang.";
  }
})();

const initialTab=location.hash.slice(1);
if(initialTab && document.querySelector(`.nav-item[data-tab="${initialTab}"]`)) document.querySelector(`.nav-item[data-tab="${initialTab}"]`).click();
// Overview and sales share the same drill-through action.
el('tb-overview').addEventListener('click',event=>{const row=event.target.closest('tr[data-row]');if(!row)return;const data=JSON.parse(row.dataset.row);openDrillThrough(new URLSearchParams({nam:data.nam}));});
