/* Shared accessible shell; selects retain their original values and event bindings. */
(() => {
  let popup=null, trigger=null;
  const close=()=>{popup?.remove();popup=null;trigger?.setAttribute('aria-expanded','false');trigger=null;};
  function open(select,button){
    if(trigger===button){close();return;}close();trigger=button;
    button.setAttribute('aria-expanded','true');
    popup=document.createElement('div');popup.className='select-popup scrollbar-clean';popup.setAttribute('role','listbox');popup.setAttribute('aria-label',button.getAttribute('aria-label'));
    const options=[...select.options];
    const render=(query='')=>{
      popup.querySelectorAll('.select-option').forEach(x=>x.remove());
      for(const option of options.filter(x=>!x.hidden&&x.text.toLocaleLowerCase('vi').includes(query.toLocaleLowerCase('vi')))){
        const item=document.createElement('button');item.type='button';item.className='select-option';item.setAttribute('role','option');item.setAttribute('aria-selected',String(option.selected));item.textContent=option.text;item.disabled=option.disabled;
        item.onclick=()=>{select.value=option.value;select.dispatchEvent(new Event('change',{bubbles:true}));close();window.upgradeSelects();button.focus();};popup.appendChild(item);
      }
    };
    if(options.length>12){const input=document.createElement('input');input.type='search';input.className='select-search';input.placeholder='Tìm trong danh sách';input.setAttribute('aria-label','Tìm lựa chọn');input.oninput=()=>render(input.value);popup.appendChild(input);}
    render();document.body.appendChild(popup);
    const rect=button.getBoundingClientRect(),width=Math.min(Math.max(rect.width,220),innerWidth-32);
    popup.style.width=width+'px';popup.style.left=Math.max(16,Math.min(rect.left,innerWidth-width-16))+'px';
    const height=Math.min(popup.scrollHeight,280);
    popup.style.top=(rect.bottom+height+12>innerHeight?Math.max(8,rect.top-height-6):rect.bottom+6)+'px';
    popup.addEventListener('keydown',e=>{if(e.key==='Escape'){close();button.focus();return;}if(['ArrowDown','ArrowUp','Home','End'].includes(e.key)){e.preventDefault();const items=[...popup.querySelectorAll('.select-option:not(:disabled)')],i=items.indexOf(document.activeElement);const next=e.key==='Home'?0:e.key==='End'?items.length-1:e.key==='ArrowDown'?(i+1)%items.length:(i-1+items.length)%items.length;items[next]?.focus();}});
    (popup.querySelector('input')||popup.querySelector('[aria-selected=true]')||popup.querySelector('button'))?.focus();
  }
  window.upgradeSelects=()=>{
    document.querySelectorAll('select').forEach(select=>{
      if(!select.dataset.enhanced){
        select.dataset.enhanced='yes';select.classList.add('native-select');select.tabIndex=-1;select.setAttribute('aria-hidden','true');
        const host=document.createElement('div');host.className='select-host';select.before(host);host.append(select);
        const button=document.createElement('button');button.type='button';button.className='custom-select';button.setAttribute('aria-haspopup','listbox');button.setAttribute('aria-expanded','false');
        const label=document.querySelector(`label[for="${select.id}"]`)?.textContent||select.closest('.field')?.querySelector('label')?.textContent||select.title||'Chọn giá trị';button.setAttribute('aria-label',label.trim());
        const span=document.createElement('span');button.append(span);const arrow=document.createElement('span');arrow.setAttribute('aria-hidden','true');arrow.textContent='⌄';button.append(arrow);host.append(button);
        button.onclick=()=>open(select,button);button.onkeydown=e=>{if(e.key==='ArrowDown'||e.key==='ArrowUp'){e.preventDefault();open(select,button);}};
        select.addEventListener('change',()=>window.upgradeSelects());
      }
      const button=select.parentElement.querySelector('.custom-select');if(!button)return;const text=select.selectedOptions[0]?.text||'Chọn giá trị';if(button.firstElementChild.textContent!==text)button.firstElementChild.textContent=text;button.disabled=select.disabled;
    });
  };
  const syncTables=()=>document.querySelectorAll('table').forEach(table=>{const labels=[...table.querySelectorAll('thead th')].map(x=>x.textContent);table.querySelectorAll('tbody tr').forEach(row=>[...row.children].forEach((cell,i)=>{if(!cell.dataset.label)cell.dataset.label=labels[i]||'';}));});
  const sync=()=>{window.upgradeSelects();syncTables();if(window.lucide&&document.querySelector('i[data-lucide]'))lucide.createIcons();};
  document.querySelector('.mobile-menu')?.addEventListener('click',()=>document.querySelector('.sidebar')?.classList.add('opened'));
  document.querySelector('.mobile-close')?.addEventListener('click',()=>document.querySelector('.sidebar')?.classList.remove('opened'));
  document.addEventListener('click',e=>{if(popup&&!popup.contains(e.target)&&!trigger.contains(e.target))close();setTimeout(window.upgradeSelects,0);});
  document.addEventListener('keydown',e=>{if(e.key==='Escape'){close();document.querySelector('.sidebar')?.classList.remove('opened');document.querySelector('.modal-backdrop')?.classList.remove('show');}});
  window.addEventListener('resize',close);window.addEventListener('scroll',e=>{if(popup&&!popup.contains(e.target))close();},true);
  let timer;document.addEventListener('scroll',e=>{const target=e.target===document?document.documentElement:e.target;target.classList.add('is-scrolling');clearTimeout(timer);timer=setTimeout(()=>target.classList.remove('is-scrolling'),700);},true);
  new MutationObserver(sync).observe(document.body,{childList:true,subtree:true});sync();
})();
