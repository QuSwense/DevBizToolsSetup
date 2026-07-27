/**
 * DevBizToolsSuite - Data Loader Module
 * Loads all sample data from individual JSON files into a global DATA store.
 * All data is cached after the first load for performance.
 */

const DATA = {
    appPerformance: [],
    serviceUtilization: [],
    recentActivity: [],
    environmentHealth: {},
    soapApps: [],
    soapRequestFiles: [],
    restApiRegistry: [],
    healthCheckRegistry: [],
    userWhitelist: [],
    systemParameters: {},
    colorPalettes: {},
    soapHistory: [],
    restHistory: []
};

const DATA_PATHS = {
    appPerformance: 'data/app-performance.json',
    serviceUtilization: 'data/service-utilization.json',
    recentActivity: 'data/recent-activity.json',
    environmentHealth: 'data/environment-health.json',
    soapApps: 'data/soap-apps.json',
    soapRequestFiles: 'data/soap-request-files.json',
    restApiRegistry: 'data/rest-api-registry.json',
    healthCheckRegistry: 'data/health-check-registry.json',
    userWhitelist: 'data/user-whitelist.json',
    systemParameters: 'data/system-parameters.json',
    colorPalettes: 'data/color-palettes.json',
    soapHistory: 'data/soap-history.json',
    restHistory: 'data/rest-history.json'
};

/**
 * Generic fetch wrapper that loads JSON from a path.
 * @param {string} path - Relative path to the JSON file
 * @returns {Promise<any>} Parsed JSON data
 */
async function loadJSON(path) {
    const response = await fetch(path);
    if (!response.ok) {
        throw new Error(`Failed to load ${path}: ${response.status} ${response.statusText}`);
    }
    return response.json();
}

/**
 * Load all data into the DATA store.
 * @returns {Promise<boolean>} true if all data loaded successfully
 */
async function loadAllData() {
    const promises = Object.entries(DATA_PATHS).map(async ([key, path]) => {
        try {
            DATA[key] = await loadJSON(path);
            return true;
        } catch (err) {
            console.warn(`[DataLoader] Could not load ${key} from ${path}:`, err.message);
            return false;
        }
    });

    const results = await Promise.all(promises);
    const allLoaded = results.every(r => r === true);

    if (allLoaded) {
        console.log('[DataLoader] All data loaded successfully.');
    } else {
        const failedCount = results.filter(r => r === false).length;
        console.warn(`[DataLoader] ${failedCount} data file(s) failed to load. Falling back to hardcoded data where needed.`);
    }

    return allLoaded;
}

// Export for use in other scripts
window.DATA = DATA;
window.loadAllData = loadAllData;
window.DATA_PATHS = DATA_PATHS;
