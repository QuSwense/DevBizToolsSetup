
/**
 * Sidebar - Reusable collapsible menu with 2-level submenus
 * Same design philosophy as DataGrid: flat, zero-radius, light/dark, ARIA, tooltips
 * 
 * Usage:
 *   const sidebar = new Sidebar('#sidebar', {
 *     menu: [ {id, label, icon, badge, children: [ {label, icon, children: [...] } ] } ],
 *     collapsed: false,
 *     onSelect: (item)=>{}
 *   });
 */

class Sidebar {
  constructor(selector, options = {}) {
    this.el = document.querySelector(selector);
    if (!this.el) throw new Error(`Sidebar: ${selector} not found`);
    this.options = Object.assign({
      menu: [],
      collapsed: localStorage.getItem('sb-collapsed') === 'true' || false,
      activeId: null,
      onSelect: null,
      storageKey: 'sb-collapsed',
    }, options);
    this.state = {
      collapsed: this.options.collapsed,
      openMenus: new Set(JSON.parse(localStorage.getItem('sb-openMenus') || '[]')),
      activeId: this.options.activeId || localStorage.getItem('sb-active') || null,
    };
    this.flyoutEl = null;
    this.tooltipEl = null;
    this.overlayEl = null;
  }

  init() {
    this.render();
    this.bindEvents();
    this.applyCollapsed(this.state.collapsed, false);
    this.restoreOpenMenus();
    if (this.state.activeId) this.setActive(this.state.activeId, false);
    this.initTooltip();
    this.initFlyout();
    this.initOverlay();
    return this;
  }

  render() {
    const menuHtml = this.options.menu.map(section => {
      if (section.type === 'label') {
        return `<div class="menu-section"><div class="menu-section-label">${section.label}</div></div>`;
      }
      if (section.type === 'section') {
        const items = section.items.map(item => this.renderMenuItem(item)).join('');
        return `<div class="menu-section"><div class="menu-section-label">${section.label}</div>${items}</div>`;
      }
      // flat item
      return `<div class="menu-section">${this.renderMenuItem(section)}</div>`;
    }).join('');

    this.el.innerHTML = `
      <div class="sidebar-header">
        <div class="sidebar-brand">
          <div class="brand-mark">DG</div>
          <div class="brand-text"><span class="brand-title">DataGrid Pro</span><span class="brand-sub">Enterprise</span></div>
        </div>
        <button class="btn-collapse" aria-label="Toggle sidebar" data-tooltip="${this.state.collapsed?'Expand sidebar':'Collapse sidebar'}" data-tooltip-pos="right">
          <i class="bi ${this.state.collapsed ? 'bi-chevron-right' : 'bi-chevron-left'}" aria-hidden="true"></i>
        </button>
      </div>
      <nav class="sidebar-nav" role="navigation" aria-label="Main navigation">
        ${menuHtml}
      </nav>
      <div class="sidebar-footer">
        <div class="user-card">
          <div class="avatar">JD</div>
          <div class="user-meta"><div class="user-name">Jane Doe</div><div class="user-role">Admin • Core Platform</div></div>
        </div>
        <div class="footer-actions">
          <button class="btn-dg" aria-label="Theme" data-tooltip="Toggle theme"><i class="bi bi-moon-stars" aria-hidden="true"></i><span class="btn-label">Theme</span></button>
          <button class="btn-dg" aria-label="Settings" data-tooltip="Settings"><i class="bi bi-gear" aria-hidden="true"></i><span class="btn-label">Settings</span></button>
        </div>
      </div>
    `;
  }

  renderMenuItem(item) {
    const hasChildren = item.children && item.children.length > 0;
    const isOpen = this.state.openMenus.has(item.id);
    const badge = item.badge ? (typeof item.badge === 'number' || !isNaN(item.badge) ? `<span class="menu-badge">${item.badge}</span>` : `<span class="menu-badge dot" data-tooltip="${item.badge}"></span>`) : '';
    const chevron = hasChildren ? `<span class="menu-chevron"><i class="bi bi-chevron-right" aria-hidden="true"></i></span>` : '';
    return `
      <div class="menu-item ${this.state.activeId===item.id?'active':''} ${hasChildren?'has-submenu':''} ${isOpen?'open':''}" data-id="${item.id}" role="button" tabindex="0" aria-expanded="${hasChildren?isOpen:false}" aria-label="${item.label}" data-tooltip="${item.label}" data-tooltip-pos="right">
        <span class="menu-icon"><i class="bi ${item.icon||'bi-circle'}" aria-hidden="true"></i></span>
        <span class="menu-label">${item.label}</span>
        ${badge}
        ${chevron}
      </div>
      ${hasChildren ? `<div class="submenu" id="submenu-${item.id}" role="group">${item.children.map(child => this.renderSubmenuItem(child, item.id)).join('')}</div>` : ''}
    `;
  }

