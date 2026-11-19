// Deterministic response-order and exact-money regressions; no browser or DB needed.
const fs=require('node:fs'),vm=require('node:vm'),assert=require('node:assert/strict'),path=require('node:path');
const root=path.resolve(__dirname,'../dw-dm/static');
const source=fs.readFileSync(path.join(root,'olap.js'),'utf8');
async function responseOrder(cube){
  const name=cube==='ds'?'runDoanhSo':'runTonKho';
  const start=source.indexOf(`async function ${name}() {`);
  const end=source.indexOf(`el("${cube}-run").addEventListener`,start);
  const nodes={};
  for(const field of ['nam','quy','thang','loai-kh','mh','tinh','cuboid','lattice','hint'])nodes[`${cube}-${field}`]={value:'',textContent:''};
  nodes[`tb-${cube}`]={querySelectorAll:()=>[]};
  let renders=[],pending=[],alerts=[];
  const ctx={URLSearchParams,salesRequestId:0,inventoryRequestId:0,axisState:{[cube]:{time:'nam',mh:'none',kh:'none',loc:'none'}},el:id=>nodes[id],api:url=>new Promise((resolve,reject)=>pending.push({url,resolve,reject})),HINTS:{1:'year'},rowCountNote:()=>'',chartRows:res=>res.data,COL_LABEL:{nam:{key:'nam',label:'Year'}},fmtNum:String,fmtMoney:String,buildTable:(_,rows)=>renders.push(rows[0].nam),chart:()=>{},PALETTE:['purple'],alert:value=>alerts.push(value)};
  vm.runInNewContext(source.slice(start,end),ctx);
  const response=year=>({cuboid:`olap_${cube}_nam`,lattice:1,dim_cols:['nam'],data:[{nam:year,tong_so_luong:1,tong_doanh_thu:'100.00',tong_ton_kho:1}]});
  nodes[`${cube}-nam`].value='2022';const old=ctx[name]();
  nodes[`${cube}-nam`].value='2023';const recent=ctx[name]();
  pending[1].resolve(response(2023));await recent;pending[0].resolve(response(2022));await old;
  assert.deepEqual(renders,[2023],`${name}: an older response overwrote the latest result`);
  nodes[`${cube}-nam`].value='2022';const oldFailure=ctx[name]();
  nodes[`${cube}-nam`].value='2023';const latest=ctx[name]();
  pending[3].resolve(response(2023));await latest;pending[2].reject(new Error('old error'));await oldFailure;
  assert.equal(alerts.length,0,`${name}: stale errors must not interrupt the latest request`);
}
(async()=>{
  await responseOrder('ds');await responseOrder('tk');
  const ctx={window:{}};vm.runInNewContext(fs.readFileSync(path.join(root,'format.js'),'utf8'),ctx);
  assert.equal(ctx.window.formatMoney('9999999999999999.99'),'9.999.999.999.999.999,99 ₫');
  assert.equal(ctx.window.formatMoney('0.00'),'0 ₫');
  assert.equal(ctx.window.formatMoney(null),'—');
  assert.equal(ctx.window.formatNumber('2.500'),'2,5');
  console.log('UI regressions passed: sales/inventory out-of-order responses and stale errors; exact money, zero and missing values');
})().catch(error=>{console.error(error);process.exitCode=1;});
