/**
 * ServiceHubContextMenu — Modular right-click context menu for Service Hub Enterprise datagrids.
 *
 * Provides a positioned context menu on right-click, with support for custom menu items,
 * dividers, headers, disabled items, and danger styling. Integrates with ServiceHubGrid
 * and ServiceHubRowActions for seamless coordination.
 *
 * DOM structure generated:
 *   <div class="context-menu-overlay-dg" id="{gridId}-contextMenuOverlay"></div>
 *   <div class="context-menu-dg" id="{gridId}-contextMenu">
 *     <button class="context-menu-item-dg" data-action="view">
 *       <i class="bi bi-eye"></i> View
 *     </button>
 *     <div class="context-menu-divider-dg"></div>
 *     <button class="context-menu-item-dg context-menu-item-sh-danger" data-action="delete">
 *       <i class="bi bi-trash"></i> Delete
 *     </button>
 *   </div>
 *
 * Usage:
 *   const ctx = new ServiceHubContextMenu('#myGrid', {
 *     rowSelector: 'tbody tr',
 *     onItemClick: (action, rowId, itemElement) => { /* handle action *\/ }
 *   });
 *
 *   // Or with static menu items
 *   const ctx = new ServiceHubContextMenu('#myGrid', {
 *     items: [
 *       { label: 'View', icon: 'bi-eye', action: 'view' },
 *       { type: 'divider' },
 *       { label: 'Edit', icon: 'bi-pencil', action: 'edit' },
 *       { type: 'divider' },
 *       { label: 'Delete', icon: 'bi-trash', action: 'delete', danger: true }
 *     ]
 *   });
 */
class ServiceHubContextMenu {
    /**
     * @param {string|HTMLElement} container - The datagrid-card element or its CSS selector.
     * @param {Object} [options]
     * @param {string} [options.rowSelector='tbody tr'] - Selector for rows that show context menu.
     * @param {Array} [options.items] - Static menu item definitions. If omitted, onItemClick is used with dynamic items.
     * @param {boolean} [options.enabled=true] - Whether the context menu is active.
     * @param {Function} [options.getItem] - Async function(rowId, itemElement) returning array of items for dynamic menus.
     * @param {Function} [options.onItemClick] - Callback(action, rowId, itemElement).
     * @param {Function} [options.onOpen] - Callback(rowId, itemElement) when menu opens.
     * @param {Function} [options.onClose] - Callback() when menu closes.
     */
    constructor(container, options = {}) {
        this.container = typeof container === 'string'
            ? document.querySelector(container)
            : container;

        if (!this.container) {
            console.warn('ServiceHubContextMenu: Container not found.');
            return;
        }

        this.options = Object.assign({
            rowSelector: 'tbody tr',
            items: null,
            enabled: true,
            getItem: null,
            onItemClick: () => {},
            onOpen: () => {},
            onClose: () => {}
        }, options);

        this._gridId = this.container.dataset.gridId || this.container.id || 'shg-ctx';
        this._menuEl = null;
        this._overlayEl = null;
        this._currentRowId = null;
        this._currentItemEl = null;
        this._boundHandleContextMenu = this._handleContextMenu.bind(this);
        this._boundHandleOverlayClick = this._handleOverlayClick.bind(this);
        this._boundHandleKeyDown = this._handleKeyDown.bind(this);

        this._build();
        this._bindEvents();
    }

    /** Build the DOM elements for the context menu and overlay. */
    _build() {
        // Remove any existing context menu for this grid
        const existingMenu = document.getElementById(`${this._gridId}-contextMenu`);
        if (existingMenu) existingMenu.remove();
        const existingOverlay = document.getElementById(`${this._gridId}-contextMenuOverlay`);
        if (existingOverlay) existingOverlay.remove();

        // Create overlay
        this._overlayEl = document.createElement('div');
        this._overlayEl.className = 'context-menu-overlay-dg';
        this._overlayEl.id = `${this._gridId}-contextMenuOverlay`;
        document.body.appendChild(this._overlayEl);

        // Create menu container
        this._menuEl = document.createElement('div');
        this._menuEl.className = 'context-menu-dg';
        this._menuEl.id = `${this._gridId}-contextMenu`;
        document.body.appendChild(this._menuEl);
    }

    /** Bind event listeners. */
    _bindEvents() {
        // Right-click on rows
        this.container.addEventListener('contextmenu', this._boundHandleContextMenu);

        // Overlay click to close
        this._overlayEl.addEventListener('click', this._boundHandleOverlayClick);

        // Escape key to close
        document.addEventListener('keydown', this._boundHandleKeyDown);

        // Window resize/reposition to close
        window.addEventListener('resize', this._close.bind(this));
        window.addEventListener('scroll', this._close.bind(this), true);
    }

    /** Handle right-click context menu event. */
    _handleContextMenu(e) {
        if (!this.options.enabled) return;

        const row = e.target.closest(this.options.rowSelector);
        if (!row) return;

        e.preventDefault();
        e.stopPropagation();

        this._currentRowId = row.dataset.rowId || null;
        this._currentItemEl = row;

        this._close(); // close any existing menu first

        // Build menu items
        if (this.options.getItem) {
            // Async dynamic items
            const result = this.options.getItem(this._currentRowId, row);
            if (result && typeof result.then === 'function') {
                result.then(items => {
                    if (items && items.length > 0) {
                        this._renderMenu(items);
                        this._position(e.clientX, e.clientY);
                        this._show();
                    }
                });
            } else if (result) {
                this._renderMenu(result);
                this._position(e.clientX, e.clientY);
                this._show();
            }
        } else if (this.options.items) {
            // Static items
            this._renderMenu(this.options.items);
            this._position(e.clientX, e.clientY);
            this._show();
        } else {
            // Default items when none configured
            this._renderMenu(this._getDefaultItems());
            this._position(e.clientX, e.clientY);
            this._show();
        }
    }

