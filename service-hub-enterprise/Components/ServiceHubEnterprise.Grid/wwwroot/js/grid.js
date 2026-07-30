/**
 * ServiceHubGrid — Main orchestrator class for Service Hub Enterprise datagrids.
 *
 * Combines filtering, pagination, and row actions into a single unified grid controller.
 * Each subsystem (filters, pagination, actions) is in its own modular file and can be
 * used independently or together via this orchestrator.
 *
 * --- Common datagrid HTML structure ---
 *
 * <div class="datagrid-card" id="myGrid">
 *   <!-- Header / Toolbar -->
 *   <div class="grid-toolbar">
 *     <div class="toolbar-left">
 *       <div class="search-box">
 *         <span class="search-icon"><i class="bi bi-search"></i></span>
 *         <input type="text" placeholder="Search..." />
 *       </div>
 *       <div class="meta-group">
 *         <span class="meta-pill">N records</span>
 *         <span class="meta-pill">0 selected</span>
 *         <span class="meta-sep"></span>
 *         <select class="form-control-dg status-select">...</select>
 *         <button class="filter-btn"><i class="bi bi-funnel"></i> Filter</button>
 *       </div>
 *     </div>
 *     <div class="toolbar-right">
 *       <button class="btn btn-dark btn-sh-primary"><i class="bi bi-plus-lg"></i> Add</button>
 *       <button class="btn btn-outline-secondary btn-dg"><i class="bi bi-download"></i> Export</button>
 *       <!-- Header actions using action-trigger + inline-actions pattern -->
 *       <div class="header-actions-wrap">
 *         <button class="action-trigger"><i class="bi bi-three-dots"></i></button>
 *         <div class="inline-actions">
 *           <button class="ia-btn">Action 1</button>
 *           <button class="ia-btn">Action 2</button>
 *         </div>
 *       </div>
 *     </div>
 *   </div>
 *
 *   <!-- Table -->
 *   <div class="table-wrap">
 *     <table class="datagrid">
 *       <thead>...</thead>
 *       <tbody>
 *         <tr data-row-id="1">
 *           <td class="check-cell"><input type="checkbox" /></td>
 *           ...
 *         </tr>
 *       </tbody>
 *     </table>
 *   </div>
 *
 *   <!-- Footer / Pagination -->
 *   <div class="pagination-footer">
 *     <div class="pagination-info">Showing 1 - 5 of 25</div>
 *     <div class="pagination-controls">
 *       <button class="pagination-btn" data-page="prev">Prev</button>
 *       <button class="pagination-btn pagination-num" data-page="1">1</button>
 *       <button class="pagination-btn" data-page="next">Next</button>
 *     </div>
 *     <!-- Footer actions using action-trigger + inline-actions pattern -->
 *     <div class="footer-actions-wrap">
 *       <button class="action-trigger"><i class="bi bi-three-dots"></i></button>
 *       <div class="inline-actions">
 *         <button class="ia-btn">Footer Action</button>
 *       </div>
 *     </div>
 *   </div>
 *   <!-- Standalone footer (no pagination) -->
 *   <div class="grid-footer">
 *     <div class="footer-actions-wrap">
 *       <button class="action-trigger"><i class="bi bi-three-dots"></i></button>
 *       <div class="inline-actions">
 *         <button class="ia-btn">Footer Action</button>
 *       </div>
 *     </div>
 *   </div>
 * </div>
 *
 * Usage:
 *   const grid = new ServiceHubGrid('#myGrid', {
 *     pageSize: 5,
 *     totalRecords: 25,
 *     onFilter: (filterState) => { /* refresh data *\/ },
 *     onPageChange: (page, size) => { /* reload page *\/ },
 *     onSelect: (ids) => { /* update UI *\/ }
 *   });
 */
class ServiceHubGrid {
    /**
     * @param {string|HTMLElement} element - The datagrid-card element or its CSS selector.
     * @param {Object} [options]
     * @param {number} [options.pageSize=10] - Default page size.
     * @param {number} [options.totalRecords=0] - Total record count.
     * @param {boolean} [options.enablePagination=true] - Whether to initialize pagination.
     * @param {boolean} [options.enableFilters=true] - Whether to initialize filters.
     * @param {boolean} [options.enableActions=true] - Whether to initialize row actions.
     * @param {Function} [options.onFilter] - Filter callback(filterState).
     * @param {Function} [options.onPageChange] - Page change callback(page, pageSize).
     * @param {Function} [options.onSelect] - Selection callback(selectedIds[]).
     * @param {Function} [options.onContextMenuClick] - Context menu item click callback(action, rowId).
     */
    constructor(element, options = {}) {
        this.el = typeof element === 'string' ? document.querySelector(element) : element;
        if (!this.el) {
            console.warn(`ServiceHubGrid: Element "${element}" not found.`);
            return;
        }

        this.options = Object.assign({
            pageSize: 10,
            totalRecords: 0,
            enablePagination: true,
            enableFilters: true,
            enableActions: true,
            onFilter: () => {},
            onPageChange: () => {},
            onSelect: () => {},
            onContextMenuClick: null
        }, options);

        this.pagination = null;
        this.filters = null;
        this.actions = null;
        this.contextMenu = null;

        this._initSubsystems();
    }

