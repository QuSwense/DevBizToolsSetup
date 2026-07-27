/**
 * DevBizToolsSuite - Shared API / HTTP Helpers
 *
 * Provides common utility functions for making HTTP requests,
 * parsing responses, and handling errors across modules.
 */

const ApiHelpers = {
    /**
     * Generic fetch wrapper with timeout support.
     * @param {string} url - Target URL
     * @param {object} [options] - Fetch options (method, headers, body, etc.)
     * @param {number} [timeoutMs=30000] - Request timeout in milliseconds
     * @returns {Promise<object>} { ok, status, statusText, data, headers, elapsed }
     */
    async request(url, options = {}, timeoutMs = 30000) {
        const controller = new AbortController();
        const timer = setTimeout(() => controller.abort(), timeoutMs);

        const startTime = performance.now();

        try {
            const response = await fetch(url, {
                ...options,
                signal: controller.signal
            });

            const elapsed = Math.round(performance.now() - startTime);
            clearTimeout(timer);

            // Read body based on content type
            let data = null;
            const contentType = response.headers.get('content-type') || '';
            if (contentType.includes('application/json')) {
                data = await response.json();
            } else {
                data = await response.text();
            }

            // Collect response headers
            const headers = {};
            response.headers.forEach((value, name) => {
                headers[name] = value;
            });

            return {
                ok: response.ok,
                status: response.status,
                statusText: response.statusText,
                data,
                headers,
                elapsed,
                ttfb: elapsed // Simplified; real TTFB requires PerformanceObserver
            };
        } catch (err) {
            clearTimeout(timer);
            const elapsed = Math.round(performance.now() - startTime);

            if (err.name === 'AbortError') {
                throw new Error(`Request timed out after ${timeoutMs}ms`);
            }
            throw err;
        }
    },

    /**
     * Perform a GET request.
     * @param {string} url
     * @param {object} [headers]
     * @param {number} [timeoutMs]
     * @returns {Promise<object>}
     */
    get(url, headers = {}, timeoutMs = 30000) {
        return this.request(url, {
            method: 'GET',
            headers: { 'Accept': 'application/json', ...headers }
        }, timeoutMs);
    },

    /**
     * Perform a POST request.
     * @param {string} url
     * @param {*} body
     * @param {object} [headers]
     * @param {number} [timeoutMs]
     * @returns {Promise<object>}
     */
    post(url, body, headers = {}, timeoutMs = 30000) {
        const isFormData = body instanceof FormData;
        return this.request(url, {
            method: 'POST',
            headers: isFormData ? headers : { 'Content-Type': 'application/json', ...headers },
            body: isFormData ? body : JSON.stringify(body)
        }, timeoutMs);
    },

    /**
     * Perform a PUT request.
     * @param {string} url
     * @param {*} body
     * @param {object} [headers]
     * @param {number} [timeoutMs]
     * @returns {Promise<object>}
     */
    put(url, body, headers = {}, timeoutMs = 30000) {
        return this.request(url, {
            method: 'PUT',
            headers: { 'Content-Type': 'application/json', ...headers },
            body: JSON.stringify(body)
        }, timeoutMs);
    },

    /**
     * Perform a DELETE request.
     * @param {string} url
     * @param {object} [headers]
     * @param {number} [timeoutMs]
     * @returns {Promise<object>}
     */
    delete(url, headers = {}, timeoutMs = 30000) {
        return this.request(url, {
            method: 'DELETE',
            headers: { 'Accept': 'application/json', ...headers }
        }, timeoutMs);
    },

    /**
     * Parse XML string into a DOM document.
     * @param {string} xmlString
     * @returns {Document|null}
     */
    parseXml(xmlString) {
        try {
            const parser = new DOMParser();
            return parser.parseFromString(xmlString, 'text/xml');
        } catch (err) {
            console.error('[ApiHelpers] XML parse error:', err);
            return null;
        }
    },

    /**
     * Extract SOAP fault information from an XML response.
     * @param {string} xmlString
     * @returns {{ faultcode: string|null, faultstring: string|null, faultactor: string|null, detail: string|null }}
     */
    extractSoapFault(xmlString) {
        const doc = this.parseXml(xmlString);
        if (!doc) return { faultcode: null, faultstring: null, faultactor: null, detail: null };

        const getTagContent = (tagName) => {
            const el = doc.getElementsByTagNameNS('*', tagName)[0];
            return el ? el.textContent.trim() : null;
        };

        return {
            faultcode: getTagContent('faultcode') || getTagContent('Code'),
            faultstring: getTagContent('faultstring') || getTagContent('Reason'),
            faultactor: getTagContent('faultactor') || getTagContent('Role'),
            detail: getTagContent('detail') || getTagContent('Detail')
        };
    },

    /**
     * Build a full URL from base and path segments.
     * @param {string} baseUrl
     * @param {string} path
     * @returns {string}
     */
    buildUrl(baseUrl, path) {
        const base = baseUrl.replace(/\/+$/, '');
        const cleanPath = path.startsWith('/') ? path : '/' + path;
        return base + cleanPath;
    },

    /**
     * Format a duration in milliseconds to a human-readable string.
     * @param {number} ms
     * @returns {string}
     */
    formatDuration(ms) {
        if (ms < 1000) return `${Math.round(ms)} ms`;
        if (ms < 60000) return `${(ms / 1000).toFixed(1)} s`;
        return `${Math.floor(ms / 60000)}m ${Math.round((ms % 60000) / 1000)}s`;
    }
};

window.ApiHelpers = ApiHelpers;
