/**
 * ServiceHubRowActions — Modular row actions manager for Service Hub Enterprise datagrids.
 *
 * Manages three-dot action triggers with inline action panels, expand/collapse toggles,
 * and row selection (individual + select-all checkboxes).
 *
 * Usage:
 *   const actions = new ServiceHubRowActions('#myGrid', {
 *     onSelect: (selectedIds) => { /* update selected count *\/ },
 *     onExpand: (id, expanded) => { /* toggle detail row *\/ }
 *   });
 */
class ServiceHubRowActions {
    /**
     * @param {string|HTMLElement} container - The grid container or table element.
     * @param {Object} [options]
     * @param {string} [options.actionTriggerSelector='.action-trigger'] - Selector for the three-dots button.
     * @param {string} [options.inlineActionsSelector='.inline-actions'] - Selector for the inline actions panel.
     * @param {string} [options.expandBtnSelector='.expand-btn'] - Selector for expand/collapse buttons.
     * @param {string} [options.checkboxSelector='input[type="checkbox"]'] - Selector for row checkboxes.
     * @param {string} [options.selectAllSelector='th.check-cell input[type="checkbox"]'] - Selector for select-all checkbox.
     * @param {string} [options.rowSelector='tbody tr'] - Selector for data rows.
     * @param {string} [options.selectedClass='is-selected'] - CSS class for selected rows.
     * @param {Function} [options.onSelect] - Callback(selectedIds: string[]).
     * @param {Function} [options.onExpand] - Callback(id: string, isExpanded: boolean).
     */
    constructor(container, options = {}) {
        this.container = typeof container === 'string'
            ? document.querySelector(container)
            : container;

        if (!this.container) return;

        this.table = this.container.tagName === 'TABLE'
            ? this.container
            : this.container.querySelector('table.datagrid');

        this.options = Object.assign({
            actionTriggerSelector: '.action-trigger',
            inlineActionsSelector: '.inline-actions',
            expandBtnSelector: '.expand-btn',
            checkboxSelector: 'input[type="checkbox"]',
            selectAllSelector: 'th.check-cell input[type="checkbox"]',
            rowSelector: 'tbody tr',
            selectedClass: 'is-selected',
            onSelect: () => {},
            onExpand: () => {}
        }, options);

        this.selectedIds = new Set();
        this.expandedIds = new Set();
        this._boundCloseAllActions = this._closeAllActionMenus.bind(this);

        this._bindEvents();
    }

    /** Bind all event listeners using delegation on the container. */
    _bindEvents() {
        // Action trigger buttons (three-dots) – toggle inline actions
        this.container.addEventListener('click', (e) => {
            const trigger = e.target.closest(this.options.actionTriggerSelector);
            if (trigger) {
                // Skip if Blazor manages this wrap
                const wrap = trigger.closest('.row-actions-wrap, .header-actions-wrap, .footer-actions-wrap');
                if (wrap && wrap.classList.contains('blazor-managed')) return;

                e.stopPropagation();
                const row = trigger.closest(this.options.rowSelector);
                const actionsPanel = trigger.parentElement.querySelector(this.options.inlineActionsSelector);
                if (actionsPanel) {
                    const isOpen = actionsPanel.classList.contains('visible');
                    this._closeAllActionMenus();
                    if (!isOpen) {
                        actionsPanel.classList.add('visible');
                        if (wrap) wrap.classList.add('is-open');
                    }
                }
                return;
            }

            // Close button inside inline actions
            const closeBtn = e.target.closest('.ia-close');
            if (closeBtn) {
                const actionsPanel = closeBtn.closest(this.options.inlineActionsSelector);
                if (actionsPanel) {
                    actionsPanel.classList.remove('visible');
                    const wrap = actionsPanel.closest('.row-actions-wrap, .header-actions-wrap, .footer-actions-wrap');
                    if (wrap) wrap.classList.remove('is-open');
                }
                return;
            }

            // Expand/collapse toggle
            const expandBtn = e.target.closest(this.options.expandBtnSelector);
            if (expandBtn) {
                const row = expandBtn.closest(this.options.rowSelector);
                if (row && row.dataset.rowId) {
                    this.toggleExpand(row.dataset.rowId);
                }
                return;
            }

            // Individual row checkbox
            const checkbox = e.target.closest(this.options.checkboxSelector);
            if (checkbox && !checkbox.closest('th')) {
                const row = checkbox.closest(this.options.rowSelector);
                if (row && row.dataset.rowId) {
                    this.toggleSelect(row.dataset.rowId);
                }
                return;
            }

            // Select-all checkbox
            const selectAll = e.target.closest(this.options.selectAllSelector);
            if (selectAll) {
                this.toggleSelectAll(selectAll.checked);
                return;
            }

            // Clicking outside action menus closes them
            this._closeAllActionMenus();
        });

        // Click outside to close inline actions & context menu
        document.addEventListener('click', (e) => {
            // Close any open action wrap (row, header, or footer)
            const actionWraps = '.row-actions-wrap, .header-actions-wrap, .footer-actions-wrap';
            if (!e.target.closest(actionWraps)) {
                document.querySelectorAll(actionWraps + '.is-open').forEach(el => el.classList.remove('is-open'));
            }
            if (!e.target.closest('#' + this.container.id + '-contextMenu')) {
                this.hideContextMenu();
            }
        });

        // Close action menus when clicking anywhere outside
        document.addEventListener('click', this._boundCloseAllActions);
    }

