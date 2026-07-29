/* ============================================================
   SERVICE HUB V8 — React Application
   Tables styled with DataGrid design system (service-hub.css)
   Components organized following appsrc philosophy.
   ============================================================ */

const { useState, useMemo, useEffect, useCallback } = React;

/* ============================================================
   ICON COMPONENTS (inline SVGs — lightweight, no deps)
   ============================================================ */
const Icons = {
    Menu: () => React.createElement('svg', { width: 18, height: 18, viewBox: '0 0 24 24', fill: 'none', stroke: 'currentColor', strokeWidth: 2, strokeLinecap: 'round', strokeLinejoin: 'round' },
        React.createElement('line', { x1: 4, y1: 12, x2: 20, y2: 12 }),
        React.createElement('line', { x1: 4, y1: 6, x2: 20, y2: 6 }),
        React.createElement('line', { x1: 4, y1: 18, x2: 20, y2: 18 })
    ),
    ChevronDown: () => React.createElement('svg', { width: 14, height: 14, viewBox: '0 0 24 24', fill: 'none', stroke: 'currentColor', strokeWidth: 2, strokeLinecap: 'round', strokeLinejoin: 'round' },
        React.createElement('path', { d: 'm6 9 6 6 6-6' })
    ),
    ChevronRight: () => React.createElement('svg', { width: 14, height: 14, viewBox: '0 0 24 24', fill: 'none', stroke: 'currentColor', strokeWidth: 2, strokeLinecap: 'round', strokeLinejoin: 'round' },
        React.createElement('path', { d: 'm9 18 6-6-6-6' })
    ),
    LayoutDashboard: () => React.createElement('svg', { width: 16, height: 16, viewBox: '0 0 24 24', fill: 'none', stroke: 'currentColor', strokeWidth: 2, strokeLinecap: 'round', strokeLinejoin: 'round' },
        React.createElement('rect', { width: 7, height: 9, x: 3, y: 3, rx: 1 }),
        React.createElement('rect', { width: 7, height: 5, x: 14, y: 3, rx: 1 }),
        React.createElement('rect', { width: 7, height: 9, x: 14, y: 12, rx: 1 }),
        React.createElement('rect', { width: 7, height: 5, x: 3, y: 16, rx: 1 })
    ),
    AppWindow: () => React.createElement('svg', { width: 16, height: 16, viewBox: '0 0 24 24', fill: 'none', stroke: 'currentColor', strokeWidth: 2, strokeLinecap: 'round', strokeLinejoin: 'round' },
        React.createElement('rect', { x: 2, y: 4, width: 20, height: 16, rx: 2 }),
        React.createElement('path', { d: 'M10 4v4' }),
        React.createElement('path', { d: 'M2 8h20' }),
        React.createElement('path', { d: 'M6 4v4' })
    ),
    Database: () => React.createElement('svg', { width: 16, height: 16, viewBox: '0 0 24 24', fill: 'none', stroke: 'currentColor', strokeWidth: 2, strokeLinecap: 'round', strokeLinejoin: 'round' },
        React.createElement('ellipse', { cx: 12, cy: 5, rx: 9, ry: 3 }),
        React.createElement('path', { d: 'M3 5V19A9 3 0 0 0 21 19V5' }),
        React.createElement('path', { d: 'M3 12A9 3 0 0 0 21 12' })
    ),
    FolderTree: () => React.createElement('svg', { width: 16, height: 16, viewBox: '0 0 24 24', fill: 'none', stroke: 'currentColor', strokeWidth: 2, strokeLinecap: 'round', strokeLinejoin: 'round' },
        React.createElement('path', { d: 'M20 10a1 1 0 0 0 1-1V6a1 1 0 0 0-1-1h-2.5a1 1 0 0 1-.8-.4l-.9-1.2A1 1 0 0 0 15 3h-2a1 1 0 0 0-1 1v5a1 1 0 0 0 1 1Z' }),
        React.createElement('path', { d: 'M20 21a1 1 0 0 0 1-1v-3a1 1 0 0 0-1-1h-2.9a1 1 0 0 1-.88-.55l-.42-.85a1 1 0 0 0-.92-.6H13a1 1 0 0 0-1 1v5a1 1 0 0 0 1 1Z' }),
        React.createElement('path', { d: 'M3 5a2 2 0 0 0 2 2h3' }),
        React.createElement('path', { d: 'M3 3v13a2 2 0 0 0 2 2h3' })
    ),
    Beaker: () => React.createElement('svg', { width: 16, height: 16, viewBox: '0 0 24 24', fill: 'none', stroke: 'currentColor', strokeWidth: 2, strokeLinecap: 'round', strokeLinejoin: 'round' },
        React.createElement('path', { d: 'M4.5 3h15' }),
        React.createElement('path', { d: 'M6 3v16a2 2 0 0 0 2 2h8a2 2 0 0 0 2-2V3' }),
        React.createElement('path', { d: 'M6 14h12' })
    ),
    Users: () => React.createElement('svg', { width: 16, height: 16, viewBox: '0 0 24 24', fill: 'none', stroke: 'currentColor', strokeWidth: 2, strokeLinecap: 'round', strokeLinejoin: 'round' },
        React.createElement('path', { d: 'M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2' }),
        React.createElement('circle', { cx: 9, cy: 7, r: 4 }),
        React.createElement('path', { d: 'M22 21v-2a4 4 0 0 0-3-3.87' }),
        React.createElement('path', { d: 'M16 3.13a4 4 0 0 1 0 7.75' })
    ),
    Settings: () => React.createElement('svg', { width: 16, height: 16, viewBox: '0 0 24 24', fill: 'none', stroke: 'currentColor', strokeWidth: 2, strokeLinecap: 'round', strokeLinejoin: 'round' },
        React.createElement('circle', { cx: 12, cy: 12, r: 3 }),
        React.createElement('path', { d: 'M12.22 2h-.44a2 2 0 0 0-2 2v.18a2 2 0 0 1-1 1.73l-.43.25a2 2 0 0 1-2 0l-.15-.08a2 2 0 0 0-2.73.73l-.22.38a2 2 0 0 0 .73 2.73l.15.1a2 2 0 0 1 1 1.72v.51a2 2 0 0 1-1 1.74l-.15.09a2 2 0 0 0-.73 2.73l.22.38a2 2 0 0 0 2.73.73l.15-.08a2 2 0 0 1 2 0l.43.25a2 2 0 0 1 1 1.73V20a2 2 0 0 0 2 2h.44a2 2 0 0 0 2-2v-.18a2 2 0 0 1 1-1.73l.43-.25a2 2 0 0 1 2 0l.15.08a2 2 0 0 0 2.73-.73l.22-.39a2 2 0 0 0-.73-2.73l-.15-.08a2 2 0 0 1-1-1.74v-.5a2 2 0 0 1 1-1.74l.15-.09a2 2 0 0 0 .73-2.73l-.22-.38a2 2 0 0 0-2.73-.73l-.15.08a2 2 0 0 1-2 0l-.43-.25a2 2 0 0 1-1-1.73V4a2 2 0 0 0-2-2z' })
    ),
    Activity: () => React.createElement('svg', { width: 16, height: 16, viewBox: '0 0 24 24', fill: 'none', stroke: 'currentColor', strokeWidth: 2, strokeLinecap: 'round', strokeLinejoin: 'round' },
        React.createElement('path', { d: 'M22 12h-2.48a2 2 0 0 0-1.93 1.46l-2.35 8.36a.25.25 0 0 1-.48 0L9.24 2.18a.25.25 0 0 0-.48 0l-2.35 8.36A2 2 0 0 1 4.49 12H2' })
    ),
    Search: () => React.createElement('svg', { width: 14, height: 14, viewBox: '0 0 24 24', fill: 'none', stroke: 'currentColor', strokeWidth: 2, strokeLinecap: 'round', strokeLinejoin: 'round' },
        React.createElement('circle', { cx: 11, cy: 11, r: 8 }),
        React.createElement('path', { d: 'm21 21-4.3-4.3' })
    ),
    Plus: () => React.createElement('svg', { width: 12, height: 12, viewBox: '0 0 24 24', fill: 'none', stroke: 'currentColor', strokeWidth: 2, strokeLinecap: 'round', strokeLinejoin: 'round' },
        React.createElement('path', { d: 'M5 12h14' }),
        React.createElement('path', { d: 'M12 5v14' })
    ),
    Download: () => React.createElement('svg', { width: 12, height: 12, viewBox: '0 0 24 24', fill: 'none', stroke: 'currentColor', strokeWidth: 2, strokeLinecap: 'round', strokeLinejoin: 'round' },
        React.createElement('path', { d: 'M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4' }),
        React.createElement('polyline', { points: '7 10 12 15 17 10' }),
        React.createElement('line', { x1: 12, x2: 12, y1: 15, y2: 3 })
    ),
    FileJson: () => React.createElement('svg', { width: 12, height: 12, viewBox: '0 0 24 24', fill: 'none', stroke: 'currentColor', strokeWidth: 2, strokeLinecap: 'round', strokeLinejoin: 'round' },
        React.createElement('path', { d: 'M15 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V7Z' }),
        React.createElement('path', { d: 'M14 2v4a2 2 0 0 0 2 2h4' }),
        React.createElement('path', { d: 'M10 12a1 1 0 0 0-1 1v1a1 1 0 0 1-1 1 1 1 0 0 1 1 1v1a1 1 0 0 0 1 1' }),
        React.createElement('path', { d: 'M14 18a1 1 0 0 0 1-1v-1a1 1 0 0 1 1-1 1 1 0 0 1-1-1v-1a1 1 0 0 0-1-1' })
    ),
    Trash2: () => React.createElement('svg', { width: 12, height: 12, viewBox: '0 0 24 24', fill: 'none', stroke: 'currentColor', strokeWidth: 2, strokeLinecap: 'round', strokeLinejoin: 'round' },
        React.createElement('path', { d: 'M3 6h18' }),
        React.createElement('path', { d: 'M19 6v14c0 1-1 2-2 2H7c-1 0-2-1-2-2V6' }),
        React.createElement('path', { d: 'M8 6V4c0-1 1-2 2-2h4c1 0 2 1 2 2v2' }),
        React.createElement('line', { x1: 10, x2: 10, y1: 11, y2: 17 }),
        React.createElement('line', { x1: 14, x2: 14, y1: 11, y2: 17 })
    ),
    ArrowUpDown: () => React.createElement('svg', { width: 12, height: 12, viewBox: '0 0 24 24', fill: 'none', stroke: 'currentColor', strokeWidth: 2, strokeLinecap: 'round', strokeLinejoin: 'round' },
        React.createElement('path', { d: 'm21 16-4 4-4-4' }),
        React.createElement('path', { d: 'M17 20V4' }),
        React.createElement('path', { d: 'm3 8 4-4 4 4' }),
        React.createElement('path', { d: 'M7 4v16' })
    ),
    X: () => React.createElement('svg', { width: 12, height: 12, viewBox: '0 0 24 24', fill: 'none', stroke: 'currentColor', strokeWidth: 2, strokeLinecap: 'round', strokeLinejoin: 'round' },
        React.createElement('path', { d: 'M18 6 6 18' }),
        React.createElement('path', { d: 'm6 6 12 12' })
    ),
    FileCode: () => React.createElement('svg', { width: 16, height: 16, viewBox: '0 0 24 24', fill: 'none', stroke: 'currentColor', strokeWidth: 2, strokeLinecap: 'round', strokeLinejoin: 'round' },
        React.createElement('path', { d: 'M10 12.5 8 15l2 2.5' }),
        React.createElement('path', { d: 'm14 12.5 2 2.5-2 2.5' }),
        React.createElement('path', { d: 'M14 2v4a2 2 0 0 0 2 2h4' }),
        React.createElement('path', { d: 'M15 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V7z' })
    ),
    FileStack: () => React.createElement('svg', { width: 16, height: 16, viewBox: '0 0 24 24', fill: 'none', stroke: 'currentColor', strokeWidth: 2, strokeLinecap: 'round', strokeLinejoin: 'round' },
        React.createElement('path', { d: 'M21 7h-3a2 2 0 0 1-2-2V2' }),
        React.createElement('path', { d: 'M21 6v6.5c0 .8-.7 1.5-1.5 1.5h-7c-.8 0-1.5-.7-1.5-1.5v-9c0-.8.7-1.5 1.5-1.5H17Z' }),
        React.createElement('path', { d: 'M7 8v8.8c0 .3.2.6.4.8.2.2.5.4.8.4H15' }),
        React.createElement('path', { d: 'M3 12v8.8c0 .3.2.6.4.8.2.2.5.4.8.4H11' })
    ),
    ExternalLink: () => React.createElement('svg', { width: 12, height: 12, viewBox: '0 0 24 24', fill: 'none', stroke: 'currentColor', strokeWidth: 2, strokeLinecap: 'round', strokeLinejoin: 'round' },
        React.createElement('path', { d: 'M15 3h6v6' }),
        React.createElement('path', { d: 'M10 14 21 3' }),
        React.createElement('path', { d: 'M18 13v6a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h6' })
    ),
    Clock: () => React.createElement('svg', { width: 16, height: 16, viewBox: '0 0 24 24', fill: 'none', stroke: 'currentColor', strokeWidth: 2, strokeLinecap: 'round', strokeLinejoin: 'round' },
        React.createElement('circle', { cx: 12, cy: 12, r: 10 }),
        React.createElement('polyline', { points: '12 6 12 12 16 14' })
    ),
    Square: () => React.createElement('svg', { width: 12, height: 12, viewBox: '0 0 24 24', fill: 'none', stroke: 'currentColor', strokeWidth: 2, strokeLinecap: 'round', strokeLinejoin: 'round' },
        React.createElement('rect', { width: 18, height: 18, x: 3, y: 3, rx: 2 })
    ),
    Layers: () => React.createElement('svg', { width: 16, height: 16, viewBox: '0 0 24 24', fill: 'none', stroke: 'currentColor', strokeWidth: 2, strokeLinecap: 'round', strokeLinejoin: 'round' },
        React.createElement('path', { d: 'M12.83 2.18a2 2 0 0 0-1.66 0L2.6 6.08a1 1 0 0 0 0 1.83l8.58 3.91a2 2 0 0 0 1.66 0l8.58-3.9a1 1 0 0 0 0-1.83z' }),
        React.createElement('path', { d: 'M2 12a1 1 0 0 0 .58.91l8.6 3.91a2 2 0 0 0 1.65 0l8.58-3.9A1 1 0 0 0 22 12' }),
        React.createElement('path', { d: 'M2 17a1 1 0 0 0 .58.91l8.6 3.91a2 2 0 0 0 1.65 0l8.58-3.9A1 1 0 0 0 22 17' })
    ),
    File: () => React.createElement('svg', { width: 14, height: 14, viewBox: '0 0 24 24', fill: 'none', stroke: 'currentColor', strokeWidth: 2, strokeLinecap: 'round', strokeLinejoin: 'round' },
        React.createElement('path', { d: 'M15 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V7Z' }),
        React.createElement('path', { d: 'M14 2v4a2 2 0 0 0 2 2h4' })
    ),
    Filter: () => React.createElement('svg', { width: 12, height: 12, viewBox: '0 0 24 24', fill: 'none', stroke: 'currentColor', strokeWidth: 2, strokeLinecap: 'round', strokeLinejoin: 'round' },
        React.createElement('polygon', { points: '22 3 2 3 10 12.46 10 19 14 21 14 12.46 22 3' })
    ),
    Edit: () => React.createElement('svg', { width: 12, height: 12, viewBox: '0 0 24 24', fill: 'none', stroke: 'currentColor', strokeWidth: 2, strokeLinecap: 'round', strokeLinejoin: 'round' },
        React.createElement('path', { d: 'M21.174 6.812a1 1 0 0 0-3.986-3.987L3.842 16.174a2 2 0 0 0-.5.83l-1.321 4.352a.5.5 0 0 0 .623.622l4.353-1.32a2 2 0 0 0 .83-.497z' })
    ),
    Moon: () => React.createElement('svg', { width: 14, height: 14, viewBox: '0 0 24 24', fill: 'none', stroke: 'currentColor', strokeWidth: 2, strokeLinecap: 'round', strokeLinejoin: 'round' },
        React.createElement('path', { d: 'M12 3a6 6 0 0 0 9 9 9 9 0 1 1-9-9Z' })
    ),
    Power: () => React.createElement('svg', { width: 14, height: 14, viewBox: '0 0 24 24', fill: 'none', stroke: 'currentColor', strokeWidth: 2, strokeLinecap: 'round', strokeLinejoin: 'round' },
        React.createElement('path', { d: 'M12 2v10' }),
        React.createElement('path', { d: 'M18.4 6.6a9 9 0 1 1-12.77.04' })
    )
};