    /** Initialize each enabled subsystem. */
    _initSubsystems() {
        // 1. Filters (search box, status dropdown, filter modal)
        if (this.options.enableFilters && typeof ServiceHubFilters !== 'undefined') {
            this.filters = new ServiceHubFilters(this.el, {
                onFilter: (filterState) => {
                    this.options.onFilter(filterState);
                }
            });
        }

        // 2. Row actions (expand/collapse, selection, action menus)
        if (this.options.enableActions && typeof ServiceHubRowActions !== 'undefined') {
            this.actions = new ServiceHubRowActions(this.el, {
                onSelect: (ids) => {
                    this._updateRecordMeta(ids.length);
                    this.options.onSelect(ids);
                },
                onExpand: (id, expanded) => {
                    // Expand/collapse is handled by the parent Blazor component
                }
            });
        }

        // 3. Context menu (right-click on rows)
        if (typeof ServiceHubContextMenu !== 'undefined') {
            const hasContextRows = this.el.querySelector('tbody tr.has-context-menu');
            if (hasContextRows) {
                this.contextMenu = new ServiceHubContextMenu(this.el, {
                    rowSelector: 'tbody tr.has-context-menu',
                    onItemClick: (action, rowId, itemElement) => {
                        // Try Blazor interop first, then fall back to custom event
                        if (window.DotNet && DotNet.invokeMethodAsync) {
                            DotNet.invokeMethodAsync(
                                'ServiceHubEnterprise.Grid',
                                'OnContextMenuItemClicked',
                                rowId,
                                action
                            ).catch(() => {});
                        }
                        // Dispatch a custom event for consumers to listen to
                        this.el.dispatchEvent(new CustomEvent('contextmenu:itemclick', {
                            detail: { rowId, action, element: itemElement }
                        }));
                        if (this.options.onContextMenuClick) {
                            this.options.onContextMenuClick(action, rowId);
                        }
                    }
                });
            }
        }

        // 4. Pagination (page navigation in footer)
        if (this.options.enablePagination && typeof ServiceHubPagination !== 'undefined') {
            const paginationFooter = this.el.querySelector('.pagination-footer');
            if (paginationFooter) {
                this.pagination = new ServiceHubPagination(paginationFooter, {
                    pageSize: this.options.pageSize,
                    totalRecords: this.options.totalRecords,
                    onPageChange: (page, size) => {
                        this.options.onPageChange(page, size);
                    }
                });
                this.pagination.render();
            }
        }
    }

    /** Update the records count and selected count in the meta pills. */
    _updateRecordMeta(selectedCount) {
        const pills = this.el.querySelectorAll('.meta-pill');
        pills.forEach(pill => {
            const text = pill.textContent.trim();
            if (text.includes('selected')) {
                pill.textContent = `${selectedCount} selected`;
            }
        });
    }

    /** Update the total records count. */
    updateTotalRecords(count) {
        if (this.pagination) {
            this.pagination.updateTotal(count);
        }
        // Update the records meta pill
        const pills = this.el.querySelectorAll('.meta-pill');
        pills.forEach(pill => {
            const text = pill.textContent.trim();
            if (text.includes('records') || text.includes('templates') || text.includes('files') || text.includes('suites')) {
                // Try to preserve the label
                const label = text.replace(/^[\d,]+/, '').trim();
                pill.textContent = `${count} ${label || 'records'}`;
            }
        });
    }

    /** Navigate to a specific page. */
    goToPage(page) {
        if (this.pagination) {
            this.pagination.goToPage(page);
        }
    }

    /** Reset all filters. */
    resetFilters() {
        if (this.filters) {
            this.filters.resetAll();
        }
    }

    /** Destroy all subsystems and clean up. */
    destroy() {
        if (this.pagination) this.pagination.destroy();
        if (this.filters) this.filters.destroy();
        if (this.actions) this.actions.destroy();
        this.pagination = null;
        this.filters = null;
        this.actions = null;
    }
}

// Export for module bundlers or global usage.
if (typeof module !== 'undefined' && module.exports) {
    module.exports = { ServiceHubGrid };
}
