/**
 * ServiceHubPagination — Modular pagination manager for Service Hub Enterprise datagrids.
 *
 * Manages page navigation, page info display, and page size for any datagrid table.
 * Designed to work with both static HTML tables and Blazor-interactive grids.
 *
 * Usage:
 *   const pager = new ServiceHubPagination('#myGrid', {
 *     pageSize: 5,
 *     onPageChange: (page, size) => {  }
 *   });
 *
 * DOM structure expected:
 *   <div class="pagination-footer">
 *     <div class="pagination-info">Showing 1 - 5 of 25</div>
 *     <div class="pagination-controls">
 *       <button class="pagination-btn" data-page="prev">...</button>
 *       <button class="pagination-btn pagination-num" data-page="1">1</button>
 *       ...
 *       <button class="pagination-btn" data-page="next">...</button>
 *     </div>
 *   </div>
 */
class ServiceHubPagination {
    /**
     * @param {string|HTMLElement} container - Selector or element containing pagination controls.
     * @param {Object} [options]
     * @param {number} [options.pageSize=10] - Number of items per page.
     * @param {number} [options.visiblePages=5] - Max page number buttons to show.
     * @param {Function} [options.onPageChange] - Callback(currentPage, pageSize).
     */
    constructor(container, options = {}) {
        this.container = typeof container === 'string'
            ? document.querySelector(container)
            : container;

        if (!this.container) return;

        this.pageSize = options.pageSize || 10;
        this.visiblePages = options.visiblePages || 5;
        this.totalRecords = options.totalRecords || 0;
        this.currentPage = 1;
        this.onPageChange = options.onPageChange || (() => {});

        this._bindEvents();
    }

    /** Update the total record count and re-render pagination. */
    updateTotal(count) {
        this.totalRecords = count;
        this.currentPage = Math.min(this.currentPage, this.totalPages || 1);
        this.render();
    }

    /** @returns {number} Total pages based on current total records. */
    get totalPages() {
        return this.totalRecords > 0
            ? Math.ceil(this.totalRecords / this.pageSize)
            : 1;
    }

    /** Navigate to a specific page number. */
    goToPage(page) {
        if (page < 1 || page > this.totalPages) return;
        this.currentPage = page;
        this.render();
        this.onPageChange(this.currentPage, this.pageSize);
    }

    /** Navigate to the next page. */
    next() { this.goToPage(this.currentPage + 1); }

    /** Navigate to the previous page. */
    prev() { this.goToPage(this.currentPage - 1); }

    /** Rebuild and refresh the pagination UI. */
    render() {
        const infoEl = this.container.querySelector('.pagination-info');
        if (infoEl) {
            const start = (this.currentPage - 1) * this.pageSize + 1;
            const end = Math.min(this.currentPage * this.pageSize, this.totalRecords);
            infoEl.textContent = `Showing ${start} - ${end} of ${this.totalRecords}`;
        }

        const controlsEl = this.container.querySelector('.pagination-controls');
        if (!controlsEl) return;

        // Preserve prev/next buttons, regenerate numeric buttons in between.
        const prevBtn = controlsEl.querySelector('[data-page="prev"]');
        const nextBtn = controlsEl.querySelector('[data-page="next"]');

        // Remove all buttons except prev/next.
        Array.from(controlsEl.children).forEach(child => {
            if (child !== prevBtn && child !== nextBtn) {
                child.remove();
            }
        });

        if (prevBtn) {
            prevBtn.disabled = this.currentPage <= 1;
        }

        if (nextBtn) {
            nextBtn.disabled = this.currentPage >= this.totalPages;
        }

        // Insert page number buttons after prev button.
        const insertAfter = prevBtn || controlsEl.firstChild;
        const range = this._getPageRange();

        range.forEach(page => {
            const btn = document.createElement('button');
            btn.className = 'pagination-btn pagination-num';
            btn.setAttribute('data-page', page);
            btn.textContent = page;
            if (page === this.currentPage) {
                btn.innerHTML = `<span style="font-weight:700">${page}</span>`;
            }
            btn.addEventListener('click', () => this.goToPage(page));
            controlsEl.insertBefore(btn, nextBtn || null);
        });
    }

    /** Calculate which page number buttons to show. */
    _getPageRange() {
        const total = this.totalPages;
        const half = Math.floor(this.visiblePages / 2);
        let start = Math.max(1, this.currentPage - half);
        let end = Math.min(total, start + this.visiblePages - 1);

        if (end - start + 1 < this.visiblePages) {
            start = Math.max(1, end - this.visiblePages + 1);
        }

        const pages = [];
        for (let i = start; i <= end; i++) {
            pages.push(i);
        }
        return pages;
    }

    /** Attach click handlers to prev/next buttons. */
    _bindEvents() {
        const controlsEl = this.container.querySelector('.pagination-controls');
        if (!controlsEl) return;

        controlsEl.addEventListener('click', (e) => {
            const btn = e.target.closest('.pagination-btn');
            if (!btn) return;
            const page = btn.getAttribute('data-page');
            if (page === 'prev') this.prev();
            else if (page === 'next') this.next();
            else if (page) this.goToPage(parseInt(page, 10));
        });
    }

    /** Clean up event listeners. */
    destroy() {
        // Events are delegated on the controls container; removing the element cleans up.
    }
}

// Export for module bundlers or global usage.
if (typeof module !== 'undefined' && module.exports) {
    module.exports = { ServiceHubPagination };
}