  renderSubmenuItem(child, parentId) {
    const hasChildren = child.children && child.children.length > 0;
    const isOpen = this.state.openMenus.has(child.id);
    return `
      <div class="submenu-item ${this.state.activeId===child.id?'active':''} ${hasChildren?'has-children':''} ${isOpen?'open':''}" data-id="${child.id}" data-parent="${parentId}" role="button" tabindex="0" aria-expanded="${hasChildren?isOpen:false}">
        <span class="sub-icon"><i class="bi ${child.icon||'bi-dot'}" aria-hidden="true"></i></span>
        <span class="sub-label">${child.label}</span>
        ${child.badge ? `<span class="menu-badge" style="height:16px; font-size:10px;">${child.badge}</span>` : ''}
        ${hasChildren ? `<span class="sub-chevron"><i class="bi bi-chevron-right" aria-hidden="true"></i></span>` : ''}
      </div>
      ${hasChildren ? `<div class="submenu-l2" id="submenu-${child.id}">${child.children.map(l2 => this.renderL2Item(l2, child.id)).join('')}</div>` : ''}
    `;
  }

  renderL2Item(l2, parentId) {
    return `
      <div class="submenu-l2-item ${this.state.activeId===l2.id?'active':''}" data-id="${l2.id}" data-parent="${parentId}" role="button" tabindex="0">
        <span class="dot"></span><span>${l2.label}</span>${l2.badge?`<span class="menu-badge" style="height:14px; font-size:9px; margin-left:auto;">${l2.badge}</span>`:''}
      </div>
    `;
  }

  bindEvents() {
    // Collapse toggle
    this.el.querySelector('.btn-collapse').addEventListener('click', ()=> this.toggleCollapsed());

    // Menu item clicks
    this.el.addEventListener('click', (e)=>{
      const item = e.target.closest('.menu-item, .submenu-item, .submenu-l2-item');
      if (!item) return;
      const id = item.dataset.id;
      const hasChildren = item.classList.contains('has-submenu') || item.classList.contains('has-children');

      if (hasChildren) {
        if (this.state.collapsed) {
          // In collapsed mode, show flyout
          const mainId = item.dataset.id;
          const mainItem = this.findItemById(mainId);
          if (mainItem) this.showFlyout(e.currentTarget, mainItem, item);
        } else {
          this.toggleSubmenu(id);
        }
      } else {
        this.setActive(id);
        if (this.options.onSelect) {
          const found = this.findItemById(id);
          this.options.onSelect(found, this);
        }
      }
    });

    // Keyboard
    this.el.addEventListener('keydown', (e)=>{
      if (e.key==='Enter' || e.key===' ') {
        e.preventDefault();
        e.target.click();
      }
      if (e.key==='Escape') {
        this.hideFlyout();
      }
    });

    // Theme button
    const themeBtn = this.el.querySelector('.footer-actions .btn-dg');
    if (themeBtn) {
      themeBtn.addEventListener('click', ()=>{
        const current = document.documentElement.getAttribute('data-theme')||'light';
        const next = current==='dark'?'light':'dark';
        document.documentElement.setAttribute('data-theme', next);
        localStorage.setItem('dg-theme', next);
      });
    }

    // Mobile overlay close
    window.addEventListener('resize', ()=>{
      if (window.innerWidth > 768) {
        document.querySelector('.sidebar-overlay')?.classList.remove('show');
        this.el.classList.remove('mobile-open');
      }
    });
  }

  toggleCollapsed() {
    this.state.collapsed = !this.state.collapsed;
    this.applyCollapsed(this.state.collapsed, true);
  }