/* ============================================================
   UTILITY FUNCTIONS
   ============================================================ */
const formatDate = (d) => {
    if (!d) return '';
    const date = new Date(d);
    return date.toLocaleDateString('en-US', { year: 'numeric', month: 'short', day: 'numeric' });
};

const toTitleCase = (str) => {
    if (!str) return '';
    return str.replace(/-/g, ' ').replace(/\b\w/g, c => c.toUpperCase());
};

/* ============================================================
   SIDEBAR COMPONENT
   ============================================================ */
function Sidebar({ activeNav, onNavigate, collapsed, onToggleCollapse, sidebarMenu, expandedMenus, onToggleMenu }) {
    return React.createElement('aside', {
        className: `sidebar ${collapsed ? 'collapsed' : ''}`,
        'data-collapsed': collapsed ? 'true' : 'false'
    },
        /* Header */
        React.createElement('div', { className: 'sidebar-header' },
            React.createElement('div', { className: 'sidebar-brand' },
                React.createElement('div', { className: 'brand-mark' }, 'SH'),
                React.createElement('div', { className: 'brand-text' },
                    React.createElement('span', { className: 'brand-title' }, 'SERVICE HUB'),
                    React.createElement('span', { className: 'brand-sub' }, 'V8 Stable')
                )
            ),
            React.createElement('button', {
                className: 'btn-collapse',
                'aria-label': collapsed ? 'Expand sidebar' : 'Collapse sidebar',
                onClick: onToggleCollapse
            },
                React.createElement('span', { style: { fontSize: 14 } }, collapsed ? '▶' : '◀')
            )
        ),
        /* Navigation */
        React.createElement('nav', { className: 'sidebar-nav', role: 'navigation', 'aria-label': 'Main navigation' },
            sidebarMenu.map(section => {
                if (section.children) {
                    const isOpen = expandedMenus[section.label];
                    return React.createElement('div', { key: section.label },
                        React.createElement('div', {
                            className: `menu-item${isOpen ? ' open' : ''}`,
                            role: 'button',
                            tabIndex: 0,
                            onClick: () => onToggleMenu(section.label)
                        },
                            React.createElement('span', { className: 'menu-icon' },
                                React.createElement(section.icon || Icons.AppWindow)
                            ),
                            React.createElement('span', { className: 'menu-label' }, section.label),
                            React.createElement('span', { className: 'menu-chevron' },
                                isOpen ? React.createElement(Icons.ChevronDown) : React.createElement(Icons.ChevronRight)
                            )
                        ),
                        React.createElement('div', { className: 'submenu', style: { display: isOpen && !collapsed ? 'flex' : 'none' } },
                            section.children.map(child => {
                                const isActive = activeNav === child.id;
                                return React.createElement('div', {
                                    key: child.id,
                                    className: `submenu-item${isActive ? ' active' : ''}`,
                                    role: 'button',
                                    tabIndex: 0,
                                    onClick: () => onNavigate(child.id)
                                },
                                    React.createElement('span', { className: 'sub-icon' },
                                        React.createElement(Icons.FileCode)
                                    ),
                                    React.createElement('span', { className: 'sub-label' }, child.label)
                                );
                            })
                        )
                    );
                }
                // Flat item
                const isActive = activeNav === section.id;
                return React.createElement('div', {
                    key: section.id,
                    className: `menu-item${isActive ? ' active' : ''}`,
                    role: 'button',
                    tabIndex: 0,
                    onClick: () => onNavigate(section.id)
                },
                    React.createElement('span', { className: 'menu-icon' },
                        React.createElement(section.icon || Icons.Activity)
                    ),
                    React.createElement('span', { className: 'menu-label' }, section.label)
                );
            })
        ),
        /* Footer */
        React.createElement('div', { className: 'sidebar-footer' },
            React.createElement('div', { className: 'user-info' }, 'Admin • Priya Sharma')
        )
    );
}

