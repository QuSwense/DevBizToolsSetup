// Service Hub Enterprise — Site-wide JavaScript
//
// Grid UI modules are in /js/grid/ (loaded after this file):
//   grid.js       — ServiceHubGrid (orchestrator)
//   pagination.js — ServiceHubPagination
//   filters.js    — ServiceHubFilters
//   actions.js    — ServiceHubRowActions
//
// Initialization of datagrids happens in initGrids() below.
//
(function () {
    'use strict';

    window.toggleTheme = function () {
        const html = document.documentElement;
        const current = html.getAttribute('data-theme') || 'light';
        const next = current === 'dark' ? 'light' : 'dark';
        html.setAttribute('data-theme', next);
        localStorage.setItem('dg-theme', next);
    };

    window.toggleSidebar = function () {
        document.getElementById('mainSidebar').classList.toggle('collapsed');
    };

    window.toggleSubmenu = function (el) {
        el.classList.toggle('open');
        const sub = el.nextElementSibling;
        if (sub && sub.classList.contains('submenu')) {
            sub.style.display = sub.style.display === 'flex' ? 'none' : 'flex';
        }
    };

    function matchNavPath(currentPath, href) {
        if (!href) return false;
        if (href === '/') return currentPath === '/';
        return currentPath === href ||
            currentPath.startsWith(href + '/') ||
            currentPath.startsWith(href + '?');
    }

    function applyActiveStates() {
        const currentPath = window.location.pathname.replace(/\/+$/, '') || '/';
        document.querySelectorAll('.sidebar-nav a, .submenu-item, .menu-item').forEach(function (el) {
            el.classList.remove('active');
        });
        document.querySelectorAll('.sidebar-nav a, .submenu-item').forEach(function (el) {
            const href = el.getAttribute('href');
            if (matchNavPath(currentPath, href)) {
                el.classList.add('active');
                const parentSub = el.closest('.submenu');
                if (parentSub) {
                    const parentMenu = parentSub.previousElementSibling;
                    if (parentMenu && parentMenu.classList.contains('menu-item')) {
                        parentMenu.classList.add('active');
                        parentMenu.classList.add('open');
                        parentSub.style.display = 'flex';
                    }
                }
                const parentMenuItem = el.closest('.menu-item');
                if (parentMenuItem && !el.closest('.submenu')) {
                    parentMenuItem.classList.add('active');
                }
            }
        });
    }

    document.addEventListener('DOMContentLoaded', function () {
        const saved = localStorage.getItem('dg-theme');
        if (saved) document.documentElement.setAttribute('data-theme', saved);

        function checkMobile() {
            const btn = document.getElementById('mobileMenuBtn');
            if (!btn) return;
            btn.style.display = window.innerWidth <= 768 ? 'inline-flex' : 'none';
            if (window.innerWidth > 768) {
                document.querySelector('.sidebar')?.classList.remove('mobile-open');
                document.querySelector('.sidebar-overlay')?.classList.remove('show');
            }
        }
        checkMobile();
        window.addEventListener('resize', checkMobile);
        applyActiveStates();
    });

    window.addEventListener('blazor.navigating', function () {
        document.querySelectorAll('.sidebar-nav a, .submenu-item, .menu-item').forEach(function (el) {
            el.classList.remove('active');
        });
    });

    window.addEventListener('blazor.navigated', function () {
        applyActiveStates();
        initGrids();
    });

    /**
     * Initialize all ServiceHubGrid instances on the page.
     * Scans for .datagrid-card elements and attaches grid controllers.
     * Add data-grid-id="myGrid" to a .datagrid-card to auto-initialize it
     * with optional config via window.__gridConfigs.
     *
     * Example config:
     *   window.__gridConfigs = window.__gridConfigs || {};
     *   window.__gridConfigs['myGrid'] = { pageSize: 5 };
     */
    function initGrids() {
        if (typeof ServiceHubGrid === 'undefined') return;

        document.querySelectorAll('.datagrid-card').forEach(function (el) {
            var gridId = el.getAttribute('data-grid-id');
            if (!gridId || el.__serviceHubGrid) return;

            var config = (window.__gridConfigs && window.__gridConfigs[gridId]) || {};
            var hasPagination = !!el.querySelector('.pagination-footer');
            var pageSize = parseInt(el.getAttribute('data-page-size'), 10) || config.pageSize || 10;
            var totalRecords = parseInt(el.getAttribute('data-total-records'), 10) || config.totalRecords || 0;

            el.__serviceHubGrid = new ServiceHubGrid(el, {
                pageSize: pageSize,
                totalRecords: hasPagination ? totalRecords : 0,
                enablePagination: hasPagination,
                onFilter: config.onFilter || function () {},
                onPageChange: config.onPageChange || function () {},
                onSelect: config.onSelect || function () {}
            });
        });
    }

    // Initial grid scan on DOMContentLoaded (after all grid scripts load).
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', initGrids);
    } else {
        initGrids();
    }
})();
