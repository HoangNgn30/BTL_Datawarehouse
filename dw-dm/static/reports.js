const REPORTS = [
 {n:1,t:"Danh sách cửa hàng, địa điểm, số điện thoại và thông tin mặt hàng đang lưu trữ.", p:[["ch","cua_hang","ch_key","Tất cả cửa hàng"]]},
 {n:2,t:"Danh sách đơn đặt hàng, khách hàng và ngày đặt theo khách hàng đã chọn.", p:[["kh","khach_hang","kh_key"]]},
 {n:3,t:"Các cửa hàng có bán mặt hàng mà khách hàng đã đặt, kèm thành phố và số điện thoại.", p:[["kh","khach_hang","kh_key"]]},
 {n:4,t:"Văn phòng đại diện của các cửa hàng có lượng tồn mặt hàng vượt ngưỡng đã chọn.", p:[["mh","mat_hang","mh_key"],["muc","num",null,"100"]]},
 {n:5,t:"Mặt hàng trong đơn, cửa hàng cấp hàng và các cửa hàng có bán mặt hàng đó.", p:[["ma_don","don_hang",null]]},
 {n:6,t:"Thành phố và bang nơi khách hàng đã chọn sinh sống.", p:[["kh","khach_hang","kh_key"]]},
 {n:7,t:"Lượng tồn của mặt hàng tại các cửa hàng trong thành phố đã chọn.", p:[["mh","mat_hang","mh_key"],["tp","thanh_pho","vp_key"]]},
 {n:8,t:"Chi tiết mặt hàng, số lượng, khách hàng và cửa hàng đáp ứng của đơn đã chọn.", p:[["ma_don","don_hang",null]]},
 {n:9,t:"Danh sách khách hàng theo loại: du lịch, bưu điện hoặc thuộc cả hai loại.", p:[["loai","enum",null]]},
];
const ENUM9=[["du_lich","Khách hàng du lịch"],["buu_dien","Khách hàng bưu điện"],["ca_hai","Thuộc cả hai loại"]];const TITLES=['Cửa hàng và mặt hàng','Đơn đặt hàng','Nơi bán mặt hàng đã đặt','Tồn kho vượt ngưỡng','Phân bổ đơn hàng','Địa chỉ khách hàng','Tồn kho thành phố','Chi tiết đơn hàng','Phân loại khách hàng'];
const PARAM_LABEL={ch:'Cửa hàng',kh:'Khách hàng',mh:'Mặt hàng',muc:'Mức tồn kho',ma_don:'Đơn hàng',tp:'Thành phố',loai:'Loại khách hàng'};
const COLUMNS={ma_don:'Mã đơn',kh_key:'Mã khách hàng',ten:'Khách hàng',ngay:'Ngày đặt',ch_key:'Cửa hàng',ten_tp:'Thành phố',bang:'Bang',so_dt:'Điện thoại',mh_key:'Mã mặt hàng',mo_ta:'Mô tả',kich_co:'Kích cỡ',trong_luong:'Trọng lượng',gia:'Đơn giá',dia_chi_vp:'Địa chỉ văn phòng',so_luong:'Số lượng đặt',so_luong_cap:'Số lượng cấp',gia_dat:'Giá đặt',khach_hang:'Khách hàng',ton_kho:'Tồn kho',loai_kh:'Loại khách hàng',huong_dan_vien:'Hướng dẫn viên',dia_chi_buu_dien:'Địa chỉ bưu điện',ch_dap_ung:'Cửa hàng cấp',tp_dap_ung:'Thành phố cấp',ch_co_ban:'Cửa hàng có bán',tp_ch_co_ban:'Thành phố có bán'};
const escapeHTML=value=>String(value??'').replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
let META={},selected=2,requestId=0;
function options(list,key){return list.map(x=>{const value=typeof x==='object'?x[key]:x;const label=typeof x==='object'?(x.ten||x.mo_ta||x.ten_tp):'';return `<option value="${escapeHTML(value)}">${escapeHTML(value)}${label?' — '+escapeHTML(label):''}</option>`;}).join('');}
function renderReport(number){
 selected=number;requestId++;
 const report=REPORTS.find(x=>x.n===number);
 document.querySelectorAll('[data-report]').forEach(button=>{const active=Number(button.dataset.report)===number;button.classList.toggle('active',active);button.setAttribute('aria-current',active?'page':'false');});
 document.getElementById('report-panel').innerHTML=`<div class="report-heading"><h2>${escapeHTML(TITLES[number-1])}</h2><p class="sub">Yêu cầu ${number}. ${escapeHTML(report.t)}</p></div><form class="card filters" id="report-form">`+report.p.map(([name,source,key,extra])=>`<div class="field"><label for="p${number}_${name}">${PARAM_LABEL[name]}</label>`+(source==='num'?`<input id="p${number}_${name}" type="number" value="${extra}" required>`:`<select id="p${number}_${name}">`+(source==='enum'?ENUM9.map(x=>`<option value="${x[0]}">${x[1]}</option>`).join(''):(name==='ch'?'<option value="">Tất cả cửa hàng</option>':'')+options(META[source]||[],key))+'</select>')+'</div>').join('')+'<button class="primary" type="submit">Xem báo cáo</button></form><div class="card" id="report-result"><div class="empty">Chọn điều kiện và nhấn Xem báo cáo.</div></div>';
 document.getElementById('report-form').onsubmit=e=>{e.preventDefault();runReport(number);};window.upgradeSelects?.();
}
async function runReport(number){
 const report=REPORTS.find(x=>x.n===number),params=new URLSearchParams();
 report.p.forEach(([name])=>{const value=document.getElementById(`p${number}_${name}`).value;if(value!=='')params.set(name,value);});
 const ticket=++requestId,box=document.getElementById('report-result'),button=document.querySelector('#report-form button[type=submit]');button.disabled=true;button.textContent='Đang tải…';box.innerHTML='<div class="loading" role="status">Đang tải kết quả…</div>';
 try{
  const response=await fetch(`/api/bao-cao/${number}?${params}`);if(!response.ok)throw new Error('Không tải được báo cáo. Kiểm tra kết nối dữ liệu rồi thử lại.');const data=await response.json();if(ticket!==requestId)return;
  if(!data.length){box.innerHTML='<div class="empty">Không có kết quả phù hợp. Thử thay đổi điều kiện lọc.</div>';return;}
  const columns=Object.keys(data[0]);box.innerHTML=`<div class="section-heading"><h2>${escapeHTML(TITLES[number-1])}</h2><span class="legend">${data.length.toLocaleString('vi-VN')} dòng</span></div><div class="table-wrap"><table><thead><tr>${columns.map(c=>`<th scope="col">${COLUMNS[c]||escapeHTML(c)}</th>`).join('')}</tr></thead><tbody>`+data.map(row=>'<tr>'+columns.map(c=>`<td data-label="${COLUMNS[c]||escapeHTML(c)}">${escapeHTML(typeof row[c]==='number'?row[c].toLocaleString('vi-VN'):row[c])}</td>`).join('')+'</tr>').join('')+'</tbody></table></div>';
 }catch(error){if(ticket===requestId)box.innerHTML=`<div class="empty" role="alert">${escapeHTML(error.message)}</div>`;}
 finally{if(ticket===requestId){button.disabled=false;button.textContent='Xem báo cáo';}}
}
(async()=>{try{
 const response=await fetch('/api/bao-cao/meta');if(!response.ok)throw new Error('Không tải được bộ lọc báo cáo. Kiểm tra kết nối dữ liệu rồi tải lại trang.');META=await response.json();
 document.getElementById('report-nav').innerHTML=TITLES.map((name,i)=>`<button type="button" data-report="${i+1}">${i+1}. ${name}</button>`).join('');document.querySelectorAll('[data-report]').forEach(button=>button.onclick=()=>renderReport(Number(button.dataset.report)));renderReport(selected);
 }catch(error){document.getElementById('report-panel').innerHTML=`<div class="card empty" role="alert">${escapeHTML(error.message)}</div>`;}})();
