/**
 * DevBizToolsSuite - Settings Module
 * Handles user whitelist display, system parameters, and color palette management.
 */
(function () {
    'use strict';

    /* ─── Module State ─── */
    const STATE = {
        users: [],
        palettes: {},
        systemParams: {},
        selectedPalette: null
    };

    /* ─── Initialization ─── */
    function init() {
        if (!document.getElementById('settingsUserTbody')) {
            setTimeout(init, 50);
            return;
        }

        loadData();
        renderUserTable();
        populateSystemParams();
        renderPaletteGallery();
        initializeTooltips();
    }

    /* ─── Load Data ─── */
    function loadData() {
        var dataStore = window.DATA || {};
        STATE.users = Array.isArray(dataStore.userWhitelist) ? dataStore.userWhitelist : [];
        STATE.systemParams = dataStore.systemParameters || {};
        STATE.palettes = dataStore.colorPalettes || {};

        // Detect current palette
        var currentPalette = document.documentElement.getAttribute('data-theme-palette') || 'bootstrap-default';
        STATE.selectedPalette = currentPalette;
    }

    /* ─── User Table ─── */
    function renderUserTable() {
        var tbody = document.getElementById('settingsUserTbody');
        if (!tbody) return;
        if (!STATE.users.length) {
            tbody.innerHTML = '<tr><td colspan="5" class="text-center text-muted py-3">No whitelist entries found.</td></tr>';
            return;
        }
        tbody.innerHTML = STATE.users.map(function (user, idx) {
            var statusClass = user.statusClass || 'bg-secondary-subtle text-secondary border border-secondary';
            var toggleIcon = user.active ? 'fa-toggle-on text-success' : 'fa-toggle-off text-muted';
            var toggleAction = user.active ? 'deactivateUser' : 'activateUser';
            return '<tr>' +
                '<td class="fw-semibold font-monospace fs-7">' + escapeHtml(user.username) + '</td>' +
                '<td>' + escapeHtml(user.fullName) + '</td>' +
                '<td><span class="badge ' + statusClass + ' fs-8">' + escapeHtml(user.status) + '</span></td>' +
                '<td class="fs-7">' + escapeHtml(user.createdDate) + '</td>' +
                '<td class="text-center">' +
                '<button class="btn btn-sm btn-outline-secondary" onclick="window.SETTINGS_MODULE.' + toggleAction + '(' + idx + ')" title="' + (user.active ? 'Deactivate' : 'Activate') + '">' +
                '<i class="fa-solid ' + toggleIcon + ' fa-lg"></i></button>' +
                '</td>' +
                '</tr>';
        }).join('');
    }

    /* ─── User Toggle Actions ─── */
    function activateUser(idx) {
        var user = STATE.users[idx];
        if (!user) return;
        user.active = true;
        user.status = 'Active';
        user.statusClass = 'bg-success-subtle text-success border border-success';
        renderUserTable();
        showActionToast(user.fullName + ' activated.', 'success');
    }

    function deactivateUser(idx) {
        var user = STATE.users[idx];
        if (!user) return;
        user.active = false;
        user.status = 'Inactive';
        user.statusClass = 'bg-secondary-subtle text-secondary border border-secondary';
        renderUserTable();
        showActionToast(user.fullName + ' deactivated.', 'secondary');
    }

    /* ─── System Parameters ─── */
    function populateSystemParams() {
        var params = STATE.systemParams;
        var fields = {
            settingsSoapMaxHistory: params.soapMaxHistoryRecords,
            settingsRestMaxHistory: params.restMaxHistoryRecords,
            settingsHealthTimeout: params.healthCheckTimeoutSec,
            settingsOrmFramework: params.ormFramework
        };

        Object.keys(fields).forEach(function (id) {
            var el = document.getElementById(id);
            if (el) el.value = fields[id] != null ? String(fields[id]) : '--';
        });
    }

    /* ─── Palette Gallery ─── */
    function renderPaletteGallery() {
        var gallery = document.getElementById('settingsPaletteGallery');
        if (!gallery) return;

        var paletteKeys = Object.keys(STATE.palettes);
        if (!paletteKeys.length) {
            gallery.innerHTML = '<div class="col-12 text-center text-muted py-3">No color palettes available.</div>';
            return;
        }

        gallery.innerHTML = paletteKeys.map(function (key) {
            var pal = STATE.palettes[key];
            var light = pal.light || {};
            var dark = pal.dark || {};
            var isSelected = STATE.selectedPalette === key;
            var selectedClass = isSelected ? ' border-primary' : '';

            return '<div class="col-md-4 col-lg-3">' +
                '<div class="card shadow-sm palette-card' + selectedClass + '" data-palette-key="' + key + '">' +
                '<div class="card-body">' +
                '<div class="d-flex gap-1 mb-2">' +
                '<div class="flex-fill" style="height:28px;border-radius:4px;background:' + (light.primary || '#ccc') + ';" title="Light Primary"></div>' +
                '<div class="flex-fill" style="height:28px;border-radius:4px;background:' + (dark.primary || '#333') + ';" title="Dark Primary"></div>' +
                '</div>' +
                '<h6 class="fw-semibold mb-1 fs-7">' + escapeHtml(pal.name || key) + '</h6>' +
                '<p class="fs-8 text-muted mb-2">' + escapeHtml(pal.description || '') + '</p>' +
                '<div class="d-flex gap-1">' +
                '<div class="flex-fill" style="height:10px;border-radius:2px;background:' + (light.accent || '#eee') + ';"></div>' +
                '<div class="flex-fill" style="height:10px;border-radius:2px;background:' + (dark.accent || '#444') + ';"></div>' +
                '</div>' +
                '</div>' +
                '</div>' +
                '</div>';
        }).join('');

        // Click handler for palette selection
        gallery.querySelectorAll('.palette-card').forEach(function (card) {
            card.addEventListener('click', function () {
                gallery.querySelectorAll('.palette-card').forEach(function (c) {
                    c.classList.remove('border-primary');
                });
                this.classList.add('border-primary');
                STATE.selectedPalette = this.dataset.paletteKey;
            });
        });
    }

    /* ─── Apply Palette ─── */
    function applyPalette() {
        var key = STATE.selectedPalette;
        if (!key || key === 'bootstrap-default') {
            resetPalette();
            return;
        }

        var pal = STATE.palettes[key];
        if (!pal) {
            showActionToast('Palette not found.', 'danger');
            return;
        }

        var isDark = document.documentElement.getAttribute('data-bs-theme') === 'dark';
        var useLighter = document.getElementById('settingsLighterPalette')?.checked !== false;

        var theme = isDark ? 'dark' : 'light';
        var colors = pal.ui ? pal.ui[theme] : null;

        if (colors) {
            document.documentElement.style.setProperty('--background-' + theme, colors.background);
            document.documentElement.style.setProperty('--surface-' + theme, colors.surface);
            document.documentElement.style.setProperty('--text-' + theme, colors.text);
            document.documentElement.style.setProperty('--border-' + theme, colors.border);
            document.documentElement.style.setProperty('--ux-bg-primary', colors.background);
            document.documentElement.style.setProperty('--ux-bg-secondary', colors.surface);
            document.documentElement.style.setProperty('--ux-text-primary', colors.text);
            document.documentElement.style.setProperty('--ux-text-secondary', colors.textSecondary);
            document.documentElement.style.setProperty('--ux-border', colors.border);
            document.documentElement.style.setProperty('--ux-active-bg', colors.activeBg);
        }

        var modeColors = pal[theme] || {};
        if (modeColors.primary) {
            document.documentElement.style.setProperty('--ux-primary', modeColors.primary);
            document.documentElement.style.setProperty('--ux-accent', modeColors.primary);
            document.documentElement.style.setProperty('--palette-primary-' + theme, modeColors.primary);
        }
        if (modeColors.secondary) {
            document.documentElement.style.setProperty('--ux-primary-700', modeColors.secondary);
            document.documentElement.style.setProperty('--palette-secondary-' + theme, modeColors.secondary);
        }
        if (modeColors.accent) {
            document.documentElement.style.setProperty('--ux-bg-tertiary', modeColors.accent);
            document.documentElement.style.setProperty('--palette-accent-' + theme, modeColors.accent);
        }
        if (modeColors.gradient) {
            document.documentElement.style.setProperty('--ux-gradient', modeColors.gradient);
            document.documentElement.style.setProperty('--palette-gradient-' + theme, modeColors.gradient);
        }
        if (modeColors.shadow) {
            document.documentElement.style.setProperty('--ux-shadow', modeColors.shadow);
            document.documentElement.style.setProperty('--palette-shadow-' + theme, modeColors.shadow);
        }

        document.documentElement.setAttribute('data-theme-palette', key);
        localStorage.setItem('devbiztools.palette', key);

        showActionToast('Palette "' + (pal.name || key) + '" applied.', 'success');
    }

    /* ─── Reset Palette ─── */
    function resetPalette() {
        STATE.selectedPalette = 'bootstrap-default';

        // Remove inline palette styles
        var theme = document.documentElement.getAttribute('data-bs-theme') || 'light';
        var props = [
            '--background-light', '--surface-light', '--text-light', '--border-light',
            '--background-dark', '--surface-dark', '--text-dark', '--border-dark',
            '--palette-primary-light', '--palette-secondary-light', '--palette-accent-light',
            '--palette-gradient-light', '--palette-shadow-light',
            '--palette-primary-dark', '--palette-secondary-dark', '--palette-accent-dark',
            '--palette-gradient-dark', '--palette-shadow-dark'
        ];
        props.forEach(function (prop) {
            document.documentElement.style.removeProperty(prop);
        });

        // Reset computed CSS vars back to stylesheet defaults
        document.documentElement.style.removeProperty('--ux-bg-primary');
        document.documentElement.style.removeProperty('--ux-bg-secondary');
        document.documentElement.style.removeProperty('--ux-bg-tertiary');
        document.documentElement.style.removeProperty('--ux-text-primary');
        document.documentElement.style.removeProperty('--ux-text-secondary');
        document.documentElement.style.removeProperty('--ux-border');
        document.documentElement.style.removeProperty('--ux-active-bg');
        document.documentElement.style.removeProperty('--ux-primary');
        document.documentElement.style.removeProperty('--ux-primary-700');
        document.documentElement.style.removeProperty('--ux-accent');
        document.documentElement.style.removeProperty('--ux-gradient');
        document.documentElement.style.removeProperty('--ux-shadow');

        document.documentElement.removeAttribute('data-theme-palette');
        localStorage.removeItem('devbiztools.palette');

        // Re-apply theme class
        document.documentElement.setAttribute('data-bs-theme', theme);

        // Update gallery selection
        document.querySelectorAll('.palette-card').forEach(function (c) {
            c.classList.toggle('border-primary', c.dataset.paletteKey === 'bootstrap-default');
        });

        showActionToast('Palette reset to Bootstrap Default.', 'success');
    }

    /* ─── Utility ─── */
    function escapeHtml(value) {
        return String(value ?? '')
            .replace(/&/g, '&amp;').replace(/</g, '&lt;')
            .replace(/>/g, '&gt;').replace(/"/g, '&quot;')
            .replace(/'/g, '&#39;');
    }

    /* ─── Public API ─── */
    window.SETTINGS_MODULE = {
        init: init,
        activateUser: activateUser,
        deactivateUser: deactivateUser,
        applyPalette: applyPalette,
        resetPalette: resetPalette
    };

    /* ─── Auto-init ─── */
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', init);
    } else {
        init();
    }

})();
