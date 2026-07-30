/**
 * ServiceHubFilters — Modular filter manager for Service Hub Enterprise datagrids.
 *
 * Manages search boxes, status filter dropdowns, filter modals, and advanced filter panels.
 * Provides a unified interface for collecting and resetting filter values.
 *
 * Usage:
 *   const filters = new ServiceHubFilters('#myGrid', {
 *     searchSelector: '.search-box input',
 *     filterModalSelector: '.filter-modal',
 *     onFilter: (filters) => { /* apply filters to data source *\/ }
 *   });
 */
class ServiceHubFilters {
    /**
     * @param {string|HTMLElement} container - The grid container element.
     * @param {Object} [options]
     * @param {string} [options.searchSelector='.search-box input'] - Selector for search input.
     * @param {string} [options.statusSelectSelector='.status-select'] - Selector for status filter dropdown.
     * @param {string} [options.filterBtnSelector='.filter-btn'] - Selector for the filter toggle button.
     * @param {string} [options.filterModalSelector='.modal-overlay'] - Selector for filter modal overlay.
     * @param {string} [options.filterModalContentSelector='.modal-content-dg'] - Selector for filter modal content.
     * @param {string} [options.applyBtnSelector] - Selector for apply filters button.
     * @param {string} [options.resetBtnSelector] - Selector for reset filters button.
     * @param {number} [options.debounceMs=300] - Debounce delay for search input.
     * @param {Function} [options.onFilter] - Callback(filterState) where filterState is { searchText, status, advanced }.
     */
    constructor(container, options = {}) {
        this.container = typeof container === 'string'
            ? document.querySelector(container)
            : container;

        if (!this.container) return;

        this.options = Object.assign({
            searchSelector: '.search-box input',
            statusSelectSelector: '.status-select',
            filterBtnSelector: '.filter-btn',
            filterModalSelector: '.modal-overlay',
            filterModalContentSelector: '.modal-content-dg',
            applyBtnSelector: null,
            resetBtnSelector: null,
            debounceMs: 300,
            onFilter: () => {}
        }, options);

        this._debounceTimer = null;
        this._filterState = {
            searchText: '',
            status: '',
            advanced: {}
        };

        this._cacheElements();
        this._bindEvents();
    }

    /** Cache DOM element references. */
    _cacheElements() {
        this.searchInput = this.container.querySelector(this.options.searchSelector);
        this.statusSelect = this.container.querySelector(this.options.statusSelectSelector);
        this.filterBtn = this.container.querySelector(this.options.filterBtnSelector);
        this.filterModal = document.querySelector(this.options.filterModalSelector);
        this.filterContent = this.filterModal
            ? this.filterModal.querySelector(this.options.filterModalContentSelector)
            : null;

        if (this.options.applyBtnSelector) {
            this.applyBtn = this.container.querySelector(this.options.applyBtnSelector);
        }
        if (this.options.resetBtnSelector) {
            this.resetBtn = this.container.querySelector(this.options.resetBtnSelector);
        }
    }

    /** Bind all event listeners. */
    _bindEvents() {
        // Search input with debounce
        if (this.searchInput) {
            this.searchInput.addEventListener('input', (e) => {
                clearTimeout(this._debounceTimer);
                this._debounceTimer = setTimeout(() => {
                    this._filterState.searchText = e.target.value;
                    this._emitFilter();
                }, this.options.debounceMs);
            });
        }

        // Status dropdown filter
        if (this.statusSelect) {
            this.statusSelect.addEventListener('change', (e) => {
                this._filterState.status = e.target.value;
                this._emitFilter();
            });
        }

        // Filter modal toggle button
        if (this.filterBtn) {
            this.filterBtn.addEventListener('click', () => {
                this.openFilterModal();
            });
        }

        // Filter modal overlay click to close
        if (this.filterModal) {
            this.filterModal.addEventListener('click', (e) => {
                if (e.target === this.filterModal) {
                    this.closeFilterModal();
                }
            });

            // Close button inside modal
            const closeBtn = this.filterModal.querySelector('.action-icon-btn');
            if (closeBtn) {
                closeBtn.addEventListener('click', () => this.closeFilterModal());
            }
        }

        // Apply filters button
        if (this.applyBtn) {
            this.applyBtn.addEventListener('click', () => {
                this._collectAdvancedFilters();
                this.closeFilterModal();
                this._emitFilter();
            });
        }

        // Reset filters button
        if (this.resetBtn) {
            this.resetBtn.addEventListener('click', () => {
                this.resetAll();
            });
        }
    }

    /** Collect values from advanced filter fields inside the modal. */
    _collectAdvancedFilters() {
        if (!this.filterContent) return;
        const inputs = this.filterContent.querySelectorAll('input, select');
        inputs.forEach(input => {
            if (input.closest('.modal-footer-dg')) return; // skip footer buttons
            const label = input.closest('.form-group')
                ?.querySelector('label')
                ?.textContent?.trim()
                ?.toLowerCase()?.replace(/\s+/g, '_');
            if (label) {
                this._filterState.advanced[label] = input.value;
            }
        });
    }

    /** Open the filter modal. */
    openFilterModal() {
        if (this.filterModal) {
            this.filterModal.style.display = 'flex';
        }
    }

    /** Close the filter modal. */
    closeFilterModal() {
        if (this.filterModal) {
            this.filterModal.style.display = 'none';
        }
    }

    /** Reset all filters to their default values. */
    resetAll() {
        this._filterState = {
            searchText: '',
            status: '',
            advanced: {}
        };

        if (this.searchInput) this.searchInput.value = '';
        if (this.statusSelect) this.statusSelect.selectedIndex = 0;

        // Reset advanced filter inputs in modal
        if (this.filterContent) {
            const inputs = this.filterContent.querySelectorAll('input, select');
            inputs.forEach(input => {
                if (input.tagName === 'SELECT') input.selectedIndex = 0;
                else input.value = '';
            });
        }

        this._emitFilter();
    }

    /** Get the current filter state. */
    getState() {
        return { ...this._filterState };
    }

    /** Set filter values programmatically and trigger callback. */
    setState(state) {
        if (state.searchText !== undefined) {
            this._filterState.searchText = state.searchText;
            if (this.searchInput) this.searchInput.value = state.searchText;
        }
        if (state.status !== undefined) {
            this._filterState.status = state.status;
            if (this.statusSelect) this.statusSelect.value = state.status;
        }
        if (state.advanced !== undefined) {
            this._filterState.advanced = { ...state.advanced };
        }
        this._emitFilter();
    }

    /** Notify the parent about filter changes. */
    _emitFilter() {
        this.options.onFilter(this.getState());
    }

    /** Remove all event listeners. */
    destroy() {
        clearTimeout(this._debounceTimer);
    }
}

// Export for module bundlers or global usage.
if (typeof module !== 'undefined' && module.exports) {
    module.exports = { ServiceHubFilters };
}
