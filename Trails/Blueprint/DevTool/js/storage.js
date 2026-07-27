/**
 * DevBizToolsSuite - Generic Namespaced Storage Utility
 *
 * Provides a safe, namespaced wrapper around localStorage so that:
 * 1. All keys are automatically prefixed with the app namespace
 *    (e.g. "devbiztools.sidebar.collapsed") — preventing collisions
 *    with other applications that may use the same key names.
 * 2. Every operation is wrapped in try/catch to handle private-browsing
 *    mode, storage quota errors, or disabled storage gracefully.
 * 3. Common patterns (get/set/remove, JSON serialization, defaults,
 *    namespaced clear) are available as single method calls.
 *
 * Usage:
 *   AppStorage.set(APP.STORAGE_KEYS.SIDEBAR_COLLAPSED, '1');
 *   const val = AppStorage.get(APP.STORAGE_KEYS.SIDEBAR_COLLAPSED, '0');
 *   AppStorage.setObject(APP.STORAGE_KEYS.FONT, { family, size });
 *   const obj = AppStorage.getObject(APP.STORAGE_KEYS.FONT);
 *   AppStorage.remove(APP.STORAGE_KEYS.FONT);
 *   AppStorage.clear();  // removes only keys under the current namespace
 */
const AppStorage = {
    /** The namespace prefix (e.g. "devbiztools."). Set during init. */
    _prefix: null,

    /**
     * Initialise the storage utility with a namespace string.
     * Must be called once before any get/set operations.
     * @param {string} namespace - The app namespace (e.g. "devbiztools")
     */
    init(namespace) {
        this._prefix = namespace ? namespace + '.' : '';
    },

    /**
     * Build the fully-qualified localStorage key.
     * @param {string} key - Relative key (e.g. "sidebar.collapsed")
     * @returns {string} Full key with namespace prefix
     */
    _fullKey(key) {
        return this._prefix + key;
    },

    /**
     * Retrieve a raw string value from storage.
     * @param {string} key - Relative key
     * @param {*} [defaultValue=null] - Fallback if key is missing or error
     * @returns {string|null} Stored value or defaultValue
     */
    get(key, defaultValue = null) {
        try {
            const val = localStorage.getItem(this._fullKey(key));
            return val !== null ? val : defaultValue;
        } catch {
            return defaultValue;
        }
    },

    /**
     * Store a string value.
     * @param {string} key - Relative key
     * @param {*} value - Value to store (converted to String)
     */
    set(key, value) {
        try {
            localStorage.setItem(this._fullKey(key), String(value));
        } catch {
            // Storage unavailable or quota exceeded — silently ignore
        }
    },

    /**
     * Retrieve a JSON-parsed object from storage.
     * @param {string} key - Relative key
     * @param {*} [defaultValue=null] - Fallback if key is missing, invalid JSON, or error
     * @returns {*} Parsed value or defaultValue
     */
    getObject(key, defaultValue = null) {
        try {
            const raw = localStorage.getItem(this._fullKey(key));
            return raw ? JSON.parse(raw) : defaultValue;
        } catch {
            return defaultValue;
        }
    },

    /**
     * Store a value as JSON.
     * @param {string} key - Relative key
     * @param {*} value - Value to JSON-serialize and store
     */
    setObject(key, value) {
        try {
            localStorage.setItem(this._fullKey(key), JSON.stringify(value));
        } catch {
            // Storage unavailable or quota exceeded
        }
    },

    /**
     * Remove a single key from storage.
     * @param {string} key - Relative key
     */
    remove(key) {
        try {
            localStorage.removeItem(this._fullKey(key));
        } catch {
            // Ignore
        }
    },

    /**
     * Remove ALL keys that belong to the current namespace.
     * Other applications' keys are left untouched.
     */
    clear() {
        try {
            const prefix = this._prefix;
            const keysToRemove = [];
            for (let i = 0; i < localStorage.length; i++) {
                const key = localStorage.key(i);
                if (key && key.startsWith(prefix)) {
                    keysToRemove.push(key);
                }
            }
            keysToRemove.forEach(k => localStorage.removeItem(k));
        } catch {
            // Ignore
        }
    }
};

// Expose globally
window.AppStorage = AppStorage;
