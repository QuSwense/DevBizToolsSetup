
/**
 * DataGrid - Reusable Enterprise DataGrid Library
 * Features: AJAX loading, sorting, filtering, boxed pagination with ellipsis, tooltips, ARIA, sticky, context menu, mobile cards, expandable rows, selection
 * Zero external dependencies except Bootstrap (for modals/dropdowns) optional
 * 
 * Usage:
 *   const grid = new DataGrid('#gridContainer', {
 *     dataUrl: './employees.json',
 *     columns: [ {key:'id', label:'ID', sortable:true, render:(v,row)=>`#${v}`}, ... ],
 *     detailRenderer: (row)=>`...`,
 *     pageSize: 5,
 *     idField: 'id'
 *   });
 *   grid.init();
 */

class DataGrid {
  constructor(containerSelector, options = {}) {
    this.container = document.querySelector(containerSelector);
    if (!this.container) throw new Error(`DataGrid: container ${containerSelector} not found`);
    
    // Default options - generic, no hardcoded employee fields
    this.options = Object.assign({
      dataUrl: null,
      data: null,
      columns: [], // [{key, label, sortable, render, className, width, tooltip}]
      detailFields: null, // ['email','dept'] or custom renderer
      detailRenderer: null, // (row)=>HTML string
      idField: 'id',
      pageSize: 5,
      pageSizeOptions: [2,5,10,25],
      searchableFields: null, // null = all columns keys
      filterableFields: null, // for advanced filter modal
      selectable: true,
      expandable: true,
      stickyFirst: false,
      tooltips: true,
      contextMenu: true,
      mobileCards: true,
      themeToggle: true,
      aria: true,
      title: 'Data Grid',
      description: '',
      addButton: true,
      toolbar: true,
      onAdd: null,
      onEdit: null,
      onDelete: null,
      onRowClick: null,
      cacheKey: null, // localStorage cache key
    }, options);

    // State - separated from config
    this.state = {
      rawData: [],
      filteredData: [],
      sortedData: [],
      currentPage: 1,
      pageSize: this.options.pageSize,
      sort: { key: null, dir: 'asc' },
      searchText: '',
      advancedFilters: {},
      selectedIds: new Set(),
      expandedIds: new Set(),
      stickyEnabled: localStorage.getItem('dg-sticky-first') === 'true' || this.options.stickyFirst,
      theme: localStorage.getItem('dg-theme') || (window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light'),
    };

    // DOM refs
    this.dom = {};
    this.tooltipEl = null;
    this.contextMenuEl = null;
  }

  // ---------- INIT ----------
  async init() {
    this.renderSkeleton();
    this.bindBaseEvents();
    if (this.options.tooltips) this.initTooltips();
    if (this.options.contextMenu) this.initContextMenu();
    this.applyTheme(this.state.theme);
    this.applyStickyState();
    await this.loadData();
    return this;
  }

  // ---------- DATA LOADING - Separated from rendering ----------
  async loadData() {
    this.setLoading(true);
    try {
      let data = [];
      if (this.options.data && Array.isArray(this.options.data)) {
        data = this.options.data;
      } else if (this.options.dataUrl) {
        const res = await fetch(this.options.dataUrl, { cache: 'no-store' });
        if (!res.ok) throw new Error(`HTTP ${res.status}`);
        const json = await res.json();
        data = Array.isArray(json) ? json : (json.data || json.employees || []);
      }
      if (!Array.isArray(data)) throw new Error('Data must be an array');
      this.state.rawData = data;
      this.state.filteredData = [...data];
      // cache
      if (this.options.cacheKey) {
        try { localStorage.setItem(this.options.cacheKey, JSON.stringify(data)); } catch(e){}
      }
      this.applyFiltersAndSort();
      this.render();
      console.log(`DataGrid: loaded ${data.length} records`);
    } catch (err) {
      console.error('DataGrid load error:', err);
      this.renderError(err);
      // fallback cache
      if (this.options.cacheKey) {
        const cached = localStorage.getItem(this.options.cacheKey);
        if (cached) {
          try {
            const data = JSON.parse(cached);
            this.state.rawData = data;
            this.state.filteredData = [...data];
            this.applyFiltersAndSort();
            this.render();
          } catch(e){}
        }
      }
    } finally {
      this.setLoading(false);
    }
  }

  setLoading(isLoading) {
    if (this.dom.tbody) {
      if (isLoading) {
        this.dom.tbody.innerHTML = `<tr><td colspan="${this.getColSpan()}" style="padding:40px; text-align:center; color:var(--dg-text-soft);"><i class="bi bi-arrow-repeat" style="animation: spin 1s linear infinite; display:inline-block;"></i> Loading...</td></tr>`;
      }
    }
  }

  renderError(err) {
    if (!this.dom.tbody) return;
    this.dom.tbody.innerHTML = `<tr><td colspan="${this.getColSpan()}" style="padding:24px;"><div style="background:var(--dg-surface-2); border:1px solid var(--dg-border); padding:14px;"><div style="font-weight:600;"><i class="bi bi-exclamation-triangle"></i> Failed to load data</div><div style="font-size:12.5px; color:var(--dg-text-soft); margin-top:6px;">${err.message}<br>Serve via HTTP: <code>python -m http.server 8000</code></div></div></td></tr>`;
  }

  // ---------- FILTERING & SORTING - Pure functions, reusable ----------
  applyFiltersAndSort() {
    let data = [...this.state.rawData];

    // Global search
    if (this.state.searchText) {
      const q = this.state.searchText.toLowerCase();
      const fields = this.options.searchableFields || this.options.columns.map(c=>c.key);
      data = data.filter(row => {
        return fields.some(k => {
          const v = this.getNestedValue(row, k);
          return String(v||'').toLowerCase().includes(q);
        });
      });
    }

    // Advanced filters
    Object.entries(this.state.advancedFilters).forEach(([k,v])=>{
      if (!v) return;
      const q = String(v).toLowerCase();
      data = data.filter(row => {
        const rv = this.getNestedValue(row, k);
        return String(rv||'').toLowerCase().includes(q);
      });
    });

    // Sorting
    if (this.state.sort.key) {
      const {key, dir} = this.state.sort;
      data.sort((a,b)=>{
        let av = this.getNestedValue(a, key);
        let bv = this.getNestedValue(b, key);
        if (av==null) av=''; if (bv==null) bv='';
        if (typeof av==='number' && typeof bv==='number') return dir==='asc'?av-bv:bv-av;
        av = String(av).toLowerCase(); bv = String(bv).toLowerCase();
        if (av<bv) return dir==='asc'?-1:1;
        if (av>bv) return dir==='asc'?1:-1;
        return 0;
      });
    }

    this.state.filteredData = data;
    this.state.currentPage = 1;
  }

  // ---------- RENDERING ----------
  renderSkeleton() {
    const id = this.container.id || 'dg';
    this.container.innerHTML = `
      <div class="page-head" style="display:flex; justify-content:space-between; align-items:flex-end; gap:16px; margin-bottom:18px; flex-wrap:wrap;">
        <div><h1 style="font-size:20px; font-weight:600; margin:0;">${this.options.title}</h1><p style="margin:4px 0 0; color:var(--dg-text-soft); font-size:13px;">${this.options.description}</p></div>
        <div style="font-size:12px; color:var(--dg-text-soft);"><span id="${id}-themeLabel" data-tooltip="Current theme" data-tooltip-pos="left">Light mode</span></div>
      </div>
      <div class="datagrid-card" id="${id}-card">
        ${this.options.toolbar ? this.renderToolbarHTML(id) : ''}
        <div id="${id}-filtersBar" class="filters-bar"><div id="${id}-filterBadges" class="d-flex flex-wrap gap-1"></div><button class="btn btn-link p-0 ms-auto text-decoration-none" style="font-size:12.5px;" onclick="document.getElementById('${id}')._gridInstance.resetFilters()">Clear all</button></div>
        <div class="table-wrap" id="${id}-tableWrap">
          <table class="datagrid" id="${id}-table" aria-label="${this.options.title}" aria-describedby="${id}-desc">
            <caption id="${id}-desc" class="visually-hidden">${this.options.description || this.options.title}</caption>
            <thead id="${id}-thead"></thead>
            <tbody id="${id}-tbody"></tbody>
          </table>
        </div>
        <div id="${id}-mobileCards" class="mobile-cards"></div>
        <div class="grid-footer">
          <div class="footer-left"><span>Showing <strong id="${id}-footerCount" aria-live="polite" aria-atomic="true">0</strong></span><span style="width:1px;height:14px;background:var(--dg-border);display:inline-block"></span>
            <label class="rows-select">Rows <select id="${id}-rowsPerPage" aria-label="Rows per page">${this.options.pageSizeOptions.map(v=>`<option value="${v}" ${v===this.state.pageSize?'selected':''}>${v}</option>`).join('')}</select></label>
          </div>
          <nav aria-label="Pagination" class="d-flex align-items-center gap-2 flex-wrap" id="${id}-paginationWrap"><div class="pagination-modern" id="${id}-pagination" role="group" aria-label="Page navigation"></div></nav>
        </div>
      </div>
      <div id="${id}-tooltip" role="tooltip" style="position:fixed; z-index:10000; pointer-events:none; opacity:0; transform:translateY(4px); transition:opacity .14s ease, transform .14s ease; max-width:280px; background:var(--dg-primary); color:var(--dg-primary-text); border:1px solid var(--dg-primary); padding:6px 8px; font-size:11.5px; font-weight:500; line-height:1.4; box-shadow:var(--dg-shadow-md); white-space:nowrap;"></div>
      <div id="${id}-contextMenu" role="menu" aria-label="Row actions" style="position:fixed; min-width:220px; background:var(--dg-surface); border:1px solid var(--dg-border); box-shadow:var(--dg-shadow-md); z-index:9999; display:none; padding:4px;"></div>
    `;
    // Store refs
    this.dom = {
      card: document.getElementById(`${id}-card`),
      thead: document.getElementById(`${id}-thead`),
      tbody: document.getElementById(`${id}-tbody`),
      pagination: document.getElementById(`${id}-pagination`),
      footerCount: document.getElementById(`${id}-footerCount`),
      rowsPerPage: document.getElementById(`${id}-rowsPerPage`),
      filtersBar: document.getElementById(`${id}-filtersBar`),
      filterBadges: document.getElementById(`${id}-filterBadges`),
      searchInput: document.getElementById(`${id}-search`),
      searchWrap: document.getElementById(`${id}-searchWrap`),
      showingCount: document.getElementById(`${id}-showingCount`),
      selectedCount: document.getElementById(`${id}-selectedCount`),
      mobileCards: document.getElementById(`${id}-mobileCards`),
      tooltip: document.getElementById(`${id}-tooltip`),
      contextMenu: document.getElementById(`${id}-contextMenu`),
      themeLabel: document.getElementById(`${id}-themeLabel`),
      themeIcon: document.getElementById(`${id}-themeIcon`),
      stickyBtn: document.getElementById(`${id}-stickyBtn`),
      stickyIcon: document.getElementById(`${id}-stickyIcon`),
    };
    // Attach instance to container for inline handlers
    this.container._gridInstance = this;
    this.tooltipEl = this.dom.tooltip;
    this.contextMenuEl = this.dom.contextMenu;
  }

  renderToolbarHTML(id) {
    return `
      <div class="grid-toolbar">
        <div class="toolbar-left">
          <div class="search-box" id="${id}-searchWrap"><i class="bi bi-search" aria-hidden="true"></i><input type="text" id="${id}-search" placeholder="Search..." aria-label="Search"><button class="search-clear" type="button" aria-label="Clear search"><i class="bi bi-x-lg"></i></button></div>
          <div class="meta-group">
            <span class="meta-pill" data-tooltip="Total filtered"><span id="${id}-showingCount" aria-live="polite" aria-atomic="true">0</span> records</span>
            <span class="meta-sep"></span>
            <span class="meta-pill selected" data-tooltip="Selected"><span id="${id}-selectedCount" aria-live="polite" aria-atomic="true">0</span> selected</span>
          </div>
        </div>
        <div class="toolbar-right">
          <button class="btn-dg btn-dg-icon" id="${id}-reloadBtn" type="button" aria-label="Reload data" data-tooltip="Reload from ${this.options.dataUrl||'source'}"><i class="bi bi-cloud-download" aria-hidden="true"></i></button>
          <button class="btn-dg btn-dg-icon" id="${id}-stickyBtn" type="button" aria-label="Toggle sticky first column" aria-pressed="false" data-tooltip="Pin first column"><i class="bi bi-pin-angle" id="${id}-stickyIcon" aria-hidden="true"></i></button>
          <button class="btn-dg btn-dg-icon" type="button" aria-label="Reset all" data-tooltip="Reset filters & sorting" id="${id}-resetBtn"><i class="bi bi-arrow-clockwise" aria-hidden="true"></i></button>
          <button class="btn-dg btn-dg-icon" id="${id}-themeBtn" type="button" aria-label="Toggle theme" data-tooltip="Toggle theme"><i class="bi bi-moon-stars" id="${id}-themeIcon" aria-hidden="true"></i></button>
          ${this.options.addButton ? `<div style="width:1px;height:20px;background:var(--dg-border);margin:0 2px;"></div><button class="btn-dg btn-dg-primary" id="${id}-addBtn" type="button" aria-label="Add new"><i class="bi bi-plus-lg" aria-hidden="true"></i> Add</button>` : ''}
        </div>
      </div>`;
  }

  getColSpan() {
    return this.options.columns.length + (this.options.selectable?1:0) + (this.options.expandable?1:0) + 1; // + actions
  }

  render() {
    this.renderHeader();
    this.renderBody();
    this.renderFooter();
    this.renderMobileCards();
    this.updateCounts();
  }

  renderHeader() {
    if (!this.dom.thead) return;
    let html = '<tr>';
    if (this.options.selectable) {
      html += `<th class="check-cell" scope="col" aria-label="Select all"><input class="form-check-input" type="checkbox" id="${this.container.id}-selectAll" aria-label="Select all visible rows"></th>`;
    }
    if (this.options.expandable) {
      html += `<th class="expand-cell" scope="col" aria-label="Expand"></th>`;
    }
    this.options.columns.forEach(col => {
      const sortable = col.sortable ? 'sortable' : '';
      const ariaSort = this.state.sort.key===col.key ? (this.state.sort.dir==='asc'?'ascending':'descending') : 'none';
      const sortAttr = col.sortable ? `aria-sort="${ariaSort}" data-sort="${col.key}"` : '';
      html += `<th class="${sortable}" scope="col" ${sortAttr} ${col.width?`style="width:${col.width}"`:''} ${col.tooltip?`data-tooltip="${col.tooltip}"`:''}><span class="th-inner">${col.label} ${col.sortable?`<span class="sort-indicator"><i class="bi bi-caret-up-fill ${this.state.sort.key===col.key&&this.state.sort.dir==='asc'?'active':''}"></i><i class="bi bi-caret-down-fill ${this.state.sort.key===col.key&&this.state.sort.dir==='desc'?'active':''}"></i></span>`:''}</span></th>`;
    });
    html += `<th class="text-end" scope="col" style="padding-right:14px;">Actions</th></tr>`;
    this.dom.thead.innerHTML = html;

    // Bind sort events
    this.dom.thead.querySelectorAll('th.sortable').forEach(th=>{
      th.addEventListener('click', ()=>{
        const key = th.getAttribute('data-sort');
        this.sortBy(key);
      });
    });
    // Bind select all
    const selAll = document.getElementById(`${this.container.id}-selectAll`);
    if (selAll) selAll.addEventListener('change', (e)=> this.toggleSelectAll(e.target.checked));
  }

  renderBody() {
    if (!this.dom.tbody) return;
    const start = (this.state.currentPage-1)*this.state.pageSize;
    const end = start + this.state.pageSize;
    const pageData = this.state.filteredData.slice(start, end);

    this.dom.tbody.innerHTML = '';
    if (pageData.length===0) {
      this.dom.tbody.innerHTML = `<tr><td colspan="${this.getColSpan()}" style="padding:32px; text-align:center; color:var(--dg-text-soft);">No records found</td></tr>`;
      return;
    }

    pageData.forEach(row => {
      const {parent, detail} = this.createRowPair(row);
      this.dom.tbody.appendChild(parent);
      this.dom.tbody.appendChild(detail);
    });

    // Re-bind row events
    this.bindRowEvents();
  }

  createRowPair(rowData) {
    const id = this.getNestedValue(rowData, this.options.idField);
    const isSelected = this.state.selectedIds.has(id);
    const isExpanded = this.state.expandedIds.has(id);

    const parent = document.createElement('tr');
    parent.className = `parent-row ${isSelected?'is-selected':''} ${isExpanded?'expanded':''}`;
    parent.setAttribute('role','row');
    parent.setAttribute('aria-selected', isSelected?'true':'false');
    parent.dataset.id = id;
    // Store all searchable values as data attributes for filtering fallback
    Object.keys(rowData).forEach(k=>{
      const v = rowData[k];
      if (typeof v==='string' || typeof v==='number') parent.setAttribute(`data-${k}`, v);
    });

    let cells = '';
    if (this.options.selectable) {
      cells += `<td class="check-cell" role="gridcell"><input class="form-check-input row-select" type="checkbox" ${isSelected?'checked':''} aria-label="Select ${rowData.name||id}" data-id="${id}"></td>`;
    }
    if (this.options.expandable) {
      cells += `<td class="expand-cell" role="gridcell"><button class="btn-expand" aria-label="${isExpanded?'Collapse':'Expand'} details" aria-expanded="${isExpanded?'true':'false'}" aria-controls="detail-${id}" data-tooltip="${isExpanded?'Collapse':'Expand'} details" data-tooltip-pos="right"><i class="bi bi-chevron-right btn-toggle-icon" aria-hidden="true"></i></button></td>`;
    }
    this.options.columns.forEach(col=>{
      const raw = this.getNestedValue(rowData, col.key);
      let rendered = raw;
      if (col.render) rendered = col.render(raw, rowData);
      else if (raw!=null) rendered = String(raw);
      else rendered = '';
      const tooltip = col.tooltip ? `data-tooltip="${typeof col.tooltip==='function'?col.tooltip(raw,rowData):col.tooltip}"` : '';
      cells += `<td class="${col.className||''}" role="gridcell" ${tooltip}>${rendered}</td>`;
    });
    // Actions cell
    cells += `<td class="text-end" role="gridcell" style="padding-right:10px;"><div class="row-actions-wrap"><button class="action-trigger" type="button" aria-label="More actions for ${rowData.name||id}" data-tooltip="More actions"><i class="bi bi-three-dots" aria-hidden="true"></i></button><div class="inline-actions"><button class="ia-btn ia-edit" type="button" aria-label="Edit" data-tooltip="Edit"><i class="bi bi-pencil" aria-hidden="true"></i></button><button class="ia-btn ia-danger" type="button" aria-label="Delete" data-tooltip="Delete"><i class="bi bi-trash" aria-hidden="true"></i></button><button class="ia-btn ia-close" type="button" aria-label="Close" data-tooltip="Close"><i class="bi bi-x-lg" style="font-size:11px" aria-hidden="true"></i></button></div></div></td>`;

    parent.innerHTML = cells;

    const detail = document.createElement('tr');
    detail.className = `detail-row ${isExpanded?'':'d-none'}`;
    detail.id = `detail-${id}`;
    detail.innerHTML = `<td colspan="${this.getColSpan()}"><div class="detail-panel">${this.renderDetail(rowData)}</div></td>`;

    return {parent, detail};
  }

  renderDetail(rowData) {
    if (this.options.detailRenderer) {
      return this.options.detailRenderer(rowData);
    }
    if (this.options.detailFields) {
      const fields = this.options.detailFields;
      let html = '<div class="detail-grid">';
      fields.forEach(k=>{
        const v = this.getNestedValue(rowData, k);
        let display = Array.isArray(v) ? v.map(x=>`<span class="chip">${x}</span>`).join('') : (v||'');
        html += `<div class="detail-item"><label>${k}</label><div class="value">${display}</div></div>`;
      });
      html += '</div>';
      return html;
    }
    // default: show all remaining fields not in columns
    let html = '<div class="detail-grid">';
    Object.entries(rowData).forEach(([k,v])=>{
      if (this.options.columns.some(c=>c.key===k)) return;
      if (k===this.options.idField) return;
      if (k==='initials') return;
      let display = Array.isArray(v) ? v.map(x=>`<span class="chip">${x}</span>`).join('') : String(v||'');
      html += `<div class="detail-item"><label>${k}</label><div class="value">${display}</div></div>`;
    });
    html += '</div>';
    return html;
  }

  renderFooter() {
    const total = this.state.filteredData.length;
    const totalPages = Math.max(1, Math.ceil(total / this.state.pageSize));
    if (this.state.currentPage > totalPages) this.state.currentPage = totalPages;

    // Footer count
    const start = total===0?0:(this.state.currentPage-1)*this.state.pageSize+1;
    const end = Math.min(this.state.currentPage*this.state.pageSize, total);
    if (this.dom.footerCount) this.dom.footerCount.textContent = total===0?'0':`${start}-${end} of ${total}`;
    if (this.dom.showingCount) this.dom.showingCount.textContent = total;
    if (this.dom.selectedCount) this.dom.selectedCount.textContent = this.state.selectedIds.size;

    // Pagination
    if (!this.dom.pagination) return;
    this.dom.pagination.innerHTML = '';
    const createBtn = (label, page, disabled=false, active=false, isIcon=false, tip='') => {
      const btn = document.createElement('button');
      btn.className = 'page-btn' + (active?' active':'');
      btn.disabled = disabled;
      if (active) btn.setAttribute('aria-current','page');
      if (isIcon) btn.innerHTML = label; else btn.textContent = label;
      if (tip) { btn.setAttribute('data-tooltip', tip); btn.setAttribute('data-tooltip-pos','top'); btn.setAttribute('aria-label', tip); }
      else if(!isIcon) btn.setAttribute('aria-label', `Go to page ${page}`);
      btn.addEventListener('click', ()=> this.goToPage(page));
      return btn;
    };
    this.dom.pagination.appendChild(createBtn('<i class="bi bi-chevron-double-left" aria-hidden="true"></i>', 1, this.state.currentPage===1, false, true, 'First page'));
    this.dom.pagination.appendChild(createBtn('<i class="bi bi-chevron-left" aria-hidden="true"></i>', this.state.currentPage-1, this.state.currentPage===1, false, true, 'Previous page'));

    let pages = [];
    if (totalPages <= 7) { for(let i=1;i<=totalPages;i++) pages.push(i); }
    else {
      pages.push(1);
      if (this.state.currentPage > 3) pages.push('...');
      let s = Math.max(2, this.state.currentPage-1);
      let e = Math.min(totalPages-1, this.state.currentPage+1);
      if (this.state.currentPage <= 3) { s=2; e=4; }
      if (this.state.currentPage >= totalPages-2) { s=totalPages-3; e=totalPages-1; }
      for(let i=s;i<=e;i++) pages.push(i);
      if (this.state.currentPage < totalPages-2) pages.push('...');
      pages.push(totalPages);
    }
    pages.forEach(p=>{
      if (p==='...') {
        const dots = document.createElement('span');
        dots.className = 'page-btn dots';
        dots.textContent = '…';
        dots.setAttribute('data-tooltip','More pages');
        this.dom.pagination.appendChild(dots);
      } else {
        this.dom.pagination.appendChild(createBtn(p, p, false, p===this.state.currentPage, false, `Go to page ${p}`));
      }
    });
    this.dom.pagination.appendChild(createBtn('<i class="bi bi-chevron-right" aria-hidden="true"></i>', this.state.currentPage+1, this.state.currentPage===totalPages, false, true, 'Next page'));
    this.dom.pagination.appendChild(createBtn('<i class="bi bi-chevron-double-right" aria-hidden="true"></i>', totalPages, this.state.currentPage===totalPages, false, true, 'Last page'));
  }

  renderMobileCards() {
    if (!this.options.mobileCards || !this.dom.mobileCards) return;
    const start = (this.state.currentPage-1)*this.state.pageSize;
    const end = start + this.state.pageSize;
    const pageData = this.state.filteredData.slice(start, end);
    this.dom.mobileCards.innerHTML = '';
    pageData.forEach(rowData=>{
      const id = this.getNestedValue(rowData, this.options.idField);
      const isExpanded = this.state.expandedIds.has(id);
      const isSelected = this.state.selectedIds.has(id);
      // Build simple card using columns
      let meta = '';
      this.options.columns.slice(0,4).forEach(col=>{
        const v = this.getNestedValue(rowData, col.key);
        meta += `<div><label>${col.label}</label><div class="val">${col.render?col.render(v,rowData):v||''}</div></div>`;
      });
      const card = document.createElement('div');
      card.className = 'm-card';
      card.innerHTML = `<div class="m-card-head"><div class="m-card-name">${rowData.name||id}</div><div style="display:flex; gap:6px;"><input type="checkbox" class="form-check-input" ${isSelected?'checked':''} aria-label="Select ${id}"></div></div><div class="m-card-meta">${meta}</div><div class="m-card-foot"><button class="btn-dg" style="height:30px;">${isExpanded?'Collapse':'Details'}</button></div>${isExpanded?`<div style="padding-top:8px; border-top:1px solid var(--dg-border); font-size:12.5px;">${this.renderDetail(rowData)}</div>`:''}`;
      this.dom.mobileCards.appendChild(card);
    });
  }

  // ---------- EVENTS ----------
  bindBaseEvents() {
    // Search
    if (this.dom.searchInput) {
      this.dom.searchInput.addEventListener('input', (e)=>{
        this.state.searchText = e.target.value;
        this.dom.searchWrap?.classList.toggle('has-value', !!e.target.value);
        this.applyFiltersAndSort();
        this.render();
      });
      const clearBtn = this.dom.searchWrap?.querySelector('.search-clear');
      if (clearBtn) clearBtn.addEventListener('click', ()=>{
        this.dom.searchInput.value='';
        this.state.searchText='';
        this.dom.searchWrap.classList.remove('has-value');
        this.applyFiltersAndSort();
        this.render();
      });
    }
    // Rows per page
    if (this.dom.rowsPerPage) {
      this.dom.rowsPerPage.addEventListener('change', (e)=>{
        this.state.pageSize = parseInt(e.target.value,10);
        this.state.currentPage = 1;
        this.render();
      });
    }
    // Reload
    const reloadBtn = document.getElementById(`${this.container.id}-reloadBtn`);
    if (reloadBtn) reloadBtn.addEventListener('click', ()=> this.loadData());
    // Reset
    const resetBtn = document.getElementById(`${this.container.id}-resetBtn`);
    if (resetBtn) resetBtn.addEventListener('click', ()=> this.resetAll());
    // Sticky
    if (this.dom.stickyBtn) this.dom.stickyBtn.addEventListener('click', ()=> this.toggleSticky());
    // Theme
    const themeBtn = document.getElementById(`${this.container.id}-themeBtn`);
    if (themeBtn) themeBtn.addEventListener('click', ()=> this.toggleTheme());
    // Add
    const addBtn = document.getElementById(`${this.container.id}-addBtn`);
    if (addBtn && this.options.onAdd) addBtn.addEventListener('click', ()=> this.options.onAdd(this));
    else if (addBtn) addBtn.addEventListener('click', ()=> { const modal=document.getElementById('addRecordModal'); if(modal) new bootstrap.Modal(modal).show(); });

    // Click outside to close inline actions & context menu
    document.addEventListener('click', (e)=>{
      if (!e.target.closest('.row-actions-wrap')) {
        document.querySelectorAll('.row-actions-wrap.is-open').forEach(el=>el.classList.remove('is-open'));
      }
      if (!e.target.closest('#'+this.container.id+'-contextMenu')) {
        this.hideContextMenu();
      }
    });
  }

  bindRowEvents() {
    // Expand buttons
    this.dom.tbody.querySelectorAll('.btn-expand').forEach(btn=>{
      btn.addEventListener('click', (e)=>{
        const tr = e.currentTarget.closest('tr');
        const id = tr.dataset.id;
        this.toggleExpand(id);
      });
    });
    // Select checkboxes
    this.dom.tbody.querySelectorAll('.row-select').forEach(cb=>{
      cb.addEventListener('change', (e)=>{
        const id = e.target.getAttribute('data-id') || e.target.closest('tr').dataset.id;
        this.toggleSelect(id, e.target.checked);
      });
    });
    // Inline actions toggle
    this.dom.tbody.querySelectorAll('.action-trigger').forEach(btn=>{
      btn.addEventListener('click', (e)=>{
        e.stopPropagation();
        const wrap = e.currentTarget.closest('.row-actions-wrap');
        const isOpen = wrap.classList.contains('is-open');
        document.querySelectorAll('.row-actions-wrap.is-open').forEach(w=>{ if(w!==wrap) w.classList.remove('is-open'); });
        wrap.classList.toggle('is-open', !isOpen);
      });
    });
    // Edit / Delete
    this.dom.tbody.querySelectorAll('.ia-edit').forEach(btn=>{
      btn.addEventListener('click', (e)=>{
        const tr = e.currentTarget.closest('tr');
        const id = tr.dataset.id;
        const rowData = this.state.rawData.find(r=>String(this.getNestedValue(r,this.options.idField))===String(id));
        if (this.options.onEdit) this.options.onEdit(rowData, this);
      });
    });
    this.dom.tbody.querySelectorAll('.ia-danger').forEach(btn=>{
      btn.addEventListener('click', (e)=>{
        const tr = e.currentTarget.closest('tr');
        const id = tr.dataset.id;
        const rowData = this.state.rawData.find(r=>String(this.getNestedValue(r,this.options.idField))===String(id));
        if (this.options.onDelete) this.options.onDelete(rowData, this);
      });
    });
    this.dom.tbody.querySelectorAll('.ia-close').forEach(btn=>{
      btn.addEventListener('click', (e)=>{
        e.stopPropagation();
        e.currentTarget.closest('.row-actions-wrap')?.classList.remove('is-open');
      });
    });
    // Context menu
    if (this.options.contextMenu) {
      this.dom.tbody.querySelectorAll('.parent-row').forEach(tr=>{
        tr.addEventListener('contextmenu', (e)=>{
          e.preventDefault();
          this.showContextMenu(e.clientX, e.clientY, tr.dataset.id);
        });
      });
    }
  }

  // ---------- ACTIONS ----------
  sortBy(key) {
    if (this.state.sort.key===key) {
      this.state.sort.dir = this.state.sort.dir==='asc'?'desc':'asc';
    } else {
      this.state.sort.key = key;
      this.state.sort.dir = 'asc';
    }
    this.applyFiltersAndSort();
    this.render();
  }

  goToPage(page) {
    const totalPages = Math.max(1, Math.ceil(this.state.filteredData.length / this.state.pageSize));
    this.state.currentPage = Math.min(Math.max(1, page), totalPages);
    this.render();
  }

  toggleSelectAll(checked) {
    const start = (this.state.currentPage-1)*this.state.pageSize;
    const end = start + this.state.pageSize;
    const pageData = this.state.filteredData.slice(start, end);
    pageData.forEach(row=>{
      const id = this.getNestedValue(row, this.options.idField);
      if (checked) this.state.selectedIds.add(id);
      else this.state.selectedIds.delete(id);
    });
    this.render();
  }

  toggleSelect(id, checked) {
    if (checked) this.state.selectedIds.add(isNaN(id)?id:Number(id)||id);
    else this.state.selectedIds.delete(isNaN(id)?id:Number(id)||id);
    // also try string version
    if (checked) this.state.selectedIds.add(id);
    else this.state.selectedIds.delete(id);
    // normalize: remove both types if unchecked
    if (!checked) {
      this.state.selectedIds.forEach(v=>{
        if (String(v)===String(id)) this.state.selectedIds.delete(v);
      });
    }
    this.renderFooter();
    this.updateCounts();
  }

  toggleExpand(id) {
    // handle both string and number
    const key = this.state.expandedIds.has(id) ? id : (this.state.expandedIds.has(Number(id))?Number(id):id);
    if (this.state.expandedIds.has(id) || this.state.expandedIds.has(Number(id)) || this.state.expandedIds.has(String(id))) {
      this.state.expandedIds.forEach(v=>{ if(String(v)===String(id)) this.state.expandedIds.delete(v); });
    } else {
      this.state.expandedIds.add(id);
    }
    this.render();
  }

  toggleSticky() {
    this.state.stickyEnabled = !this.state.stickyEnabled;
    localStorage.setItem('dg-sticky-first', this.state.stickyEnabled);
    this.applyStickyState();
  }

  applyStickyState() {
    if (!this.dom.card) return;
    if (this.state.stickyEnabled) {
      this.dom.card.classList.add('sticky-first');
      this.dom.stickyBtn?.classList.add('active');
      this.dom.stickyBtn?.setAttribute('aria-pressed','true');
      if (this.dom.stickyIcon) this.dom.stickyIcon.className = 'bi bi-pin-angle-fill';
    } else {
      this.dom.card.classList.remove('sticky-first');
      this.dom.stickyBtn?.classList.remove('active');
      this.dom.stickyBtn?.setAttribute('aria-pressed','false');
      if (this.dom.stickyIcon) this.dom.stickyIcon.className = 'bi bi-pin-angle';
    }
  }

  toggleTheme() {
    this.state.theme = this.state.theme==='dark'?'light':'dark';
    this.applyTheme(this.state.theme);
  }

  applyTheme(theme) {
    document.documentElement.setAttribute('data-theme', theme);
    localStorage.setItem('dg-theme', theme);
    if (this.dom.themeIcon) this.dom.themeIcon.className = theme==='dark' ? 'bi bi-sun' : 'bi bi-moon-stars';
    if (this.dom.themeLabel) this.dom.themeLabel.textContent = theme==='dark' ? 'Dark mode' : 'Light mode';
  }

  resetAll() {
    this.state.searchText = '';
    this.state.advancedFilters = {};
    this.state.sort = {key:null, dir:'asc'};
    this.state.currentPage = 1;
    if (this.dom.searchInput) { this.dom.searchInput.value=''; this.dom.searchWrap?.classList.remove('has-value'); }
    this.applyFiltersAndSort();
    this.render();
  }

  resetFilters() {
    this.state.searchText = '';
    this.state.advancedFilters = {};
    if (this.dom.searchInput) { this.dom.searchInput.value=''; this.dom.searchWrap?.classList.remove('has-value'); }
    this.applyFiltersAndSort();
    this.render();
  }

  updateCounts() {
    if (this.dom.showingCount) this.dom.showingCount.textContent = this.state.filteredData.length;
    if (this.dom.selectedCount) this.dom.selectedCount.textContent = this.state.selectedIds.size;
  }

  // ---------- TOOLTIPS - Reusable ----------
  initTooltips() {
    let hideTimer = null;
    const show = (target) => {
      const text = target.getAttribute('data-tooltip');
      if (!text || !this.tooltipEl) return;
      this.tooltipEl.textContent = text;
      this.tooltipEl.classList.toggle('multiline', text.length>40);
      this.tooltipEl.style.left='0px'; this.tooltipEl.style.top='0px';
      this.tooltipEl.classList.add('show');
      this.tooltipEl.style.opacity='1';
      this.tooltipEl.style.transform='translateY(0)';
      const tRect = target.getBoundingClientRect();
      const tipRect = this.tooltipEl.getBoundingClientRect();
      const pos = target.getAttribute('data-tooltip-pos')||'top';
      let left, top; const gap=8;
      if(pos==='bottom'){ left=tRect.left+(tRect.width-tipRect.width)/2; top=tRect.bottom+gap; }
      else if(pos==='left'){ left=tRect.left-tipRect.width-gap; top=tRect.top+(tRect.height-tipRect.height)/2; }
      else if(pos==='right'){ left=tRect.right+gap; top=tRect.top+(tRect.height-tipRect.height)/2; }
      else { left=tRect.left+(tRect.width-tipRect.width)/2; top=tRect.top-tipRect.height-gap; }
      left=Math.max(6,Math.min(left,window.innerWidth-tipRect.width-6));
      top=Math.max(6,Math.min(top,window.innerHeight-tipRect.height-6));
      this.tooltipEl.style.left=left+'px';
      this.tooltipEl.style.top=top+'px';
    };
    const hide = () => {
      if (!this.tooltipEl) return;
      this.tooltipEl.classList.remove('show');
      this.tooltipEl.style.opacity='0';
      this.tooltipEl.style.transform='translateY(4px)';
    };
    document.addEventListener('mouseover', (e)=>{
      const target = e.target.closest('[data-tooltip]');
      if (!target || !this.container.contains(target) && !target.closest('.pagination-modern')) return;
      if (hideTimer) clearTimeout(hideTimer);
      hideTimer = setTimeout(()=>show(target), 200);
    });
    document.addEventListener('mouseout', (e)=>{
      const target = e.target.closest('[data-tooltip]');
      if (!target) return;
      if (hideTimer) clearTimeout(hideTimer);
      hideTimer = setTimeout(()=>hide(), 80);
    });
    document.addEventListener('click', hide);
    window.addEventListener('scroll', hide, true);
  }

  // ---------- CONTEXT MENU - Reusable ----------
  initContextMenu() {
    if (!this.contextMenuEl) return;
    this.contextMenuEl.innerHTML = `
      <div class="ctx-header" id="ctxHeader" role="presentation">Row actions</div>
      <div class="ctx-item" role="menuitem" tabindex="-1" data-action="copyId"><i class="bi bi-hash" aria-hidden="true"></i> Copy ID</div>
      <div class="ctx-item" role="menuitem" tabindex="-1" data-action="copyRow"><i class="bi bi-clipboard" aria-hidden="true"></i> Copy row as JSON</div>
      <div class="ctx-sep"></div>
      <div class="ctx-item" role="menuitem" tabindex="-1" data-action="toggle"><i class="bi bi-arrows-expand" aria-hidden="true"></i> Expand / Collapse</div>
      <div class="ctx-item" role="menuitem" tabindex="-1" data-action="edit"><i class="bi bi-pencil" aria-hidden="true"></i> Edit</div>
      <div class="ctx-sep"></div>
      <div class="ctx-item danger" role="menuitem" tabindex="-1" data-action="delete"><i class="bi bi-trash" aria-hidden="true"></i> Delete</div>
    `;
    this.contextMenuEl.querySelectorAll('[data-action]').forEach(item=>{
      item.addEventListener('click', ()=>{
        const action = item.getAttribute('data-action');
        this.handleContextAction(action);
      });
    });
  }

  showContextMenu(x, y, rowId) {
    if (!this.contextMenuEl) return;
    this.contextMenuRowId = rowId;
    const header = this.contextMenuEl.querySelector('#ctxHeader');
    if (header) {
      const row = this.state.rawData.find(r=>String(this.getNestedValue(r,this.options.idField))===String(rowId));
      header.textContent = row ? `${row.name||rowId} • #${rowId}` : `Row #${rowId}`;
    }
    this.contextMenuEl.style.left = x+'px';
    this.contextMenuEl.style.top = y+'px';
    this.contextMenuEl.style.display = 'block';
    const rect = this.contextMenuEl.getBoundingClientRect();
    if (rect.right>window.innerWidth) this.contextMenuEl.style.left = (window.innerWidth-rect.width-8)+'px';
    if (rect.bottom>window.innerHeight) this.contextMenuEl.style.top = (window.innerHeight-rect.height-8)+'px';
  }

  hideContextMenu() {
    if (this.contextMenuEl) this.contextMenuEl.style.display='none';
    this.contextMenuRowId = null;
  }

  handleContextAction(action) {
    const rowId = this.contextMenuRowId;
    if (!rowId) return;
    const rowData = this.state.rawData.find(r=>String(this.getNestedValue(r,this.options.idField))===String(rowId));
    switch(action){
      case 'copyId': navigator.clipboard.writeText(String(rowId)); break;
      case 'copyRow': navigator.clipboard.writeText(JSON.stringify(rowData,null,2)); break;
      case 'toggle': this.toggleExpand(rowId); break;
      case 'edit': if(this.options.onEdit) this.options.onEdit(rowData, this); break;
      case 'delete': if(this.options.onDelete) this.options.onDelete(rowData, this); break;
    }
    this.hideContextMenu();
  }

  // ---------- HELPERS - Reusable ----------
  getNestedValue(obj, path) {
    if (!path) return undefined;
    return path.split('.').reduce((o,k)=>o?o[k]:undefined, obj);
  }

  // Data manipulation helpers - separated from UI
  addRow(rowData) {
    this.state.rawData.push(rowData);
    this.applyFiltersAndSort();
    this.render();
  }

  updateRow(id, newData) {
    const idx = this.state.rawData.findIndex(r=>String(this.getNestedValue(r,this.options.idField))===String(id));
    if (idx>=0) {
      this.state.rawData[idx] = {...this.state.rawData[idx], ...newData};
      this.applyFiltersAndSort();
      this.render();
    }
  }

  deleteRow(id) {
    this.state.rawData = this.state.rawData.filter(r=>String(this.getNestedValue(r,this.options.idField))!==String(id));
    this.state.selectedIds.forEach(v=>{ if(String(v)===String(id)) this.state.selectedIds.delete(v); });
    this.state.expandedIds.forEach(v=>{ if(String(v)===String(id)) this.state.expandedIds.delete(v); });
    this.applyFiltersAndSort();
    this.render();
  }

  // Export data
  getSelectedRows() {
    return this.state.rawData.filter(r=> {
      const id = this.getNestedValue(r, this.options.idField);
      return Array.from(this.state.selectedIds).some(s=>String(s)===String(id));
    });
  }

  getFilteredRows() {
    return this.state.filteredData;
  }
}

// Export for module systems
if (typeof module!=='undefined' && module.exports) module.exports = DataGrid;
if (typeof window!=='undefined') window.DataGrid = DataGrid;
