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
        loadFontSettings();
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

        // Restore gradient mode checkbox from localStorage.
        // Default to checked (true) since CSS default :root has a gradient.
        var savedGradient = localStorage.getItem('devbiztools.gradient');
        var gradientCheckbox = document.getElementById('settingsGradientMode');
        if (gradientCheckbox) {
            gradientCheckbox.checked = savedGradient !== null ? savedGradient === 'true' : true;
        }

        // Sync data-gradient-mode attribute on <html> with saved gradient state
        // so gradient-enhanced CSS is active immediately on page load
        var gradientOn = gradientCheckbox ? gradientCheckbox.checked : true;
        if (gradientOn) {
            document.documentElement.setAttribute('data-gradient-mode', 'true');
        } else {
            document.documentElement.removeAttribute('data-gradient-mode');
        }

        // Restore lighter palette checkbox from localStorage.
        // Default to checked (true) so UI uses the lighter/softer variant.
        var savedLighter = localStorage.getItem('devbiztools.lighterPalette');
        var lighterCheckbox = document.getElementById('settingsLighterPalette');
        if (lighterCheckbox) {
            lighterCheckbox.checked = savedLighter !== null ? savedLighter === 'true' : true;
        }

        // Restore theme mode from localStorage and update both the toggle and the label.
        var savedTheme = localStorage.getItem('devbiztools.theme');
        if (savedTheme === 'dark' || savedTheme === 'light') {
            document.documentElement.setAttribute('data-bs-theme', savedTheme);
        }
        syncThemeToggleUI();
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
            var toggleIcon = user.active ? 'bi-toggle2-on text-success' : 'bi-toggle2-off text-muted';
            var toggleAction = user.active ? 'deactivateUser' : 'activateUser';
            return '<tr>' +
                '<td class="fw-semibold font-monospace fs-7">' + escapeHtml(user.username) + '</td>' +
                '<td>' + escapeHtml(user.fullName) + '</td>' +
                '<td><span class="badge ' + statusClass + ' fs-8">' + escapeHtml(user.status) + '</span></td>' +
                '<td class="fs-7">' + escapeHtml(user.createdDate) + '</td>' +
                '<td class="text-center">' +
                '<button class="btn btn-sm btn-outline-secondary" onclick="window.SETTINGS_MODULE.' + toggleAction + '(' + idx + ')" title="' + (user.active ? 'Deactivate' : 'Activate') + '">' +
                '<i class="bi ' + toggleIcon + ' fs-5"></i></button>' +
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
        // Read checkbox states FIRST, before any early return
        var useGradient = document.getElementById('settingsGradientMode')?.checked === true;
        var key = STATE.selectedPalette;

        // Handle bootstrap-default: reset then optionally override gradient
        if (!key || key === 'bootstrap-default') {
            resetPalette(useGradient);
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
            var bg = colors.background;
            var surface = colors.surface;
            var text = colors.text;
            var border = colors.border;
            var textSecondary = colors.textSecondary;
            var activeBg = colors.activeBg;

            // When "Use lighter palette variant" is checked, slightly lighten the UI colors
            if (useLighter) {
                bg = lightenColor(bg, 12);
                surface = lightenColor(surface, 10);
                border = lightenColor(border, 15);
                activeBg = lightenColor(activeBg, 8);
            }

            document.documentElement.style.setProperty('--background-' + theme, bg);
            document.documentElement.style.setProperty('--surface-' + theme, surface);
            document.documentElement.style.setProperty('--text-' + theme, text);
            document.documentElement.style.setProperty('--border-' + theme, border);
            document.documentElement.style.setProperty('--ux-bg-primary', bg);
            document.documentElement.style.setProperty('--ux-bg-secondary', surface);
            document.documentElement.style.setProperty('--ux-text-primary', text);
            document.documentElement.style.setProperty('--ux-text-secondary', textSecondary);
            document.documentElement.style.setProperty('--ux-border', border);
            document.documentElement.style.setProperty('--ux-active-bg', activeBg);
        }

        var modeColors = pal[theme] || {};

        // When "Use lighter palette variant" is checked, also lighten the mode colors
        var lightPrimary, lightSecondary, lightAccent, lightGradient, lightShadow;
        if (useLighter) {
            lightPrimary = lightenColor(modeColors.primary, 10);
            lightSecondary = lightenColor(modeColors.secondary, 8);
            lightAccent = lightenColor(modeColors.accent, 10);
            lightGradient = lightenGradient(modeColors.gradient, 10);
            lightShadow = lightenRgbaColor(modeColors.shadow, 10);
        } else {
            lightPrimary = modeColors.primary;
            lightSecondary = modeColors.secondary;
            lightAccent = modeColors.accent;
            lightGradient = modeColors.gradient;
            lightShadow = modeColors.shadow;
        }

        if (lightPrimary) {
            document.documentElement.style.setProperty('--ux-primary', lightPrimary);
            document.documentElement.style.setProperty('--ux-accent', lightPrimary);
            document.documentElement.style.setProperty('--palette-primary-' + theme, lightPrimary);
        }
        if (lightSecondary) {
            document.documentElement.style.setProperty('--ux-primary-700', lightSecondary);
            document.documentElement.style.setProperty('--palette-secondary-' + theme, lightSecondary);
        }
        if (lightAccent) {
            document.documentElement.style.setProperty('--ux-bg-tertiary', lightAccent);
            document.documentElement.style.setProperty('--palette-accent-' + theme, lightAccent);
        }
        if (lightGradient) {
            if (useGradient) {
                document.documentElement.style.setProperty('--ux-gradient', lightGradient);
                document.documentElement.style.setProperty('--palette-gradient-' + theme, lightGradient);
            } else {
                // Solid color fallback on navbar when gradient mode is off
                document.documentElement.style.setProperty('--ux-gradient', lightPrimary || 'none');
                document.documentElement.style.removeProperty('--palette-gradient-' + theme);
            }
        } else if (!useGradient) {
            // No gradient defined in palette but gradient mode is off — still ensure solid
            document.documentElement.style.setProperty('--ux-gradient', lightPrimary || 'none');
        }
        if (lightShadow) {
            document.documentElement.style.setProperty('--ux-shadow', lightShadow);
            document.documentElement.style.setProperty('--palette-shadow-' + theme, lightShadow);
        }

        // Manage data-gradient-mode attribute on <html> so CSS gradient-mode
        // enhancement rules (sidebar, card headers, active nav, etc.) take effect
        if (useGradient) {
            document.documentElement.setAttribute('data-gradient-mode', 'true');
        } else {
            document.documentElement.removeAttribute('data-gradient-mode');
        }

        document.documentElement.setAttribute('data-theme-palette', key);
        localStorage.setItem('devbiztools.palette', key);
        localStorage.setItem('devbiztools.gradient', String(useGradient));
        localStorage.setItem('devbiztools.lighterPalette', String(useLighter));

        showActionToast('Palette "' + (pal.name || key) + '" applied.', 'success');
    }

    /* ─── Reset Palette ─── */
    function resetPalette(useGradient) {
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
        localStorage.removeItem('devbiztools.gradient');
        localStorage.removeItem('devbiztools.lighterPalette');

        // If gradient mode is off, override the CSS default gradient with a solid primary color
        if (useGradient === false) {
            var primaryColor = theme === 'dark' ? '#6ea8fe' : '#0d6efd';
            document.documentElement.style.setProperty('--ux-gradient', primaryColor);
        }

        // Sync data-gradient-mode attribute so CSS gradient enhancements are disabled on reset
        if (useGradient) {
            document.documentElement.setAttribute('data-gradient-mode', 'true');
        } else {
            document.documentElement.removeAttribute('data-gradient-mode');
        }

        // Re-apply theme class
        document.documentElement.setAttribute('data-bs-theme', theme);

        // Update gallery selection
        document.querySelectorAll('.palette-card').forEach(function (c) {
            c.classList.toggle('border-primary', c.dataset.paletteKey === 'bootstrap-default');
        });

        showActionToast('Palette reset to Bootstrap Default.', 'success');
    }

    /* ─── Font Settings ─── */

    /* Default font configuration (matches common.css :root defaults) */
    var FONT_DEFAULTS = {
        fontFamily: "'Segoe UI', system-ui, -apple-system, sans-serif",
        fontSizeBase: '0.875rem',
        fontSizeHeadings: '1.25',
        fontMonospace: "'Cascadia Code', 'JetBrains Mono', Consolas, 'Courier New', monospace"
    };

    /**
     * Load saved font settings from localStorage and populate UI controls.
     */
    function loadFontSettings() {
        var saved = {};
        try {
            var raw = localStorage.getItem('devbiztools.font');
            if (raw) saved = JSON.parse(raw);
        } catch (e) {
            // ignore parse errors
        }

        var familyEl = document.getElementById('settingsFontFamily');
        var sizeEl = document.getElementById('settingsFontSizeBase');
        var headingEl = document.getElementById('settingsFontSizeHeadings');
        var monoEl = document.getElementById('settingsFontMonospace');

        if (familyEl) familyEl.value = saved.fontFamily || FONT_DEFAULTS.fontFamily;
        if (sizeEl) sizeEl.value = saved.fontSizeBase || FONT_DEFAULTS.fontSizeBase;
        if (headingEl) headingEl.value = saved.fontSizeHeadings || FONT_DEFAULTS.fontSizeHeadings;
        if (monoEl) monoEl.value = saved.fontMonospace || FONT_DEFAULTS.fontMonospace;

        // Apply saved fonts to the document
        applyFontVars(
            saved.fontFamily || FONT_DEFAULTS.fontFamily,
            saved.fontSizeBase || FONT_DEFAULTS.fontSizeBase,
            saved.fontSizeHeadings || FONT_DEFAULTS.fontSizeHeadings,
            saved.fontMonospace || FONT_DEFAULTS.fontMonospace
        );
    }

    /**
     * Apply CSS custom properties for fonts to the document root.
     */
    function applyFontVars(family, baseSize, headingMultiplier, monospace) {
        var root = document.documentElement;
        root.style.setProperty('--font-family-base', family);
        root.style.setProperty('--font-family-heading', family);
        root.style.setProperty('--font-family-monospace', monospace);
        root.style.setProperty('--font-size-base', baseSize);

        // Derive proportional heading sizes
        var mult = parseFloat(headingMultiplier) || 1.25;
        var base = parseFloat(baseSize) || 0.875;
        root.style.setProperty('--font-size-xs', '0.72rem');
        root.style.setProperty('--font-size-sm', (base * 0.94).toFixed(3) + 'rem');
        root.style.setProperty('--font-size-lg', (base * 1.14).toFixed(3) + 'rem');
        root.style.setProperty('--font-size-xl', (base * 1.43).toFixed(3) + 'rem');
        root.style.setProperty('--font-size-2xl', (base * 1.71).toFixed(3) + 'rem');
        root.style.setProperty('--font-size-heading', (base * mult).toFixed(3) + 'rem');
    }

    /**
     * Apply font settings from the UI controls and persist to localStorage.
     */
    function applyFontSettings() {
        var family = document.getElementById('settingsFontFamily')?.value || FONT_DEFAULTS.fontFamily;
        var baseSize = document.getElementById('settingsFontSizeBase')?.value || FONT_DEFAULTS.fontSizeBase;
        var headingMult = document.getElementById('settingsFontSizeHeadings')?.value || FONT_DEFAULTS.fontSizeHeadings;
        var monospace = document.getElementById('settingsFontMonospace')?.value || FONT_DEFAULTS.fontMonospace;

        applyFontVars(family, baseSize, headingMult, monospace);

        // Persist to localStorage
        try {
            localStorage.setItem('devbiztools.font', JSON.stringify({
                fontFamily: family,
                fontSizeBase: baseSize,
                fontSizeHeadings: headingMult,
                fontMonospace: monospace
            }));
        } catch (e) {
            // ignore storage errors
        }

        showActionToast('Font settings applied.', 'success');
    }

    /**
     * Reset font settings to defaults.
     */
    function resetFontSettings() {
        var root = document.documentElement;
        root.style.removeProperty('--font-family-base');
        root.style.removeProperty('--font-family-heading');
        root.style.removeProperty('--font-family-monospace');
        root.style.removeProperty('--font-size-base');
        root.style.removeProperty('--font-size-xs');
        root.style.removeProperty('--font-size-sm');
        root.style.removeProperty('--font-size-lg');
        root.style.removeProperty('--font-size-xl');
        root.style.removeProperty('--font-size-2xl');
        root.style.removeProperty('--font-size-heading');

        localStorage.removeItem('devbiztools.font');

        // Reset UI controls to defaults
        var familyEl = document.getElementById('settingsFontFamily');
        var sizeEl = document.getElementById('settingsFontSizeBase');
        var headingEl = document.getElementById('settingsFontSizeHeadings');
        var monoEl = document.getElementById('settingsFontMonospace');

        if (familyEl) familyEl.value = FONT_DEFAULTS.fontFamily;
        if (sizeEl) sizeEl.value = FONT_DEFAULTS.fontSizeBase;
        if (headingEl) headingEl.value = FONT_DEFAULTS.fontSizeHeadings;
        if (monoEl) monoEl.value = FONT_DEFAULTS.fontMonospace;

        showActionToast('Font settings reset to defaults.', 'success');
    }

    /* ─── Utility ─── */

    /**
     * Lighten a hex color by a given percentage (0-100).
     * Returns the original color if it cannot be parsed.
     */
    function lightenColor(hex, percent) {
        if (!hex || hex === '#ccc' || hex === '#eee' || hex === '#333' || hex === '#444') return hex;
        var num = parseInt(hex.replace('#', ''), 16);
        if (isNaN(num)) return hex;
        var amt = Math.round(255 * percent / 100);
        var R = Math.min(255, (num >> 16) + amt);
        var G = Math.min(255, ((num >> 8) & 0x00FF) + amt);
        var B = Math.min(255, (num & 0x0000FF) + amt);
        return '#' + (1 << 24 | R << 16 | G << 8 | B).toString(16).slice(1);
    }

    /**
     * Lighten all hex color values found inside a CSS gradient string.
     * e.g. 'linear-gradient(135deg, #eff6ff, #1d4ed8)' -> 'linear-gradient(135deg, #f0f7ff, #3175ff)'
     */
    function lightenGradient(gradientStr, percent) {
        if (!gradientStr) return gradientStr;
        return gradientStr.replace(/#[0-9a-fA-F]{3,8}/g, function (match) {
            // Normalize shorthand hex (#abc -> #aabbcc)
            var hex = match;
            if (hex.length === 4) {
                hex = '#' + hex[1] + hex[1] + hex[2] + hex[2] + hex[3] + hex[3];
            }
            return lightenColor(hex, percent);
        });
    }

    /**
     * Lighten the RGB component of an rgba() or rgb() color string.
     * e.g. 'rgba(15, 23, 42, 0.08)' -> 'rgba(46, 54, 73, 0.08)'
     */
    function lightenRgbaColor(rgbaStr, percent) {
        if (!rgbaStr) return rgbaStr;
        var match = rgbaStr.match(/rgba?\(\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)(?:\s*,\s*([\d.]+))?\s*\)/);
        if (!match) return rgbaStr;
        var r = Math.min(255, parseInt(match[1], 10) + Math.round(255 * percent / 100));
        var g = Math.min(255, parseInt(match[2], 10) + Math.round(255 * percent / 100));
        var b = Math.min(255, parseInt(match[3], 10) + Math.round(255 * percent / 100));
        var a = match[4] !== undefined ? match[4] : '1';
        return 'rgba(' + r + ', ' + g + ', ' + b + ', ' + a + ')';
    }

    function escapeHtml(value) {
        return String(value ?? '')
            .replace(/&/g, '&amp;').replace(/</g, '&lt;')
            .replace(/>/g, '&gt;').replace(/"/g, '&quot;')
            .replace(/'/g, '&#39;');
    }

    /* ─── Theme Toggle ─── */

    /**
     * Sync the theme toggle checkbox and label text to match the current
     * data-bs-theme attribute on <html>.
     */
    function syncThemeToggleUI() {
        var isDark = document.documentElement.getAttribute('data-bs-theme') === 'dark';
        var toggle = document.getElementById('settingsThemeToggle');
        var label = document.getElementById('settingsThemeLabel');
        if (toggle) {
            toggle.checked = isDark;
        }
        if (label) {
            label.innerHTML = isDark
                ? '<i class="bi bi-moon me-1"></i>Dark Mode'
                : '<i class="bi bi-sun me-1"></i>Light Mode';
        }
    }

    /**
     * Toggle between dark and light theme.
     * Updates data-bs-theme on <html>, persists to localStorage, syncs the UI,
     * then re-applies the current palette so the new theme's colors take effect.
     */
    function toggleTheme() {
        var isDark = document.documentElement.getAttribute('data-bs-theme') === 'dark';
        var newTheme = isDark ? 'light' : 'dark';

        document.documentElement.setAttribute('data-bs-theme', newTheme);
        localStorage.setItem('devbiztools.theme', newTheme);

        syncThemeToggleUI();

        // Re-apply current palette so the new theme's color values take over
        applyPalette();

        showActionToast('Switched to ' + (newTheme === 'dark' ? 'Dark' : 'Light') + ' Mode.', 'info');
    }

    /* ─── Public API ─── */
    window.SETTINGS_MODULE = {
        init: init,
        activateUser: activateUser,
        deactivateUser: deactivateUser,
        applyPalette: applyPalette,
        resetPalette: resetPalette,
        applyFontSettings: applyFontSettings,
        resetFontSettings: resetFontSettings,
        toggleTheme: toggleTheme
    };

    /* ─── Auto-init ─── */
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', init);
    } else {
        init();
    }

})();