/* ============================================================
   STATUS BADGE HELPER
   ============================================================ */
function StatusBadge({ status }) {
    let cls = 'status-badge ';
    let dotCls = 'dot ';
    if (status === 'enabled' || status === 'ok' || status === 'Active') {
        cls += 'status-enabled';
        dotCls += '';
    } else if (status === 'disabled' || status === 'Inactive') {
        cls += 'status-disabled';
        dotCls += '';
    } else if (status === 'down') {
        cls += 'status-down';
        dotCls += '';
    } else {
        cls += 'status-disabled';
    }
    return React.createElement('span', { className: cls },
        React.createElement('span', { className: dotCls }),
        status
    );
}

/* ============================================================
   SEARCH BOX COMPONENT
   ============================================================ */
function SearchBox({ value, onChange, placeholder }) {
    return React.createElement('div', { className: `search-box${value ? ' has-value' : ''}` },
        React.createElement('span', { className: 'search-icon' }, React.createElement(Icons.Search)),
        React.createElement('input', {
            type: 'text',
            value: value,
            onChange: e => onChange(e.target.value),
            placeholder: placeholder || 'Search...',
            'aria-label': 'Search'
        }),
        value ? React.createElement('button', {
            className: 'search-clear',
            onClick: () => onChange(''),
            'aria-label': 'Clear search'
        }, React.createElement(Icons.X)) : null
    );
}

/* ============================================================
   DASHBOARD COMPONENT
   ============================================================ */
function Dashboard({ onNavigate }) {
    const [typeFilter, setTypeFilter] = useState('All');
    const [sourceFilter, setSourceFilter] = useState('All');
    const [timeRange, setTimeRange] = useState('Today');

    const files = [
        { type: 'json', source: 'REST' }, { type: 'xml', source: 'REST' },
        { type: 'json', source: 'REST' }, { type: 'xml', source: 'SOAP' },
        { type: 'xml', source: 'SOAP' }, { type: 'json', source: 'SOAP' },
        { type: 'xml', source: 'REST' }, { type: 'json', source: 'REST' },
        { type: 'xml', source: 'REST' }
    ];

    const filteredCount = files.filter(f =>
        (typeFilter === 'All' || f.type === typeFilter.toLowerCase()) &&
        (sourceFilter === 'All' || f.source === sourceFilter)
    ).length;

    const executionCounts = { Today: 24, 'Last 2 Days': 58, 'Last 3 Days': 82, 'Last 30 Days': 412, Custom: 24 };
    const execCount = executionCounts[timeRange] || 0;

    return React.createElement('div', { className: 'dashboard-grid' },
        /* Files Card */
        React.createElement('div', { className: 'dash-card' },
            React.createElement('div', { className: 'card-header' },
                React.createElement('h3', { className: 'card-title' }, 'Files'),
                React.createElement(Icons.FileStack)
            ),
            React.createElement('div', { style: { display: 'flex', gap: 8, marginBottom: 12 } },
                React.createElement('select', {
                    value: typeFilter,
                    onChange: e => setTypeFilter(e.target.value),
                    className: 'form-control-dg',
                    style: { flex: 1, fontSize: 12 }
                },
                    React.createElement('option', null, 'All'),
                    React.createElement('option', null, 'XML'),
                    React.createElement('option', null, 'JSON')
                ),
                React.createElement('select', {
                    value: sourceFilter,
                    onChange: e => setSourceFilter(e.target.value),
                    className: 'form-control-dg',
                    style: { flex: 1, fontSize: 12 }
                },
                    React.createElement('option', null, 'All'),
                    React.createElement('option', null, 'REST'),
                    React.createElement('option', null, 'SOAP')
                )
            ),
            React.createElement('div', { className: 'card-value' },
                filteredCount,
                React.createElement('span', { style: { fontSize: 14, fontWeight: 400, color: 'var(--dg-text-soft)' } }, ` / ${files.length}`)
            ),
            React.createElement('div', { className: 'card-sub' }, `Filter: ${typeFilter} • ${sourceFilter}`),
            React.createElement('div', { style: { marginTop: 12, display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 8, fontSize: 12 } },
                React.createElement('div', { style: { border: '1px solid var(--dg-border)', padding: '6px 8px', display: 'flex', justifyContent: 'space-between' } },
                    React.createElement('span', null, 'XML'),
                    React.createElement('span', { style: { fontWeight: 600 } }, files.filter(f => f.type === 'xml').length)
                ),
                React.createElement('div', { style: { border: '1px solid var(--dg-border)', padding: '6px 8px', display: 'flex', justifyContent: 'space-between' } },
                    React.createElement('span', null, 'JSON'),
                    React.createElement('span', { style: { fontWeight: 600 } }, files.filter(f => f.type === 'json').length)
                ),
                React.createElement('div', { style: { border: '1px solid var(--dg-border)', padding: '6px 8px', display: 'flex', justifyContent: 'space-between' } },
                    React.createElement('span', null, 'REST'),
                    React.createElement('span', { style: { fontWeight: 600 } }, files.filter(f => f.source === 'REST').length)
                ),
                React.createElement('div', { style: { border: '1px solid var(--dg-border)', padding: '6px 8px', display: 'flex', justifyContent: 'space-between' } },
                    React.createElement('span', null, 'SOAP'),
                    React.createElement('span', { style: { fontWeight: 600 } }, files.filter(f => f.source === 'SOAP').length)
                )
            )
        ),

        /* Test Suites Card */
        React.createElement('div', { className: 'dash-card' },
            React.createElement('div', { className: 'card-header' },
                React.createElement('h3', { className: 'card-title' }, 'Test Suites'),
                React.createElement(Icons.Layers)
            ),
            React.createElement('div', { style: { fontSize: 12, lineHeight: 1.6, background: 'var(--dg-surface-2)', border: '1px solid var(--dg-border)', padding: 8, marginBottom: 12 } },
                '8 Suites • Avg 4.2 Test Cases/Suite • Avg 3.1 Files/Test Case'
            ),
            React.createElement('div', { style: { display: 'flex', flexDirection: 'column', gap: 6 } },
                SH_TEST_SUITES.map(s => React.createElement('div', {
                    key: s.name,
                    style: { display: 'flex', justifyContent: 'space-between', fontSize: 12, border: '1px solid var(--dg-border)', padding: '6px 8px' }
                },
                    React.createElement('span', { style: { fontWeight: 500 } }, s.name),
                    React.createElement('span', { style: { color: 'var(--dg-text-soft)', fontSize: 11 } }, `${s.cases} Cases • ${s.files} Files`)
                ))
            ),
            React.createElement('button', {
                onClick: () => onNavigate('test-suites'),
                style: { marginTop: 12, fontSize: 11, textDecoration: 'underline', background: 'none', border: 'none', color: 'var(--dg-accent)', cursor: 'pointer', padding: 0 }
            }, 'View all 8 suites →')
        ),

        /* Executions Card */
        React.createElement('div', { className: 'dash-card' },
            React.createElement('div', { className: 'card-header' },
                React.createElement('h3', { className: 'card-title' }, 'Executions'),
                React.createElement(Icons.Clock)
            ),
            React.createElement('select', {
                value: timeRange,
                onChange: e => setTimeRange(e.target.value),
                className: 'form-control-dg',
                style: { width: '100%', fontSize: 12, marginBottom: 12 }
            },
                React.createElement('option', null, 'Today'),
                React.createElement('option', null, 'Last 2 Days'),
                React.createElement('option', null, 'Last 3 Days'),
                React.createElement('option', null, 'Last 30 Days'),
                React.createElement('option', null, 'Custom')
            ),
            React.createElement('div', { className: 'card-value' }, execCount),
            React.createElement('div', { className: 'card-sub' }, `${timeRange} executions • 92% pass rate`),
            React.createElement('div', { style: { marginTop: 12, height: 8, background: 'var(--dg-surface-3)', display: 'flex' } },
                React.createElement('div', { style: { width: '92%', background: '#059669' } }),
                React.createElement('div', { style: { width: '8%', background: '#dc2626' } })
            ),
            React.createElement('div', { style: { marginTop: 6, display: 'flex', gap: 12, fontSize: 11 } },
                React.createElement('span', null,
                    React.createElement('span', { style: { width: 8, height: 8, background: '#059669', display: 'inline-block', marginRight: 4 } }), ' Passed'
                ),
                React.createElement('span', null,
                    React.createElement('span', { style: { width: 8, height: 8, background: '#dc2626', display: 'inline-block', marginRight: 4 } }), ' Failed'
                )
            )
        ),

        /* Health Card */
        React.createElement('div', { className: 'dash-card' },
            React.createElement('div', { className: 'card-header' },
                React.createElement('h3', { className: 'card-title' }, 'Health'),
                React.createElement(Icons.Activity)
            ),
            React.createElement('div', { style: { display: 'flex', alignItems: 'center', gap: 8, marginBottom: 8 } },
                React.createElement('span', { style: { fontSize: 28, fontWeight: 700 } }, '12'),
                React.createElement('span', { style: { fontSize: 12, color: 'var(--dg-text-soft)' } }, 'Total Services'),
                React.createElement('span', { style: { marginLeft: 'auto', background: '#dc2626', color: '#fff', fontSize: 11, padding: '2px 6px', fontWeight: 600 } }, '2 down')
            ),
            React.createElement('div', { style: { display: 'flex', flexDirection: 'column', gap: 6 } },
                SH_HEALTH.map(h => React.createElement('div', {
                    key: h.name,
                    style: { display: 'flex', justifyContent: 'space-between', fontSize: 12, border: '1px solid var(--dg-border)', padding: '4px 8px' }
                },
                    React.createElement('span', null, h.name),
                    React.createElement(StatusBadge, { status: h.status })
                ))
            )
        ),

        /* Recent Activity */
        React.createElement('div', { className: 'dash-card', style: { gridColumn: 'span 2' } },
            React.createElement('div', { className: 'card-header' },
                React.createElement('h3', { className: 'card-title' }, 'Recent Activity')
            ),
            React.createElement('div', { style: { display: 'flex', flexDirection: 'column', gap: 8 } },
                SH_ACTIVITY_LOG.map((a, i) => React.createElement('div', {
                    key: i,
                    style: { fontSize: 12, lineHeight: 1.5, borderLeft: '2px solid var(--dg-primary)', padding: '6px 10px', background: 'var(--dg-surface-2)' }
                }, `${a.user} ${a.action} ${a.time}`))
            )
        ),

        /* Stats Row */
        React.createElement('div', { className: 'dash-card dash-card-dark' },
            React.createElement('div', { className: 'card-title' }, 'REST Applications'),
            React.createElement('div', { className: 'card-value' }, SH_REST_APPS.length),
            React.createElement('div', { className: 'card-sub' },
                `${SH_REST_APPS.filter(a => a.status === 'enabled').length} enabled • ${SH_REST_APPS.filter(a => a.status === 'disabled').length} disabled`
            )
        ),
        React.createElement('div', { className: 'dash-card dash-card-dark' },
            React.createElement('div', { className: 'card-title' }, 'SOAP Applications'),
            React.createElement('div', { className: 'card-value' }, SH_SOAP_APPS.length),
            React.createElement('div', { className: 'card-sub' }, 'File type always XML')
        ),
        React.createElement('div', { className: 'dash-card', style: { display: 'flex', alignItems: 'center', justifyContent: 'space-between' } },
            React.createElement('div', null,
                React.createElement('div', { style: { fontSize: 11, textTransform: 'uppercase', letterSpacing: '.05em' } }, 'Quick Actions'),
                React.createElement('div', { style: { fontSize: 12, color: 'var(--dg-text-soft)', marginTop: 4 } }, 'Jump to most used')
            ),
            React.createElement('div', { style: { display: 'flex', gap: 8 } },
                React.createElement('button', { onClick: () => onNavigate('file-library'), className: 'btn-dg', style: { fontSize: 12 } }, 'File Library'),
                React.createElement('button', { onClick: () => onNavigate('rest-execute'), className: 'btn-dg btn-dg-primary', style: { fontSize: 12 } }, 'Execute History')
            )
        )
    );
}

