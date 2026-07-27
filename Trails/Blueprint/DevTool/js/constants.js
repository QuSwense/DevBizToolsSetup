/**
 * DevBizToolsSuite - Central Application Constants
 *
 * Single source of truth for all app-wide constants, including
 * the namespace prefix and localStorage key definitions.
 * Every other module should import/use these constants rather
 * than duplicating string literals.
 */
const APP = {
    /* ─── App Identity ─── */
    NAMESPACE: 'devbiztools',
    NAME: 'DevBizToolsSuite',
    VERSION: 'v1.0 (.NET 8)',

    /* ─── localStorage Key Definitions ───
     *
     * These are relative keys — the AppStorage utility automatically
     * prepends the namespace (e.g. "devbiztools.sidebar.collapsed").
     * Keys are organized by feature area for discoverability.
     */

    STORAGE_KEYS: {
        // ─── Common / Global ───
        SIDEBAR_COLLAPSED: 'sidebar.collapsed',
        FONT: 'font',

        // ─── Dashboard Module ───
        DASHBOARD_APP_PERF_VIEW: 'dashboard.appPerformanceView',
        DASHBOARD_APP_PERF_METRIC: 'dashboard.appPerformanceMetric',
        DASHBOARD_SERVICE_UTIL_VIEW: 'dashboard.serviceUtilView',

        // ─── Settings Module ───
        SETTINGS_PALETTE: 'palette',
        SETTINGS_GRADIENT: 'gradient',
        SETTINGS_LIGHTER_PALETTE: 'lighterPalette',
        SETTINGS_THEME: 'theme',

        // ─── Test Suites Module ───
        TS_HISTORY_VIEW: 'ts.historyView',
        TS_GRAPH_METRIC: 'ts.graphMetric'
    },

    /* ─── Default Values ─── */
    DEFAULTS: {
        DASHBOARD_APP_PERF_VIEW: 'list',
        DASHBOARD_APP_PERF_METRIC: 'calls',
        DASHBOARD_SERVICE_UTIL_VIEW: 'list',
        SETTINGS_GRADIENT: true,
        SETTINGS_LIGHTER_PALETTE: true,
        TS_HISTORY_VIEW: 'list',
        TS_GRAPH_METRIC: 'passfail'
    }
};

// Expose globally so all modules can reference APP.STORAGE_KEYS.*
window.APP = APP;
