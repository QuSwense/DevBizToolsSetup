/**
 * DevBizToolsSuite - Health Checks Module
 * Handles health check registry, sequential/single execution, and detail viewing.
 */
(function () {
    'use strict';

    /* ─── Module State ─── */
    const STATE = {
        checks: [],
        currentDetail: null,
        isRunning: false,
        sequentialAborted: false
    };

    /* ─── Initialization ─── */
    function init() {
        if (!document.getElementById('healthAppsCards')) {
            setTimeout(init, 50);
            return;
        }

        loadChecks();
        renderCards();
        updateGroupCounts();
        initializeTooltips();
    }

    /* ─── Load Data ─── */
    function loadChecks() {
        var dataStore = window.DATA || {};
        STATE.checks = Array.isArray(dataStore.healthCheckRegistry)
            ? JSON.parse(JSON.stringify(dataStore.healthCheckRegistry))
            : [];
    }

    /* ─── Render Cards ─── */
    function renderCards() {
        var appsContainer = document.getElementById('healthAppsCards');
        var dbContainer = document.getElementById('healthDbCards');
        if (!appsContainer || !dbContainer) return;

        var appsChecks = STATE.checks.filter(function (c) { return c.group === 'apps'; });
        var dbChecks = STATE.checks.filter(function (c) { return c.group === 'database'; });

        appsContainer.innerHTML = appsChecks.map(buildCardHtml).join('');
        dbContainer.innerHTML = dbChecks.map(buildCardHtml).join('');
    }

    function buildCardHtml(check) {
        var mock = check.mockResult || {};
        var badgeClass = mock.badgeClass || 'badge-status-pending';
        var badgeText = mock.badgeHtml || 'Pending';
        var borderClass = mock.borderClass || 'border-secondary';
        var responseTime = mock.responseTime || '--';
        var statusText = mock.statusText || '--';

        return '<div class="col-md-4 col-lg-3" data-check-id="' + check.id + '">' +
            '<div class="card shadow-sm h-100 border-start border-3 ' + borderClass + '">' +
            '<div class="card-body d-flex flex-column">' +
            '<h6 class="card-title fw-semibold mb-1">' + escapeHtml(check.name) + '</h6>' +
            '<div class="fs-7 text-muted text-truncate mb-2" title="' + escapeHtml(check.endpoint) + '">' +
            '<code class="fs-8">' + escapeHtml(check.endpoint) + '</code></div>' +
            '<div class="d-flex justify-content-between align-items-center mb-1">' +
            '<span class="fs-7 text-muted">' + escapeHtml(check.field1Label || 'Response') + ':</span>' +
            '<span class="fw-semibold fs-7" id="health-rt-' + check.id + '">' + responseTime + '</span>' +
            '</div>' +
            '<div class="d-flex justify-content-between align-items-center mb-2">' +
            '<span class="fs-7 text-muted">' + escapeHtml(check.field2Label || 'Status') + ':</span>' +
            '<span id="health-status-' + check.id + '"><span class="badge ' + badgeClass + '">' + badgeText + '</span></span>' +
            '</div>' +
            '<div class="health-card-actions mt-auto">' +
            '<button class="btn btn-sm btn-outline-primary flex-fill" onclick="window.HEALTH_MODULE.runSingle(' + check.id + ')">' +
            '<i class="fa-solid fa-rotate me-1"></i>Run</button>' +
            '<button class="btn btn-sm btn-outline-info flex-fill" onclick="window.HEALTH_MODULE.showDetail(' + check.id + ')">' +
            '<i class="fa-solid fa-eye me-1"></i>Details</button>' +
            '</div>' +
            '</div>' +
            '</div>' +
            '</div>';
    }

    /* ─── Run Single Check ─── */
    function runSingle(checkId) {
        var check = STATE.checks.find(function (c) { return c.id === checkId; });
        if (!check) return;

        var rtEl = document.getElementById('health-rt-' + checkId);
        var statusEl = document.getElementById('health-status-' + checkId);
        if (!rtEl || !statusEl) return;

        // Set to checking state
        rtEl.textContent = 'Checking...';
        statusEl.innerHTML = '<span class="badge badge-status-checking"><i class="fa-solid fa-spinner fa-spin me-1"></i>Checking</span>';

        // Simulate check delay
        var delay = 300 + Math.round(Math.random() * 1200);
        setTimeout(function () {
            var mock = check.mockResult || {};
            var result = generateMockResult(check);

            rtEl.textContent = result.responseTime;
            statusEl.innerHTML = '<span class="badge ' + result.badgeClass + '">' + result.badgeHtml + '</span>';

            // Update card border
            var card = document.querySelector('[data-check-id="' + checkId + '"] .card');
            if (card) {
                card.className = card.className.replace(/border-\w+/g, '') + ' card shadow-sm h-100 border-start border-3 ' + result.borderClass;
            }

            showActionToast(check.name + ': ' + result.badgeHtml, result.badgeClass === 'badge-status-healthy' ? 'success' : 'danger');
            updateGroupCounts();
        }, delay);
    }

    /* ─── Run Sequential ─── */
    function runSequential() {
        if (STATE.isRunning) {
            showActionToast('Checks are already running.', 'warning');
            return;
        }

        STATE.isRunning = true;
        STATE.sequentialAborted = false;
        showActionToast('Starting sequential health checks...', 'info');

        var allChecks = STATE.checks.slice();
        var idx = 0;

        function runNext() {
            if (STATE.sequentialAborted || idx >= allChecks.length) {
                STATE.isRunning = false;
                if (!STATE.sequentialAborted) {
                    showActionToast('All health checks completed.', 'success');
                }
                return;
            }

            var check = allChecks[idx];
            var rtEl = document.getElementById('health-rt-' + check.id);
            var statusEl = document.getElementById('health-status-' + check.id);

            if (rtEl) rtEl.textContent = 'Checking...';
            if (statusEl) {
                statusEl.innerHTML = '<span class="badge badge-status-checking"><i class="fa-solid fa-spinner fa-spin me-1"></i>Checking</span>';
            }

            var delay = 300 + Math.round(Math.random() * 800);
            setTimeout(function () {
                if (STATE.sequentialAborted) {
                    STATE.isRunning = false;
                    return;
                }

                var result = generateMockResult(check);

                if (rtEl) rtEl.textContent = result.responseTime;
                if (statusEl) {
                    statusEl.innerHTML = '<span class="badge ' + result.badgeClass + '">' + result.badgeHtml + '</span>';
                }

                var card = document.querySelector('[data-check-id="' + check.id + '"] .card');
                if (card) {
                    card.className = card.className.replace(/border-\w+/g, '') + ' card shadow-sm h-100 border-start border-3 ' + result.borderClass;
                }

                updateGroupCounts();
                idx++;
                runNext();
            }, delay);
        }

        runNext();
    }

    /* ─── Generate Mock Result ─── */
    function generateMockResult(check) {
        // Use mockResult if available, otherwise generate
        if (check.mockResult) {
            return check.mockResult;
        }
        // Fallback random result
        var healthy = Math.random() > 0.2;
        return {
            borderClass: healthy ? 'border-success' : 'border-danger',
            badgeClass: healthy ? 'badge-status-healthy' : 'badge-status-danger',
            badgeHtml: healthy ? 'Healthy' : 'Failed',
            responseTime: healthy ? (20 + Math.round(Math.random() * 80)) + ' ms' : (2000 + Math.round(Math.random() * 3000)) + ' ms',
            statusText: healthy ? '200 OK' : '504 Timeout'
        };
    }

    /* ─── Show Detail ─── */
    function showDetail(checkId) {
        var check = STATE.checks.find(function (c) { return c.id === checkId; });
        if (!check) return;

        STATE.currentDetail = check;

        var detail = check.detailData || {};
        var status = detail.status || 'unknown';
        var titleEl = document.getElementById('healthDetailTitle');
        var bannerEl = document.getElementById('healthDetailBanner');
        var bannerTextEl = document.getElementById('healthDetailStatusText');
        var serviceEl = document.getElementById('healthDetailService');
        var endpointEl = document.getElementById('healthDetailEndpoint');
        var rtEl = document.getElementById('healthDetailResponseTime');
        var httpEl = document.getElementById('healthDetailHttpStatus');
        var tsEl = document.getElementById('healthDetailTimestamp');
        var bodyEl = document.getElementById('healthDetailBody');

        if (titleEl) titleEl.textContent = check.name;

        // Status banner
        if (bannerEl && bannerTextEl) {
            var bannerClass = status === 'healthy' ? 'healthy' : status === 'failed' ? 'failed' : 'warning';
            bannerEl.className = 'health-detail-status-banner ' + bannerClass;
            var icon = bannerEl.querySelector('i');
            if (icon) {
                icon.className = status === 'healthy' ? 'fa-solid fa-circle-check fa-lg'
                    : status === 'failed' ? 'fa-solid fa-circle-xmark fa-lg'
                        : 'fa-solid fa-triangle-exclamation fa-lg';
            }
            bannerTextEl.textContent = detail.statusText || status;
        }

        // Meta info
        if (serviceEl) serviceEl.textContent = check.name;
        if (endpointEl) endpointEl.textContent = check.endpoint || '--';
        if (rtEl) rtEl.textContent = detail.responseTime || '--';
        if (httpEl) httpEl.textContent = detail.httpStatus || '--';
        if (tsEl) tsEl.textContent = new Date().toLocaleString();

        // Body
        if (bodyEl) {
            bodyEl.textContent = detail.body || 'No response body available.';
        }

        var modal = new bootstrap.Modal(document.getElementById('healthDetailModal'));
        modal.show();
    }

    /* ─── Copy Detail Body ─── */
    window.copyHealthDetailBody = function () {
        var bodyEl = document.getElementById('healthDetailBody');
        if (!bodyEl || !bodyEl.textContent) return;
        navigator.clipboard.writeText(bodyEl.textContent).then(function () {
            showActionToast('Response body copied to clipboard.', 'success');
        }).catch(function () {
            showActionToast('Failed to copy.', 'danger');
        });
    };

    /* ─── Update Group Counts ─── */
    function updateGroupCounts() {
        var appsCount = document.getElementById('healthAppsCount');
        var dbCount = document.getElementById('healthDbCount');

        var appsChecks = STATE.checks.filter(function (c) { return c.group === 'apps'; });
        var dbChecks = STATE.checks.filter(function (c) { return c.group === 'database'; });

        var appsHealthy = appsChecks.filter(function (c) {
            var el = document.getElementById('health-status-' + c.id);
            return el && el.textContent.includes('Healthy') || el && el.textContent.includes('Connected');
        }).length;

        var dbHealthy = dbChecks.filter(function (c) {
            var el = document.getElementById('health-status-' + c.id);
            return el && el.textContent.includes('Healthy') || el && el.textContent.includes('Connected');
        }).length;

        if (appsCount) appsCount.textContent = appsHealthy + ' / ' + appsChecks.length;
        if (dbCount) dbCount.textContent = dbHealthy + ' / ' + dbChecks.length;
    }

    /* ─── Utility ─── */
    function escapeHtml(value) {
        return String(value ?? '')
            .replace(/&/g, '&amp;').replace(/</g, '&lt;')
            .replace(/>/g, '&gt;').replace(/"/g, '&quot;')
            .replace(/'/g, '&#39;');
    }

    /* ─── Public API ─── */
    window.HEALTH_MODULE = {
        init: init,
        runSingle: runSingle,
        runSequential: runSequential,
        showDetail: showDetail
    };

    /* ─── Auto-init ─── */
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', init);
    } else {
        init();
    }

})();