/* ============================================================
   APPLICATIONS TABLE COMPONENT (REST & SOAP)
   ============================================================ */
function ApplicationsTable({ apps, setApps, isSoap }) {
    const [selected, setSelected] = useState([]);
    const [sortKey, setSortKey] = useState(null);
    const [sortDir, setSortDir] = useState('asc');
    const [search, setSearch] = useState('');
    const [showModal, setShowModal] = useState(false);
    const [editApp, setEditApp] = useState(null);
    const [filterStatus, setFilterStatus] = useState('All');
    const [form, setForm] = useState({ name: '', baseUrl: '', status: 'enabled', lastUpdatedBy: 'Priya Sharma', createdDate: new Date().toISOString().slice(0, 10), summary: '' });

    // Filtered & sorted data
    const filtered = useMemo(() => {
        let data = [...apps];
        if (search) {
            const q = search.toLowerCase();
            data = data.filter(a =>
                a.name.toLowerCase().includes(q) ||
                a.baseUrl.toLowerCase().includes(q) ||
                (a.lastUpdatedBy || '').toLowerCase().includes(q)
            );
        }
        if (filterStatus !== 'All') {
            data = data.filter(a => a.status === filterStatus);
        }
        if (sortKey) {
            data.sort((a, b) => {
                let av = (a[sortKey] || '').toString().toLowerCase();
                let bv = (b[sortKey] || '').toString().toLowerCase();
                if (av < bv) return sortDir === 'asc' ? -1 : 1;
                if (av > bv) return sortDir === 'asc' ? 1 : -1;
                return 0;
            });
        }
        return data;
    }, [apps, search, sortKey, sortDir, filterStatus]);

    const toggleSort = (key) => {
        if (sortKey === key) setSortDir(d => d === 'asc' ? 'desc' : 'asc');
        else { setSortKey(key); setSortDir('asc'); }
    };

    const toggleSelect = (id) => {
        setSelected(s => s.includes(id) ? s.filter(x => x !== id) : [...s, id]);
    };

    const toggleAll = () => {
        if (selected.length === filtered.length) setSelected([]);
        else setSelected(filtered.map(a => a.id));
    };

    const toggleStatus = (id) => {
        setApps(prev => prev.map(a => a.id === id ? { ...a, status: a.status === 'enabled' ? 'disabled' : 'enabled' } : a));
    };

    const openEdit = (app) => {
        setEditApp(app);
        setForm({ name: app.name, baseUrl: app.baseUrl, status: app.status, lastUpdatedBy: app.lastUpdatedBy || 'Priya Sharma', createdDate: app.createdDate, summary: app.summary || '' });
        setShowModal(true);
    };

    const handleSave = () => {
        if (!form.name || !form.baseUrl) { alert('Name and Base URL required'); return; }
        if (editApp) {
            setApps(prev => prev.map(a => a.id === editApp.id ? { ...a, ...form } : a));
        } else {
            const newApp = {
                id: Date.now().toString(),
                ...form,
                apisCount: 0,
                apis: []
            };
            setApps(prev => [...prev, newApp]);
        }
        setShowModal(false);
        setEditApp(null);
    };

    const deleteSelected = () => {
        if (selected.length === 0) { alert('Select rows first'); return; }
        if (!confirm(`Delete ${selected.length} selected?`)) return;
        setApps(prev => prev.filter(a => !selected.includes(a.id)));
        setSelected([]);
    };

    const exportCSV = () => {
        const headers = ['App Name', 'Base URL', 'Status', 'Last Updated By', 'Created Date', 'APIs'];
        const rows = filtered.map(a => [a.name, a.baseUrl, a.status, a.lastUpdatedBy || '', a.createdDate, String(a.apisCount)]);
        const csv = [headers, ...rows].map(r => r.map(c => `"${c}"`).join(',')).join('\n');
        const blob = new Blob([csv], { type: 'text/csv' });
        const url = URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        a.download = `${isSoap ? 'soap' : 'rest'}_applications.csv`;
        a.click();
        URL.revokeObjectURL(url);
    };

    const exportJSON = () => {
        const blob = new Blob([JSON.stringify(filtered, null, 2)], { type: 'application/json' });
        const url = URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        a.download = `${isSoap ? 'soap' : 'rest'}_applications.json`;
        a.click();
        URL.revokeObjectURL(url);
    };

    return React.createElement('div', { className: 'datagrid-card' },
        /* Toolbar */
        React.createElement('div', { className: 'grid-toolbar' },
            React.createElement('div', { className: 'toolbar-left' },
                React.createElement(SearchBox, { value: search, onChange: setSearch }),
                React.createElement('div', { className: 'meta-group' },
                    React.createElement('span', { className: 'meta-pill' },
                        React.createElement('span', null, filtered.length), ' records'
                    ),
                    React.createElement('span', { className: 'meta-sep' }),
                    React.createElement('span', { className: 'meta-pill selected' },
                        React.createElement('span', null, selected.length), ' selected'
                    )
                ),
                React.createElement('select', {
                    value: filterStatus,
                    onChange: e => setFilterStatus(e.target.value),
                    style: { height: 36, border: '1px solid var(--dg-border)', background: 'var(--dg-input-bg)', fontSize: 12, padding: '0 8px', color: 'var(--dg-text)' }
                },
                    React.createElement('option', { value: 'All' }, 'All Status'),
                    React.createElement('option', { value: 'enabled' }, 'Enabled'),
                    React.createElement('option', { value: 'disabled' }, 'Disabled')
                )
            ),
            React.createElement('div', { className: 'toolbar-right' },
                React.createElement('button', { onClick: () => { setEditApp(null); setForm({ name: '', baseUrl: '', status: 'enabled', lastUpdatedBy: 'Priya Sharma', createdDate: new Date().toISOString().slice(0, 10), summary: '' }); setShowModal(true); }, className: 'btn-dg btn-dg-primary', style: { fontSize: 12 } },
                    React.createElement(Icons.Plus), ' Add Application'
                ),
                React.createElement('button', { onClick: exportCSV, className: 'btn-dg', style: { fontSize: 12 } },
                    React.createElement(Icons.Download), ' CSV'
                ),
                React.createElement('button', { onClick: exportJSON, className: 'btn-dg', style: { fontSize: 12 } },
                    React.createElement(Icons.FileJson), ' JSON'
                ),
                React.createElement('button', { onClick: deleteSelected, className: 'btn-dg', style: { fontSize: 12, color: '#dc2626', borderColor: '#fecaca' } },
                    React.createElement(Icons.Trash2), ` Delete (${selected.length})`
                )
            )
        ),

        /* Table */
        React.createElement('div', { className: 'table-wrap' },
            React.createElement('table', { className: 'datagrid' },
                React.createElement('thead', null,
                    React.createElement('tr', null,
                        React.createElement('th', { className: 'check-cell' },
                            React.createElement('input', {
                                type: 'checkbox',
                                className: 'form-check-input',
                                checked: selected.length === filtered.length && filtered.length > 0,
                                onChange: toggleAll,
                                'aria-label': 'Select all'
                            })
                        ),
                        React.createElement('th', { className: 'sortable', onClick: () => toggleSort('name') },
                            React.createElement('span', { className: 'th-inner' }, 'App Name',
                                React.createElement('span', { className: 'sort-indicator' },
                                    React.createElement(Icons.ArrowUpDown)
                                )
                            )
                        ),
                        React.createElement('th', { className: 'sortable', onClick: () => toggleSort('baseUrl') },
                            React.createElement('span', { className: 'th-inner' }, 'Base URL',
                                React.createElement('span', { className: 'sort-indicator' },
                                    React.createElement(Icons.ArrowUpDown)
                                )
                            )
                        ),
                        React.createElement('th', { className: 'sortable', onClick: () => toggleSort('status') },
                            React.createElement('span', { className: 'th-inner' }, 'Status',
                                React.createElement('span', { className: 'sort-indicator' },
                                    React.createElement(Icons.ArrowUpDown)
                                )
                            )
                        ),
                        React.createElement('th', null, 'Last Updated'),
                        React.createElement('th', null, 'Created'),
                        React.createElement('th', { className: 'sortable', onClick: () => toggleSort('apisCount') },
                            React.createElement('span', { className: 'th-inner' }, 'APIs',
                                React.createElement('span', { className: 'sort-indicator' },
                                    React.createElement(Icons.ArrowUpDown)
                                )
                            )
                        ),
                        React.createElement('th', { style: { textAlign: 'right' } }, 'Actions')
                    )
                ),
                React.createElement('tbody', null,
                    filtered.length === 0 ?
                        React.createElement('tr', null,
                            React.createElement('td', { colSpan: 8, style: { padding: 32, textAlign: 'center', color: 'var(--dg-text-soft)' } }, 'No applications found')
                        ) :
                        filtered.map(app => React.createElement('tr', {
                            key: app.id,
                            className: selected.includes(app.id) ? 'is-selected' : ''
                        },
                            React.createElement('td', { className: 'check-cell' },
                                React.createElement('input', {
                                    type: 'checkbox',
                                    className: 'form-check-input',
                                    checked: selected.includes(app.id),
                                    onChange: () => toggleSelect(app.id)
                                })
                            ),
                            React.createElement('td', null,
                                React.createElement('span', { className: 'name-stack' },
                                    React.createElement('span', { className: 'avatar-sm' }, app.name.substring(0, 2).toUpperCase()),
                                    React.createElement('span', { style: { fontWeight: 500 } }, app.name)
                                )
                            ),
                            React.createElement('td', null,
                                React.createElement('span', { className: 'cell-id' }, app.baseUrl)
                            ),
                            React.createElement('td', null, React.createElement(StatusBadge, { status: app.status })),
                            React.createElement('td', null, app.lastUpdatedBy || '-'),
                            React.createElement('td', null, formatDate(app.createdDate)),
                            React.createElement('td', null, React.createElement('span', { style: { fontWeight: 600 } }, app.apisCount)),
                            React.createElement('td', { style: { textAlign: 'right' } },
                                React.createElement('button', {
                                    onClick: () => openEdit(app),
                                    className: 'btn-dg btn-dg-ghost',
                                    style: { height: 28, fontSize: 11 },
                                    'aria-label': 'Edit'
                                }, React.createElement(Icons.Edit)),
                                React.createElement('button', {
                                    onClick: () => toggleStatus(app.id),
                                    className: 'btn-dg btn-dg-ghost',
                                    style: { height: 28, fontSize: 11, color: app.status === 'enabled' ? '#dc2626' : '#059669' },
                                    'aria-label': app.status === 'enabled' ? 'Disable' : 'Enable'
                                }, app.status === 'enabled' ? 'Disable' : 'Enable')
                            )
                        ))
                )
            )
        ),

        /* Modal */
        showModal && React.createElement('div', { className: 'modal-overlay', onClick: () => setShowModal(false) },
            React.createElement('div', { className: 'modal-content-dg', onClick: e => e.stopPropagation() },
                React.createElement('div', { className: 'modal-header-dg' },
                    React.createElement('h3', null, editApp ? 'Edit Application' : 'Add Application'),
                    React.createElement('button', { onClick: () => setShowModal(false), className: 'btn-dg btn-dg-ghost btn-dg-icon', 'aria-label': 'Close' },
                        React.createElement(Icons.X)
                    )
                ),
                React.createElement('div', { className: 'modal-body-dg' },
                    React.createElement('div', { className: 'form-group' },
                        React.createElement('label', null, 'App Name'),
                        React.createElement('input', {
                            className: 'form-control-dg',
                            value: form.name,
                            onChange: e => setForm(f => ({ ...f, name: e.target.value })),
                            placeholder: 'e.g. PaymentService'
                        })
                    ),
                    React.createElement('div', { className: 'form-group' },
                        React.createElement('label', null, 'Base URL'),
                        React.createElement('input', {
                            className: 'form-control-dg',
                            value: form.baseUrl,
                            onChange: e => setForm(f => ({ ...f, baseUrl: e.target.value })),
                            placeholder: 'e.g. https://api.example.com/v1'
                        })
                    ),
                    React.createElement('div', { className: 'form-group' },
                        React.createElement('label', null, 'Status'),
                        React.createElement('select', {
                            className: 'form-control-dg',
                            value: form.status,
                            onChange: e => setForm(f => ({ ...f, status: e.target.value }))
                        },
                            React.createElement('option', { value: 'enabled' }, 'Enabled'),
                            React.createElement('option', { value: 'disabled' }, 'Disabled')
                        )
                    ),
                    React.createElement('div', { className: 'form-group' },
                        React.createElement('label', null, 'Summary'),
                        React.createElement('textarea', {
                            className: 'form-control-dg textarea',
                            value: form.summary,
                            onChange: e => setForm(f => ({ ...f, summary: e.target.value })),
                            placeholder: 'Brief description...'
                        })
                    )
                ),
                React.createElement('div', { className: 'modal-footer-dg' },
                    React.createElement('button', { onClick: () => setShowModal(false), className: 'btn-dg' }, 'Cancel'),
                    React.createElement('button', { onClick: handleSave, className: 'btn-dg btn-dg-primary' }, editApp ? 'Save Changes' : 'Create')
                )
            )
        )
    );
}

