// DOM integration checks; not a substitute for visual/browser QA.
const {JSDOM,ResourceLoader,VirtualConsole}=require('../ui/react-app/node_modules/jsdom');
const assert=require('node:assert/strict');
const base=process.env.UI_BASE_URL||'http://127.0.0.1:8017';
class Assets extends ResourceLoader{fetch(url,options){if(url.endsWith('chart.umd.min.js'))return Promise.resolve(Buffer.from('window.Chart=class {constructor(){} destroy(){}}'));return super.fetch(url,options);}}
async function waitFor(fn,message){const end=Date.now()+90000;while(Date.now()<end){if(fn())return;await new Promise(r=>setTimeout(r,50));}throw new Error(message);}
async function load(path){const errors=[];const vc=new VirtualConsole();vc.on('jsdomError',e=>{if(!e.message.includes('HTMLCanvasElement.prototype.getContext'))errors.push(e.message);});const html=await (await fetch(base+path,{signal:AbortSignal.timeout(30000)})).text();const dom=new JSDOM(html,{url:base+path,resources:new Assets(),runScripts:'dangerously',pretendToBeVisual:true,virtualConsole:vc,beforeParse(w){w.fetch=(url,options)=>fetch(new URL(url,base),options);w.HTMLCanvasElement.prototype.getContext=()=>({});}});return {dom,w:dom.window,d:dom.window.document,errors};}
(async()=>{
console.log('Loading overview DOM');
const a=await load('/');
console.log('Waiting for overview data');
try{
 await waitFor(()=>a.d.querySelector('#tb-ds tbody tr[data-row]'),'Sales boot did not load');
 assert.equal(a.d.querySelector('#kpi-soluong').textContent,'16.500');
 assert.equal(a.d.querySelectorAll('#tb-overview tbody tr').length,3);
 a.d.querySelector('[data-tab=sales]').click();assert(a.d.querySelector('#tab-sales').classList.contains('active'));
 a.d.querySelector('#ds-nam').parentElement.querySelector('.custom-select').click();
 const option=[...a.d.querySelectorAll('.select-option')].find(x=>x.textContent==='2022');assert(option);option.click();
 assert.equal(a.d.querySelector('#ds-nam').value,'2022');a.d.querySelector('#ds-run').click();
 await waitFor(()=>a.d.querySelectorAll('#tb-ds tbody tr').length===1&&a.d.querySelector('#tb-ds tbody tr').textContent.includes('2022'),'Sales filter failed');
 a.d.querySelector('#tb-overview tbody tr td').click();
 await waitFor(()=>a.d.querySelector('.modal-body table tbody tr'),'Drill-through did not load');
 a.d.dispatchEvent(new a.w.KeyboardEvent('keydown',{key:'Escape',bubbles:true}));assert(!a.d.querySelector('#modal').classList.contains('show'));
 a.d.querySelector('.mobile-menu').click();assert(a.d.querySelector('.sidebar').classList.contains('opened'));
 a.d.dispatchEvent(new a.w.KeyboardEvent('keydown',{key:'Escape',bubbles:true}));assert(!a.d.querySelector('.sidebar').classList.contains('opened'));
 const change=(selector,value)=>{const control=a.d.querySelector(selector);control.value=value;control.dispatchEvent(new a.w.Event('change',{bubbles:true}));};
 change('[data-sl="cube"]','tk');
 assert.deepEqual([...a.d.querySelector('[data-sl="chieu"]').options].filter(o=>!o.disabled).map(o=>o.value),['nam','bang']);
 change('[data-sl="cube"]','ds');
 assert(a.d.querySelector('[data-sl="chieu"] option[value="bang"]').disabled);
 change('[data-pv="hang"]','mh');
 assert.equal(a.d.querySelector('[data-pv="cot"]').value,'nam');
 assert(a.d.querySelector('[data-pv="cot"] option[value="loai_kh"]').disabled);
 change('[data-di="cube"]','tk');assert(a.d.querySelector('[data-di="loai_kh"]').disabled);assert.equal(a.w.getComputedStyle(a.d.querySelector('[data-di="loai_kh"]').closest('.field')).display,'none');
 assert.deepEqual(a.errors,[]);console.log('[OK] Overview values/table, sales filter, custom select, drill-through and shell events');
}finally{a.w.close();}
console.log('Loading report DOM');
const b=await load('/bao-cao');
try{
 await waitFor(()=>b.d.querySelector('#report-form'),'Report metadata did not load');
 b.d.querySelector('#report-form button[type=submit]').click();
 await waitFor(()=>b.d.querySelectorAll('#report-result tbody tr').length===5,'Report 2 failed');
 b.d.querySelector('[data-report="9"]').click();
 b.d.querySelector('#p9_loai').parentElement.querySelector('.custom-select').click();
 [...b.d.querySelectorAll('.select-option')].find(x=>x.textContent==='Thuộc cả hai loại').click();
 b.d.querySelector('#report-form button[type=submit]').click();
 await waitFor(()=>b.d.querySelectorAll('#report-result tbody tr').length===50,'Report 9 failed');
 assert.deepEqual(b.errors,[]);console.log('[OK] Report navigation, parameters, report 2 (5 rows), report 9 (50 rows)');
}finally{b.w.close();}
console.log('UI DOM integration passed (charts stubbed; no geometry assertions)');
})().catch(e=>{console.error(e);process.exitCode=1;});