  applyCollapsed(collapsed, persist=true) {
    this.state.collapsed = collapsed;
    this.el.classList.toggle('collapsed', collapsed);
    if (persist) {
      localStorage.setItem(this.options.storageKey, collapsed);
      localStorage.setItem('sb-collapsed', collapsed);
    }
    const btn = this.el.querySelector('.btn-collapse');
    if (btn) {
      btn.setAttribute('data-tooltip', collapsed?'Expand sidebar':'Collapse sidebar');
      btn.querySelector('i').className = `bi ${collapsed?'bi-chevron-right':'bi-chevron-left'}`;
    }
    // Update main content margin via CSS variable or event
    document.dispatchEvent(new CustomEvent('sidebar:toggle', {detail:{collapsed}}));
  }

  toggleSubmenu(id) {
    const isOpen = this.state.openMenus.has(id);
    if (isOpen) this.state.openMenus.delete(id);
    else this.state.openMenus.add(id);
    // Persist
    localStorage.setItem('sb-openMenus', JSON.stringify([...this.state.openMenus]));
    localStorage.setItem('sb-active', this.state.activeId||'');

    // DOM
    const item = this.el.querySelector(`[data-id="${id}"]`);
    if (item) {
      item.classList.toggle('open', !isOpen);
      item.setAttribute('aria-expanded', !isOpen);
    }
    // Also toggle submenu visibility via CSS (open class controls)
  }

  restoreOpenMenus() {
    this.state.openMenus.forEach(id=>{
      const el = this.el.querySelector(`[data-id="${id}"]`);
      if (el) {
        el.classList.add('open');
        el.setAttribute('aria-expanded','true');
      }
    });
  }

  setActive(id, persist=true) {
    this.state.activeId = id;
    this.el.querySelectorAll('.menu-item, .submenu-item, .submenu-l2-item').forEach(el=>el.classList.remove('active'));
    const activeEl = this.el.querySelector(`[data-id="${id}"]`);
    if (activeEl) activeEl.classList.add('active');
    if (persist) localStorage.setItem('sb-active', id);
  }

  findItemById(id, items=this.options.menu) {
    for (const it of items) {
      if (it.id===id) return it;
      if (it.items) {
        const found = this.findItemById(id, it.items);
        if (found) return found;
      }
      if (it.children) {
        const found = this.findItemById(id, it.children);
        if (found) return found;
      }
    }
    return null;
  }

  // Flyout for collapsed mode
  initFlyout() {
    let flyout = document.getElementById('sidebarFlyout');
    if (!flyout) {
      flyout = document.createElement('div');
      flyout.id = 'sidebarFlyout';
      flyout.className = 'sidebar-flyout';
      flyout.setAttribute('role','menu');
      document.body.appendChild(flyout);
    }
    this.flyoutEl = flyout;

    // Close on outside click
    document.addEventListener('click', (e)=>{
      if (!e.target.closest('.sidebar') && !e.target.closest('#sidebarFlyout')) this.hideFlyout();
    });
    document.addEventListener('keydown', (e)=>{ if(e.key==='Escape') this.hideFlyout(); });
  }

  showFlyout(anchor, itemData, clickedEl) {
    if (!this.flyoutEl) return;
    const rect = clickedEl.getBoundingClientRect();
    let html = `<div class="flyout-header">${itemData.label}</div>`;
    if (itemData.children) {
      itemData.children.forEach(child=>{
        const hasChildren = child.children && child.children.length>0;
        html += `<div class="flyout-item ${hasChildren?'has-children':''} ${this.state.activeId===child.id?'active':''}" data-id="${child.id}" role="menuitem">${child.label} ${hasChildren?'<i class="bi bi-chevron-right" style="font-size:10px;"></i>':''}</div>`;
        if (hasChildren) {
          html += `<div class="flyout-sub" id="flyout-sub-${child.id}">${child.children.map(l2=>`<div class="flyout-item ${this.state.activeId===l2.id?'active':''}" data-id="${l2.id}" role="menuitem"><span class="dot" style="width:4px;height:4px;background:currentColor;display:inline-block;"></span> ${l2.label}</div>`).join('')}</div>`;
        }
      });
    }
    this.flyoutEl.innerHTML = html;
    this.flyoutEl.style.left = (rect.right + 8) + 'px';
    this.flyoutEl.style.top = rect.top + 'px';
    this.flyoutEl.classList.add('show');

    // Keep in viewport
    const fr = this.flyoutEl.getBoundingClientRect();
    if (fr.bottom > window.innerHeight) this.flyoutEl.style.top = (window.innerHeight - fr.height - 12) + 'px';
    if (fr.right > window.innerWidth) this.flyoutEl.style.left = (rect.left - fr.width - 8) + 'px';

    // Bind flyout clicks
    this.flyoutEl.querySelectorAll('.flyout-item').forEach(el=>{
      el.addEventListener('click', (e)=>{
        const id = el.dataset.id;
        const hasChildren = el.classList.contains('has-children');
        if (hasChildren) {
          el.classList.toggle('open');
          const sub = document.getElementById(`flyout-sub-${id}`);
          if (sub) sub.style.display = sub.style.display==='flex' ? 'none' : 'flex';
        } else {
          this.setActive(id);
          if (this.options.onSelect) {
            const found = this.findItemById(id);
            this.options.onSelect(found, this);
          }
          this.hideFlyout();
        }
      });
    });
  }