/* ============================================================
   REQUEST FILES COMPONENT
   ============================================================ */
function RequestFiles({ files, isSoap, onNavigate }) {
    const [search, setSearch] = useState('');
    const [sortKey, setSortKey] = useState(null);
    const [sortDir, setSortDir] = useState('asc');

    const filtered = useMemo(() => {
        let data = [...files];
        if (search) {
            const q = search.toLowerCase();
            data = data.filter(f =>
                f.fileName.toLowerCase().includes(q) ||
                f.appName.toLowerCase().includes(q) ||
                f.description.toLowerCase().includes(q)
            );
        }
        if (sortKey) {
            data.sort((a, b) => {
                let av = (a[sortKey] || '').toString().toLowerCase();
                let bv = (b[sortKey] || '').toString().toLowerCase();
                if (av < bv) return sortDir === 'asc' ? -1 : 1;
                if (av > bv) return sortDir === 'asc' ? 1 : -1;
                return 0;
            });
        }
        return data;
    }, [files, search, sortKey, sortDir]);

    const toggleSort = (key) => {
        if (sortKey === key) setSortDir(d => d === 'asc' ? 'desc' : 'asc');
        else { setSortKey(key); setSortDir('asc'); }
    };

    return React.createElement('div', { className: 'datagrid-card' },
        React.createElement('div', { className: 'grid-toolbar' },
            React.createElement('div', { className: 'toolbar-left' },
                React.createElement(SearchBox, { value: search, onChange: setSearch }),
                React.createElement('div', { className: 'meta-group' },
                    React.createElement('span', { className: 'meta-pill' },
                        React.createElement('span', null, filtered.length), ' files'
                    )
                )
            ),
            React.createElement('div', { className: 'toolbar-right' },
                React.createElement('span', { style: { fontSize: 12, color: 'var(--dg-text-soft)' } },
                    `${files.filter(f => f.type === 'json').length} JSON • ${files.filter(f => f.type === 'xml').length} XML`
                )
            )
        ),
        React.createElement('div', { className: 'table-wrap' },
            React.createElement('table', { className: 'datagrid' },
                React.createElement('thead', null,
                    React.createElement('tr', null,
                        React.createElement('th', { className: 'sortable', onClick: () => toggleSort('fileName') },
                            React.createElement('span', { className: 'th-inner' }, 'File Name',
                                React.createElement(Icons.ArrowUpDown)
                            )
                        ),
                        React.createElement('th', null, 'Application'),
                        React.createElement('th', null, 'API Path'),
                        React.createElement('th', null, 'Verb'),
                        React.createElement('th', null, 'Description'),
                        React.createElement('th', { className: 'sortable', onClick: () => toggleSort('type') },
                            React.createElement('span', { className: 'th-inner' }, 'Type',
                                React.createElement(Icons.ArrowUpDown)
                            )
                        ),
                        React.createElement('th', null, 'Created')
                    )
                ),
                React.createElement('tbody', null,
                    filtered.length === 0 ?
                        React.createElement('tr', null,
                            React.createElement('td', { colSpan: 7, style: { padding: 32, textAlign: 'center', color: 'var(--dg-text-soft)' } }, 'No request files found')
                        ) :
                        filtered.map(f => React.createElement('tr', { key: f.id },
                            React.createElement('td', null,
                                React.createElement('span', { style: { fontFamily: "'JetBrains Mono', monospace", fontSize: 12 } }, f.fileName)
                            ),
                            React.createElement('td', null,
                                React.createElement('span', { className: 'name-stack' },
                                    React.createElement('span', { className: 'avatar-sm' }, f.appName.substring(0, 2).toUpperCase()),
                                    React.createElement('span', null, f.appName)
                                )
                            ),
                            React.createElement('td', null,
                                React.createElement('span', { className: 'cell-id' }, f.apiPath)
                            ),
                            React.createElement('td', null,
                                React.createElement('span', {
                                    style: {
                                        display: 'inline-block',
                                        padding: '1px 6px',
                                        fontSize: 10,
                                        fontWeight: 600,
                                        border: '1px solid var(--dg-border)',
                                        background: f.verb === 'POST' ? '#ecfdf5' : f.verb === 'GET' ? '#eff6ff' : f.verb === 'DELETE' ? '#fef2f2' : 'var(--dg-surface-2)',
                                        color: f.verb === 'POST' ? '#065f46' : f.verb === 'GET' ? '#1d4ed8' : f.verb === 'DELETE' ? '#991b1b' : 'var(--dg-text)'
                                    }
                                }, f.verb)
                            ),
                            React.createElement('td', { style: { fontSize: 12, color: 'var(--dg-text-soft)', maxWidth: 200, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' } }, f.description),
                            React.createElement('td', null,
                                React.createElement('span', { className: f.type === 'json' ? 'status-badge status-enabled' : 'status-badge status-disabled', style: { fontSize: 10, height: 20 } }, f.type)
                            ),
                            React.createElement('td', null, formatDate(f.createdDate))
                        ))
                )
            )
        )
    );
}

/* ============================================================
   TEMPLATES COMPONENT
   ============================================================ */
function Templates({ isSoap }) {
    const templates = [
        { name: isSoap ? 'SOAP Envelope Template' : 'Payment Success Template', type: isSoap ? 'xml' : 'json', created: '2024-03-15', usage: 24 },
        { name: isSoap ? 'WSDL Request Base' : 'User Query Template', type: isSoap ? 'xml' : 'json', created: '2024-03-20', usage: 18 },
        { name: isSoap ? 'SOAP Fault Handler' : 'Error Response Template', type: isSoap ? 'xml' : 'json', created: '2024-04-01', usage: 12 }
    ];

    return React.createElement('div', { className: 'datagrid-card' },
        React.createElement('div', { className: 'grid-toolbar' },
            React.createElement('div', { className: 'toolbar-left' },
                React.createElement('span', { className: 'meta-pill' },
                    React.createElement('span', null, templates.length), ` ${isSoap ? 'SOAP' : 'REST'} templates`
                )
            ),
            React.createElement('div', { className: 'toolbar-right' },
                React.createElement('button', { className: 'btn-dg btn-dg-primary', style: { fontSize: 12 } },
                    React.createElement(Icons.Plus), ' New Template'
                )
            )
        ),
        React.createElement('div', { className: 'table-wrap' },
            React.createElement('table', { className: 'datagrid' },
                React.createElement('thead', null,
                    React.createElement('tr', null,
                        React.createElement('th', null, 'Template Name'),
                        React.createElement('th', null, 'Type'),
                        React.createElement('th', null, 'Created'),
                        React.createElement('th', null, 'Usage'),
                        React.createElement('th', { style: { textAlign: 'right' } }, 'Actions')
                    )
                ),
                React.createElement('tbody', null,
                    templates.map(t => React.createElement('tr', { key: t.name },
                        React.createElement('td', null,
                            React.createElement('span', { className: 'name-stack' },
                                React.createElement('span', { className: 'avatar-sm' }, t.name.substring(0, 2)),
                                React.createElement('span', { style: { fontWeight: 500 } }, t.name)
                            )
                        ),
                        React.createElement('td', null,
                            React.createElement('span', { className: t.type === 'json' ? 'status-badge status-enabled' : 'status-badge status-disabled', style: { fontSize: 10, height: 20 } }, t.type)
                        ),
                        React.createElement('td', null, formatDate(t.created)),
                        React.createElement('td', null, React.createElement('span', { style: { fontWeight: 600 } }, `${t.usage}x`)),
                        React.createElement('td', { style: { textAlign: 'right' } },
                            React.createElement('button', { className: 'btn-dg btn-dg-ghost', style: { height: 28, fontSize: 11 } },
                                React.createElement(Icons.Edit), ' Edit'
                            )
                        )
                    ))
                )
            )
        )
    );
}

/* ============================================================
   EXECUTE & HISTORY COMPONENT
   ============================================================ */
function ExecuteHistory({ isSoap }) {
    const history = [
        { id: 'EX-001', app: isSoap ? 'LegacyBilling' : 'PaymentService', status: 'passed', duration: '1.2s', date: '2024-04-05', by: 'Priya Sharma' },
        { id: 'EX-002', app: isSoap ? 'ShippingSOAP' : 'UserManagement', status: 'failed', duration: '0.8s', date: '2024-04-05', by: 'Rahul Patel' },
        { id: 'EX-003', app: isSoap ? 'LegacyBilling' : 'OrderService', status: 'passed', duration: '0.9s', date: '2024-04-04', by: 'Vikram Singh' },
        { id: 'EX-004', app: isSoap ? 'LegacyBilling' : 'PaymentService', status: 'passed', duration: '1.1s', date: '2024-04-03', by: 'System' }
    ];

    return React.createElement('div', { className: 'datagrid-card' },
        React.createElement('div', { className: 'grid-toolbar' },
            React.createElement('div', { className: 'toolbar-left' },
                React.createElement('span', { className: 'meta-pill selected' },
                    React.createElement('span', null, history.length), ' executions'
                ),
                React.createElement('span', { className: 'meta-pill' },
                    '92% pass rate'
                )
            ),
            React.createElement('div', { className: 'toolbar-right' },
                React.createElement('button', { className: 'btn-dg', style: { fontSize: 12 } },
                    React.createElement(Icons.Plus), ' Execute Now'
                )
            )
        ),
        React.createElement('div', { className: 'table-wrap' },
            React.createElement('table', { className: 'datagrid' },
                React.createElement('thead', null,
                    React.createElement('tr', null,
                        React.createElement('th', null, 'Execution ID'),
                        React.createElement('th', null, 'Application'),
                        React.createElement('th', null, 'Status'),
                        React.createElement('th', null, 'Duration'),
                        React.createElement('th', null, 'Date'),
                        React.createElement('th', null, 'Triggered By')
                    )
                ),
                React.createElement('tbody', null,
                    history.map(h => React.createElement('tr', { key: h.id },
                        React.createElement('td', null, React.createElement('span', { className: 'cell-id' }, h.id)),
                        React.createElement('td', null, h.app),
                        React.createElement('td', null, React.createElement(StatusBadge, { status: h.status === 'passed' ? 'enabled' : 'down' })),
                        React.createElement('td', null, h.duration),
                        React.createElement('td', null, formatDate(h.date)),
                        React.createElement('td', null, h.by)
                    ))
                )
            )
        )
    );
}

/* ============================================================
   FILE LIBRARY COMPONENT
   ============================================================ */
function FileLibrary() {
    const files = [
        { name: 'payment_create_001.json', app: 'PaymentService', type: 'json', size: '2.4 KB', linked: 'Test Case TC-01' },
        { name: 'user_list_filter.xml', app: 'UserManagement', type: 'xml', size: '1.8 KB', linked: 'Test Case TC-02' },
        { name: 'invoice_create.xml', app: 'LegacyBilling', type: 'xml', size: '3.2 KB', linked: 'Test Case TC-03' },
        { name: 'stock_update_003.json', app: 'InventoryAPI', type: 'json', size: '1.1 KB', linked: 'Test Case TC-04' }
    ];

    return React.createElement('div', { className: 'datagrid-card' },
        React.createElement('div', { className: 'grid-toolbar' },
            React.createElement('div', { className: 'toolbar-left' },
                React.createElement('span', { className: 'meta-pill' },
                    React.createElement('span', null, files.length), ' files'
                ),
                React.createElement('span', { style: { fontSize: 12, color: 'var(--dg-text-soft)' } },
                    'Linked to Test Suites, Test Cases, Execution History'
                )
            ),
            React.createElement('div', { className: 'toolbar-right' },
                React.createElement('button', { className: 'btn-dg btn-dg-primary', style: { fontSize: 12 } },
                    React.createElement(Icons.Plus), ' Upload File'
                )
            )
        ),
        React.createElement('div', { className: 'table-wrap' },
            React.createElement('table', { className: 'datagrid' },
                React.createElement('thead', null,
                    React.createElement('tr', null,
                        React.createElement('th', null, 'File Name'),
                        React.createElement('th', null, 'Application'),
                        React.createElement('th', null, 'Type'),
                        React.createElement('th', null, 'Size'),
                        React.createElement('th', null, 'Linked To'),
                        React.createElement('th', { style: { textAlign: 'right' } }, 'Actions')
                    )
                ),
                React.createElement('tbody', null,
                    files.map(f => React.createElement('tr', { key: f.name },
                        React.createElement('td', null,
                            React.createElement('span', { className: 'name-stack' },
                                React.createElement('span', { className: 'avatar-sm' }, f.type === 'json' ? '{ }' : '<>'),
                                React.createElement('span', { style: { fontFamily: "'JetBrains Mono', monospace", fontSize: 12 } }, f.name)
                            )
                        ),
                        React.createElement('td', null, f.app),
                        React.createElement('td', null,
                            React.createElement('span', { className: f.type === 'json' ? 'status-badge status-enabled' : 'status-badge status-disabled', style: { fontSize: 10, height: 20 } }, f.type)
                        ),
                        React.createElement('td', null, f.size),
                        React.createElement('td', null,
                            React.createElement('span', { className: 'cell-id' }, f.linked)
                        ),
                        React.createElement('td', { style: { textAlign: 'right' } },
                            React.createElement('button', { className: 'btn-dg btn-dg-ghost', style: { height: 28, fontSize: 11 } },
                                React.createElement(Icons.ExternalLink), ' View'
                            )
                        )
                    ))
                )
            )
        )
    );
}

/* ============================================================
   FILE BROWSER COMPONENT
   ============================================================ */
function FileBrowser() {
    const dirs = [
        { name: 'requests/', type: 'dir', modified: '2024-04-05', size: '-' },
        { name: 'responses/', type: 'dir', modified: '2024-04-05', size: '-' },
        { name: 'templates/', type: 'dir', modified: '2024-04-04', size: '-' },
        { name: 'payment_create_001.json', type: 'file', modified: '2024-04-05', size: '2.4 KB' },
        { name: 'user_list_filter.xml', type: 'file', modified: '2024-04-02', size: '1.8 KB' },
        { name: 'invoice_create.xml', type: 'file', modified: '2024-03-20', size: '3.2 KB' }
    ];

    return React.createElement('div', { className: 'datagrid-card' },
        React.createElement('div', { className: 'grid-toolbar' },
            React.createElement('div', { className: 'toolbar-left' },
                React.createElement(SearchBox, { value: '', onChange: () => { } }),
                React.createElement('span', { className: 'meta-pill' },
                    React.createElement('span', null, dirs.length), ' items'
                )
            ),
            React.createElement('div', { className: 'toolbar-right' },
                React.createElement('span', { style: { fontSize: 12, color: 'var(--dg-text-soft)' } }, 'WebDAV • /shared/api_files/')
            )
        ),
        React.createElement('div', { className: 'table-wrap' },
            React.createElement('table', { className: 'datagrid' },
                React.createElement('thead', null,
                    React.createElement('tr', null,
                        React.createElement('th', null, 'Name'),
                        React.createElement('th', null, 'Type'),
                        React.createElement('th', null, 'Modified'),
                        React.createElement('th', null, 'Size')
                    )
                ),
                React.createElement('tbody', null,
                    dirs.map(d => React.createElement('tr', { key: d.name },
                        React.createElement('td', null,
                            React.createElement('span', { className: 'name-stack' },
                                React.createElement('span', { className: 'avatar-sm', style: { fontSize: 12, fontFamily: 'monospace' } },
                                    d.type === 'dir' ? '📁' : '📄'
                                ),
                                React.createElement('span', { style: { fontFamily: d.type === 'dir' ? 'inherit' : "'JetBrains Mono', monospace", fontSize: d.type === 'dir' ? 13 : 12, fontWeight: d.type === 'dir' ? 500 : 400 } }, d.name)
                            )
                        ),
                        React.createElement('td', null,
                            React.createElement('span', { className: 'status-badge status-disabled', style: { fontSize: 10, height: 20 } }, d.type)
                        ),
                        React.createElement('td', null, formatDate(d.modified)),
                        React.createElement('td', null, d.size)
                    ))
                )
            )
        )
    );
}

/* ============================================================
   FILE VIEWER COMPONENT
   ============================================================ */
function FileViewer() {
    return React.createElement('div', { className: 'datagrid-card' },
        React.createElement('div', { className: 'grid-toolbar' },
            React.createElement('div', { className: 'toolbar-left' },
                React.createElement('span', { className: 'meta-pill' }, 'PDF/XML/JSON Viewer'),
                React.createElement('span', { style: { fontSize: 12, color: 'var(--dg-text-soft)' } }, 'Select a file to preview')
            )
        ),
        React.createElement('div', { style: { padding: 48, textAlign: 'center', color: 'var(--dg-text-soft)' } },
            React.createElement('div', { style: { fontSize: 32, marginBottom: 12, opacity: .3 } }, '📄'),
            React.createElement('div', { style: { fontWeight: 600, color: 'var(--dg-text)' } }, 'No file selected'),
            React.createElement('div', { style: { fontSize: 12, marginTop: 4 } }, 'Select a file from the File Library or File Browser to preview its contents here.')
        )
    );
}

/* ============================================================
   HEALTH DASHBOARD COMPONENT
   ============================================================ */
function HealthDashboard() {
    return React.createElement('div', { className: 'dashboard-grid' },
        React.createElement('div', { className: 'dash-card' },
            React.createElement('div', { className: 'card-header' },
                React.createElement('h3', { className: 'card-title' }, 'Service Health'),
                React.createElement(Icons.Activity)
            ),
            React.createElement('div', { className: 'card-value' }, SH_HEALTH.filter(h => h.status === 'ok').length, '/', SH_HEALTH.length),
            React.createElement('div', { className: 'card-sub' }, `${SH_HEALTH.filter(h => h.status === 'ok').length} healthy • ${SH_HEALTH.filter(h => h.status === 'down').length} down`),
            React.createElement('div', { style: { marginTop: 12, display: 'flex', flexDirection: 'column', gap: 6 } },
                SH_HEALTH.map(h => React.createElement('div', {
                    key: h.name,
                    style: { display: 'flex', justifyContent: 'space-between', fontSize: 12, border: '1px solid var(--dg-border)', padding: '6px 8px' }
                },
                    React.createElement('span', null, h.name),
                    React.createElement(StatusBadge, { status: h.status })
                ))
            )
        ),
        React.createElement('div', { className: 'dash-card' },
            React.createElement('div', { className: 'card-header' },
                React.createElement('h3', { className: 'card-title' }, 'Response Times'),
                React.createElement(Icons.Clock)
            ),
            React.createElement('div', { style: { display: 'flex', flexDirection: 'column', gap: 8 } },
                SH_HEALTH.filter(h => h.status === 'ok').map(h => React.createElement('div', {
                    key: h.name,
                    style: { display: 'flex', justifyContent: 'space-between', fontSize: 12, border: '1px solid var(--dg-border)', padding: '6px 8px' }
                },
                    React.createElement('span', null, h.name),
                    React.createElement('span', { style: { fontWeight: 600 } }, `${(Math.random() * 200 + 50).toFixed(0)}ms`)
                ))
            )
        )
    );
}

/* ============================================================
   PLACEHOLDER COMPONENT (for unimplemented sections)
   ============================================================ */
function Placeholder({ title, desc }) {
    return React.createElement('div', { className: 'datagrid-card' },
        React.createElement('div', { className: 'grid-toolbar' },
            React.createElement('div', { className: 'toolbar-left' },
                React.createElement('span', { className: 'meta-pill selected' }, title),
                React.createElement('span', { style: { fontSize: 12, color: 'var(--dg-text-soft)' } }, desc)
            )
        ),
        React.createElement('div', { style: { padding: 48, textAlign: 'center', color: 'var(--dg-text-soft)' } },
            React.createElement('div', { style: { fontSize: 40, marginBottom: 12, opacity: .2 } },
                React.createElement(Icons.FileCode)
            ),
            React.createElement('div', { style: { fontWeight: 600, color: 'var(--dg-text)', fontSize: 14 } }, title),
            React.createElement('div', { style: { fontSize: 12, marginTop: 6, maxWidth: 400, margin: '8px auto 0' } }, desc)
        )
    );
}

/* ============================================================
   MAIN APP COMPONENT
   ============================================================ */
function App() {
    const [collapsed, setCollapsed] = useState(false);
    const [activeNav, setActiveNav] = useState('dashboard');
    const [expandedMenus, setExpandedMenus] = useState({ REST: true, SOAP: false, 'File Management': false, 'Test Suite': false });
    const [restApps, setRestApps] = useState(SH_REST_APPS);
    const [soapApps, setSoapApps] = useState(SH_SOAP_APPS);

    const sidebarMenu = [
        { id: 'dashboard', label: 'Dashboard', icon: Icons.LayoutDashboard },
        {
            label: 'REST', icon: Icons.AppWindow, children: [
                { id: 'rest-applications', label: 'Applications' },
                { id: 'rest-request-files', label: 'Request Files' },
                { id: 'rest-templates', label: 'Templates' },
                { id: 'rest-swagger', label: 'Swagger Sync' },
                { id: 'rest-execute', label: 'Execute & History' }
            ]
        },
        {
            label: 'SOAP', icon: Icons.Database, children: [
                { id: 'soap-applications', label: 'Applications' },
                { id: 'soap-request-files', label: 'Request Files' },
                { id: 'soap-templates', label: 'Templates' },
                { id: 'soap-swagger', label: 'WSDL Sync' },
                { id: 'soap-execute', label: 'Execute & History' }
            ]
        },
        {
            label: 'File Management', icon: Icons.FolderTree, children: [
                { id: 'file-library', label: 'File Library' },
                { id: 'file-browser', label: 'File Browser WebDAV' },
                { id: 'file-viewer', label: 'File Viewer PDF' },
                { id: 'file-comparer', label: 'Editor Comparer' }
            ]
        },
        {
            label: 'Test Suite', icon: Icons.Beaker, children: [
                { id: 'test-cases', label: 'Test Cases' },
                { id: 'test-suites', label: 'Test Suites' },
                { id: 'test-criteria', label: 'Success Criteria' },
                { id: 'test-executions', label: 'Executions & History' }
            ]
        },
        { id: 'health', label: 'Monitoring Health Dashboard', icon: Icons.Activity },
        { id: 'ad-viewer', label: 'AD Viewer', icon: Icons.Users },
        { id: 'settings', label: 'Settings', icon: Icons.Settings }
    ];

    const toggleMenu = (label) => {
        setExpandedMenus(prev => ({ ...prev, [label]: !prev[label] }));
    };

    const handleNavigate = (id) => {
        setActiveNav(id);
    };

    const renderContent = () => {
        switch (activeNav) {
            case 'dashboard':
                return React.createElement(Dashboard, { onNavigate: handleNavigate });
            case 'rest-applications':
                return React.createElement(ApplicationsTable, { apps: restApps, setApps: setRestApps, isSoap: false });
            case 'soap-applications':
                return React.createElement(ApplicationsTable, { apps: soapApps, setApps: setSoapApps, isSoap: true });
            case 'rest-request-files':
                return React.createElement(RequestFiles, {
                    files: SH_REQUEST_FILES.filter(f => f.source === 'REST'),
                    isSoap: false,
                    onNavigate: handleNavigate
                });
            case 'soap-request-files':
                return React.createElement(RequestFiles, {
                    files: SH_REQUEST_FILES.filter(f => f.source === 'SOAP'),
                    isSoap: true,
                    onNavigate: handleNavigate
                });
            case 'rest-templates':
                return React.createElement(Templates, { isSoap: false });
            case 'soap-templates':
                return React.createElement(Templates, { isSoap: true });
            case 'rest-execute':
                return React.createElement(ExecuteHistory, { isSoap: false });
            case 'soap-execute':
                return React.createElement(ExecuteHistory, { isSoap: true });
            case 'file-library':
                return React.createElement(FileLibrary, null);
            case 'file-browser':
                return React.createElement(FileBrowser, null);
            case 'file-viewer':
                return React.createElement(FileViewer, null);
            case 'file-comparer':
                return React.createElement(Placeholder, { title: 'Editor Comparer', desc: 'Diff XML/JSON files side by side with highlighted changes.' });
            case 'test-cases':
                return React.createElement(Placeholder, { title: 'Test Cases', desc: 'Manage test cases, link files, set assertions.' });
            case 'test-suites':
                return React.createElement(Placeholder, { title: 'Test Suites', desc: '8 Suites • Group test cases into suites, schedule executions.' });
            case 'test-criteria':
                return React.createElement(Placeholder, { title: 'Success Criteria', desc: 'Define XPath/JSONPath validations.' });
            case 'test-executions':
                return React.createElement(Placeholder, { title: 'Executions & History', desc: 'View execution timeline and pass/fail trends.' });
            case 'rest-swagger':
                return React.createElement(Placeholder, { title: 'Swagger Sync', desc: 'Sync OpenAPI specs from URLs, auto-generate APIs.' });
            case 'soap-swagger':
                return React.createElement(Placeholder, { title: 'WSDL Sync', desc: 'Import WSDL and generate operations.' });
            case 'health':
                return React.createElement(HealthDashboard, null);
            case 'ad-viewer':
                return React.createElement(Placeholder, { title: 'AD Viewer', desc: 'Browse Active Directory groups and members.' });
            case 'settings':
                return React.createElement(Placeholder, { title: 'Settings', desc: 'Manage users, permissions, integrations.' });
            default:
                return React.createElement(Dashboard, { onNavigate: handleNavigate });
        }
    };

    return React.createElement('div', { className: 'app-layout' },
        /* Sidebar */
        React.createElement(Sidebar, {
            activeNav,
            onNavigate: handleNavigate,
            collapsed,
            onToggleCollapse: () => setCollapsed(c => !c),
            sidebarMenu,
            expandedMenus,
            onToggleMenu: toggleMenu
        }),
        /* Mobile overlay */
        React.createElement('div', {
            className: `sidebar-overlay${collapsed ? '' : ''}`,
            id: 'sidebarOverlay'
        }),
        /* Main Content */
        React.createElement('div', { className: 'main-content' },
            React.createElement('header', { className: 'main-header' },
                React.createElement('div', { style: { display: 'flex', alignItems: 'center', gap: 12 } },
                    React.createElement('button', {
                        className: 'btn-dg btn-dg-icon',
                        id: 'mobileMenuBtn',
                        'aria-label': 'Open menu',
                        style: { display: 'none' },
                        onClick: () => {
                            const sidebar = document.querySelector('.sidebar');
                            const overlay = document.getElementById('sidebarOverlay');
                            if (sidebar) sidebar.classList.toggle('mobile-open');
                            if (overlay) overlay.classList.toggle('show');
                        }
                    },
                        React.createElement(Icons.Menu)
                    ),
                    React.createElement('h1', { style: { fontSize: 13, fontWeight: 500, margin: 0, letterSpacing: '.01em', color: 'var(--dg-text-faint)' } },
                        toTitleCase(activeNav)
                    )
                ),
                React.createElement('div', { style: { display: 'flex', alignItems: 'center', gap: 8 } },
                    React.createElement('button', {
                        className: 'btn-dg btn-dg-icon',
                        'aria-label': 'Toggle theme',
                        onClick: () => {
                            const html = document.documentElement;
                            const current = html.getAttribute('data-theme') || 'light';
                            html.setAttribute('data-theme', current === 'dark' ? 'light' : 'dark');
                            localStorage.setItem('dg-theme', current === 'dark' ? 'light' : 'dark');
                        }
                    },
                        React.createElement(Icons.Moon)
                    ),
                    React.createElement('span', { style: { fontSize: 12, color: 'var(--dg-text-soft)' } }, 'Admin • Priya Sharma'),
                    React.createElement('div', { className: 'avatar-sm', style: { background: 'var(--dg-primary)', color: 'var(--dg-primary-text)', border: 'none' } }, 'PS')
                )
            ),
            React.createElement('div', { className: 'main-body' },
                renderContent()
            )
        )
    );
}

/* ============================================================
   MOBILE CHECK — runs on mount and resize
   ============================================================ */
document.addEventListener('DOMContentLoaded', () => {
    const root = document.getElementById('root');
    if (root) {
        const reactRoot = ReactDOM.createRoot(root);
        reactRoot.render(React.createElement(App));
    }

    const checkMobile = () => {
        const btn = document.getElementById('mobileMenuBtn');
        if (!btn) return;
        if (window.innerWidth <= 768) {
            btn.style.display = 'inline-flex';
        } else {
            btn.style.display = 'none';
            document.querySelector('.sidebar')?.classList.remove('mobile-open');
            document.querySelector('.sidebar-overlay')?.classList.remove('show');
        }
    };
    checkMobile();
    window.addEventListener('resize', checkMobile);
});