    /** Close all visible action panels. */
    _closeAllActionMenus() {
        this.container.querySelectorAll(`${this.options.inlineActionsSelector}.visible`).forEach(el => {
            el.classList.remove('visible');
        });
        this.container.querySelectorAll('.row-actions-wrap.is-open, .header-actions-wrap.is-open, .footer-actions-wrap.is-open').forEach(el => {
            el.classList.remove('is-open');
        });
    }

    /** Hide the context menu associated with this grid, if one is open. */
    hideContextMenu() {
        const menu = document.querySelector(`#${this.container.id}-contextMenu`);
        const overlay = document.querySelector(`#${this.container.id}-contextMenuOverlay`);
        if (menu) {
            menu.classList.remove('visible');
            menu.style.display = 'none';
        }
        if (overlay) {
            overlay.classList.remove('visible');
        }
    }

    /** Toggle row selection. */
    toggleSelect(rowId) {
        if (this.selectedIds.has(rowId)) {
            this.selectedIds.delete(rowId);
        } else {
            this.selectedIds.add(rowId);
        }
        this._updateRowStates();
        this._updateSelectAll();
        this.options.onSelect([...this.selectedIds]);
    }

    /** Toggle select-all. */
    toggleSelectAll(checked) {
        const rows = this.table?.querySelectorAll(this.options.rowSelector);
        if (!rows) return;

        rows.forEach(row => {
            if (row.dataset.rowId) {
                if (checked) {
                    this.selectedIds.add(row.dataset.rowId);
                } else {
                    this.selectedIds.delete(row.dataset.rowId);
                }
            }
        });

        this._updateRowStates();
        this._updateSelectAll();
        this.options.onSelect([...this.selectedIds]);
    }

    /** Toggle row expand/collapse. */
    toggleExpand(rowId) {
        const isExpanded = this.expandedIds.has(rowId);
        if (isExpanded) {
            this.expandedIds.delete(rowId);
        } else {
            this.expandedIds.add(rowId);
        }
        this._updateExpandIcons();
        this.options.onExpand(rowId, !isExpanded);
    }

    /** Expand all rows. */
    expandAll(rowIds) {
        (rowIds || []).forEach(id => this.expandedIds.add(id));
        this._updateExpandIcons();
    }

    /** Collapse all rows. */
    collapseAll() {
        this.expandedIds.clear();
        this._updateExpandIcons();
    }

    /** Update row CSS classes and checkbox states based on selected set. */
    _updateRowStates() {
        const rows = this.table?.querySelectorAll(this.options.rowSelector);
        if (!rows) return;

        rows.forEach(row => {
            const id = row.dataset.rowId;
            const checkbox = row.querySelector(this.options.checkboxSelector);
            if (id) {
                row.classList.toggle(this.options.selectedClass, this.selectedIds.has(id));
                if (checkbox) checkbox.checked = this.selectedIds.has(id);
            }
        });
    }

    /** Update the select-all checkbox state. */
    _updateSelectAll() {
        const selectAll = this.container.querySelector(this.options.selectAllSelector);
        if (!selectAll) return;

        const rows = this.table?.querySelectorAll(this.options.rowSelector);
        if (!rows || rows.length === 0) {
            selectAll.checked = false;
            selectAll.indeterminate = false;
            return;
        }

        const checkedCount = rows.length > 0
            ? Array.from(rows).filter(r => r.dataset.rowId && this.selectedIds.has(r.dataset.rowId)).length
            : 0;

        selectAll.checked = checkedCount === rows.length;
        selectAll.indeterminate = checkedCount > 0 && checkedCount < rows.length;
    }

    /** Update expand/collapse icons based on expanded set. */
    _updateExpandIcons() {
        const rows = this.table?.querySelectorAll(this.options.rowSelector);
        if (!rows) return;

        rows.forEach(row => {
            const id = row.dataset.rowId;
            const expandBtn = row.querySelector(this.options.expandBtnSelector);
            if (expandBtn && id) {
                const icon = expandBtn.querySelector('i');
                if (icon) {
                    icon.className = this.expandedIds.has(id)
                        ? 'bi bi-chevron-up'
                        : 'bi bi-chevron-down';
                }
            }
        });
    }

    /** Get current selection state. */
    getSelectedIds() {
        return [...this.selectedIds];
    }

    /** Get current expanded state. */
    getExpandedIds() {
        return [...this.expandedIds];
    }

    /** Remove all event listeners. */
    destroy() {
        document.removeEventListener('click', this._boundCloseAllActions);
    }
}

// Export for module bundlers or global usage.
if (typeof module !== 'undefined' && module.exports) {
    module.exports = { ServiceHubRowActions };
}