  hideFlyout() {
    if (this.flyoutEl) this.flyoutEl.classList.remove('show');
  }

  initTooltip() {
    let tooltip = document.getElementById('sidebarTooltip');
    if (!tooltip) {
      tooltip = document.createElement('div');
      tooltip.id = 'sidebarTooltip';
      tooltip.setAttribute('role','tooltip');
      document.body.appendChild(tooltip);
    }
    this.tooltipEl = tooltip;
    let hideTimer=null;
    const show = (target)=>{
      if (!this.state.collapsed) {
        // Only show tooltip when collapsed or explicitly data-tooltip
        const isCollapsedOnly = target.closest('.sidebar.collapsed');
        if (!isCollapsedOnly && !target.hasAttribute('data-tooltip')) return;
      }
      const text = target.getAttribute('data-tooltip') || target.getAttribute('aria-label') || target.textContent.trim();
      if (!text || !this.tooltipEl) return;
      this.tooltipEl.textContent = text;
      this.tooltipEl.style.left='0px'; this.tooltipEl.style.top='0px';
      this.tooltipEl.classList.add('show');
      this.tooltipEl.style.opacity='1'; this.tooltipEl.style.transform='translateY(0)';
      const tRect = target.getBoundingClientRect();
      const tipRect = this.tooltipEl.getBoundingClientRect();
      let left = tRect.right + 10;
      let top = tRect.top + (tRect.height - tipRect.height)/2;
      left=Math.max(6,Math.min(left,window.innerWidth-tipRect.width-6));
      top=Math.max(6,Math.min(top,window.innerHeight-tipRect.height-6));
      this.tooltipEl.style.left=left+'px'; this.tooltipEl.style.top=top+'px';
    };
    const hide = ()=>{
      if (!this.tooltipEl) return;
      this.tooltipEl.classList.remove('show');
      this.tooltipEl.style.opacity='0'; this.tooltipEl.style.transform='translateY(4px)';
    };
    document.addEventListener('mouseover', (e)=>{
      const target = e.target.closest('.sidebar [data-tooltip], .sidebar .menu-item, .sidebar .btn-collapse');
      if (!target || !this.el.contains(target)) return;
      if (!this.state.collapsed && !target.hasAttribute('data-tooltip')) return;
      if (hideTimer) clearTimeout(hideTimer);
      hideTimer=setTimeout(()=>show(target), 250);
    });
    document.addEventListener('mouseout', (e)=>{
      const target = e.target.closest('.sidebar [data-tooltip], .sidebar .menu-item');
      if (!target) return;
      if (hideTimer) clearTimeout(hideTimer);
      hideTimer=setTimeout(()=>hide(), 80);
    });
    document.addEventListener('click', hide);
  }

  initOverlay() {
    let overlay = document.querySelector('.sidebar-overlay');
    if (!overlay) {
      overlay = document.createElement('div');
      overlay.className = 'sidebar-overlay';
      document.body.appendChild(overlay);
    }
    this.overlayEl = overlay;
    overlay.addEventListener('click', ()=>{
      this.el.classList.remove('mobile-open');
      overlay.classList.remove('show');
    });
  }

  openMobile() {
    this.el.classList.add('mobile-open');
    this.overlayEl?.classList.add('show');
  }
}

if (typeof window!=='undefined') window.Sidebar = Sidebar;