    /** Get default context menu items. */
    _getDefaultItems() {
        return [
            { label: 'View', icon: 'bi-eye', action: 'view' },
            { label: 'Edit', icon: 'bi-pencil', action: 'edit' },
            { type: 'divider' },
            { label: 'Copy Row ID', icon: 'bi-files', action: 'copyId' },
            { type: 'divider' },
            { label: 'Delete', icon: 'bi-trash', action: 'delete', danger: true }
        ];
    }

    /** Render menu items into the menu element. */
    _renderMenu(items) {
        this._menuEl.innerHTML = '';

        items.forEach((item, index) => {
            if (item.type === 'divider') {
                const divider = document.createElement('div');
                divider.className = 'context-menu-divider-dg';
                this._menuEl.appendChild(divider);
                return;
            }

            if (item.type === 'header') {
                const header = document.createElement('div');
                header.className = 'context-menu-header-dg';
                header.textContent = item.label || '';
                this._menuEl.appendChild(header);
                return;
            }

            const btn = document.createElement('button');
            let className = 'context-menu-item-dg';

            if (item.danger) {
                className += ' context-menu-item-sh-danger';
            }

            if (item.disabled) {
                btn.disabled = true;
            }

            btn.className = className;
            btn.setAttribute('data-action', item.action || '');
            btn.setAttribute('data-index', index);

            const icon = item.icon
                ? `<i class="bi ${item.icon}"></i>`
                : '';
            btn.innerHTML = `${icon}${item.label || ''}`;

            btn.addEventListener('click', () => {
                this.options.onItemClick(item.action || item.label, this._currentRowId, this._currentItemEl);
                this._close();
            });

            this._menuEl.appendChild(btn);
        });
    }

    /** Position the menu at the given coordinates, flipping if needed. */
    _position(x, y) {
        this._menuEl.style.left = '0px';
        this._menuEl.style.top = '0px';
        this._menuEl.style.display = 'block';

        const menuRect = this._menuEl.getBoundingClientRect();
        const viewportW = window.innerWidth;
        const viewportH = window.innerHeight;

        let posX = x;
        let posY = y;

        // Flip horizontally if overflowing right edge
        if (posX + menuRect.width > viewportW - 4) {
            posX = Math.max(4, viewportW - menuRect.width - 4);
        }

        // Flip vertically if overflowing bottom edge
        if (posY + menuRect.height > viewportH - 4) {
            posY = Math.max(4, viewportH - menuRect.height - 4);
        }

        this._menuEl.style.left = `${posX}px`;
        this._menuEl.style.top = `${posY}px`;
    }

    /** Show the context menu and overlay. */
    _show() {
        this._menuEl.classList.add('visible');
        this._overlayEl.classList.add('visible');
        this.options.onOpen(this._currentRowId, this._currentItemEl);
    }

    /** Handle click on the overlay backdrop. */
    _handleOverlayClick() {
        this._close();
    }

    /** Handle Escape key press. */
    _handleKeyDown(e) {
        if (e.key === 'Escape' && this._menuEl.classList.contains('visible')) {
            this._close();
        }
    }

    /** Close the context menu. */
    _close() {
        if (this._menuEl) {
            this._menuEl.classList.remove('visible');
            this._menuEl.style.display = 'none';
        }
        if (this._overlayEl) {
            this._overlayEl.classList.remove('visible');
        }
        this.options.onClose();
    }

    /** Set whether the context menu is enabled. */
    setEnabled(enabled) {
        this.options.enabled = enabled;
    }

    /** Update the menu items (for dynamic item sets). */
    setItems(items) {
        this.options.items = items;
        this.options.getItem = null; // clear dynamic provider
    }

    /** Set a dynamic item provider function. */
    setItemProvider(fn) {
        this.options.getItem = fn;
        this.options.items = null; // clear static items
    }

    /** Programmatically open the context menu for a specific row at coordinates. */
    openAt(rowId, itemElement, x, y) {
        this._currentRowId = rowId;
        this._currentItemEl = itemElement;

        if (this.options.getItem) {
            const result = this.options.getItem(rowId, itemElement);
            if (result && typeof result.then === 'function') {
                result.then(items => {
                    if (items && items.length > 0) {
                        this._renderMenu(items);
                        this._position(x, y);
                        this._show();
                    }
                });
            } else if (result) {
                this._renderMenu(result);
                this._position(x, y);
                this._show();
            }
        } else if (this.options.items) {
            this._renderMenu(this.options.items);
            this._position(x, y);
            this._show();
        } else {
            this._renderMenu(this._getDefaultItems());
            this._position(x, y);
            this._show();
        }
    }

    /** Destroy the context menu and clean up listeners. */
    destroy() {
        this.container.removeEventListener('contextmenu', this._boundHandleContextMenu);
        this._overlayEl.removeEventListener('click', this._boundHandleOverlayClick);
        document.removeEventListener('keydown', this._boundHandleKeyDown);
        window.removeEventListener('resize', this._close.bind(this));
        window.removeEventListener('scroll', this._close.bind(this), true);

        if (this._menuEl) {
            this._menuEl.remove();
        }
        if (this._overlayEl) {
            this._overlayEl.remove();
        }
    }
}

// Export for module bundlers or global usage.
if (typeof module !== 'undefined' && module.exports) {
    module.exports = { ServiceHubContextMenu };
}
