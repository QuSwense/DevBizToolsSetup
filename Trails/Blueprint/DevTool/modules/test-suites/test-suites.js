/**
 * DevBizToolsSuite - Test Suites Module
 * Manages combined test suites with cases derived from SOAP & REST request files.
 * Provides execution history with stats, charts, and detailed results.
 */
(function () {
    'use strict';

    /* ─── Module State ─── */
    const STATE = {
        suites: [],
        history: [],
        historyIdCounter: 1,
        suiteIdCounter: 1,
        historyChart: null,
        durationChart: null,
        paginationState: null,
        VIEW_KEY: APP.STORAGE_KEYS.TS_HISTORY_VIEW,
        METRIC_KEY: APP.STORAGE_KEYS.TS_GRAPH_METRIC
    };

    /* ─── Initialization ─── */
    function init() {
        if (!document.getElementById('tsSuitesContainer')) {
            setTimeout(init, 50);
            return;
        }

        loadData();
        renderAll();
        setupFilters();
        setupViewToggles();
        setupMetricToggles();
        registerPagination();
        restoreSavedViews();
        initializeTooltips();
    }

    /* ─── Data Loading ─── */
    function loadData() {
        var dataStore = window.DATA || {};

        // Build sample suites with test cases from SOAP & REST request files
        var soapFiles = Array.isArray(dataStore.soapRequestFiles) ? dataStore.soapRequestFiles : [];
        var restFiles = [];

        // Try to load REST request files if available
        if (Array.isArray(dataStore.restRequestFiles)) {
            restFiles = dataStore.restRequestFiles;
        }

        // Build test cases from request files
        var soapCases = soapFiles.map(function (f, i) {
            return {
                id: 'tc-soap-' + i,
                name: f.actionName || f.name || 'SOAP Case ' + (i + 1),
                fileName: f.name || '',
                application: f.application || '',
                apiType: 'soap',
                action: f.actionName || f.soapAction || '',
                status: 'pending',
                lastRun: null,
                lastDuration: null
            };
        });

        // If no REST files data, create some samples
        if (!restFiles.length) {
            restFiles = [
                { name: 'getInventory.json', application: 'Inventory Service API', method: 'GET', endpoint: '/items', payloadSize: '0.5 KB', lastModified: '2026-03-30 08:15' },
                { name: 'createCustomer.json', application: 'Customer Profile API', method: 'POST', endpoint: '/', payloadSize: '1.2 KB', lastModified: '2026-03-29 14:30' },
                { name: 'searchBilling.json', application: 'Billing Events API', method: 'GET', endpoint: '/events', payloadSize: '0.3 KB', lastModified: '2026-03-28 16:45' }
            ];
        }

        var restCases = restFiles.map(function (f, i) {
            return {
                id: 'tc-rest-' + i,
                name: (f.method || 'GET') + ' ' + (f.endpoint || f.name || ''),
                fileName: f.name || '',
                application: f.application || '',
                apiType: 'rest',
                action: f.method || 'GET',
                status: 'pending',
                lastRun: null,
                lastDuration: null
            };
        });

        // Build suites
        STATE.suites = [
            {
                id: 'suite-' + (STATE.suiteIdCounter++),
                name: 'Payment Smoke Tests',
                app: 'Payment Gateway Service',
                apiType: 'soap',
                description: 'Core payment flow verification',
                cases: soapCases.slice(0, 2)
            },
            {
                id: 'suite-' + (STATE.suiteIdCounter++),
                name: 'Customer Account Validation',
                app: 'Customer Account Service',
                apiType: 'soap',
                description: 'Account CRUD test cases',
                cases: soapCases.slice(2, 4)
            },
            {
                id: 'suite-' + (STATE.suiteIdCounter++),
                name: 'Inventory API Tests',
                app: 'Inventory Service API',
                apiType: 'rest',
                description: 'REST inventory endpoint verification',
                cases: restCases.slice(0, 2)
            },
            {
                id: 'suite-' + (STATE.suiteIdCounter++),
                name: 'Customer Profile REST Suite',
                app: 'Customer Profile API',
                apiType: 'rest',
                description: 'Customer profile CRUD operations',
                cases: restCases.slice(1, 3)
            }
        ];

        // Build sample execution history
        var now = new Date();
        var sampleHistory = [
            buildHistoryEntry('suite-1', soapCases[0], 'pass', 120, now),
            buildHistoryEntry('suite-1', soapCases[1], 'pass', 195, new Date(now - 60000)),
            buildHistoryEntry('suite-2', soapCases[2], 'fail', 320, new Date(now - 120000)),
            buildHistoryEntry('suite-2', soapCases[3], 'pass', 88, new Date(now - 180000)),
            buildHistoryEntry('suite-3', restCases[0], 'pass', 65, new Date(now - 240000)),
            buildHistoryEntry('suite-3', restCases[1], 'fail', 450, new Date(now - 300000)),
            buildHistoryEntry('suite-4', restCases[1], 'pass', 145, new Date(now - 360000)),
            buildHistoryEntry('suite-4', restCases[2], 'pass', 92, new Date(now - 420000)),
            buildHistoryEntry('suite-1', soapCases[0], 'pass', 110, new Date(now - 480000)),
            buildHistoryEntry('suite-2', soapCases[2], 'pass', 205, new Date(now - 540000)),
            buildHistoryEntry('suite-3', restCases[0], 'pass', 78, new Date(now - 600000)),
            buildHistoryEntry('suite-4', restCases[2], 'fail', 380, new Date(now - 660000)),
            buildHistoryEntry('suite-1', soapCases[1], 'pass', 155, new Date(now - 720000)),
            buildHistoryEntry('suite-2', soapCases[3], 'pass', 95, new Date(now - 780000)),
            buildHistoryEntry('suite-3', restCases[1], 'pass', 130, new Date(now - 840000))
        ];

        STATE.history = sampleHistory;
        STATE.historyIdCounter = sampleHistory.length + 1;

        // Update case statuses based on history
        STATE.history.forEach(function (entry) {
            STATE.suites.forEach(function (suite) {
                suite.cases.forEach(function (tc) {
                    if (tc.id === entry.caseId) {
                        tc.status = entry.result;
                        tc.lastRun = entry.timestamp;
                        tc.lastDuration = entry.duration;
                    }
                });
            });
        });
    }

    function buildHistoryEntry(suiteId, tc, result, duration, date) {
        var suite = STATE.suites.find(function (s) { return s.id === suiteId; });
        return {
            id: 'hist-' + (STATE.historyIdCounter++),
            timestamp: formatTimestamp(date),
            suiteId: suiteId,
            suiteName: suite ? suite.name : 'Unknown',
            caseId: tc.id,
            caseName: tc.name,
            fileName: tc.fileName,
            application: tc.application,
            apiType: tc.apiType,
            action: tc.action,
            result: result,
            duration: duration,
            error: result === 'fail' ? 'Assertion failed: Expected status 200, got 500' : null,
            responseSummary: result === 'pass'
                ? 'Completed successfully with expected response'
                : 'Unexpected HTTP status code returned'
        };
    }

    function formatTimestamp(date) {
        return date.getFullYear() + '-' +
            String(date.getMonth() + 1).padStart(2, '0') + '-' +
            String(date.getDate()).padStart(2, '0') + ' ' +
            String(date.getHours()).padStart(2, '0') + ':' +
            String(date.getMinutes()).padStart(2, '0') + ':' +
            String(date.getSeconds()).padStart(2, '0');
    }

    /* ─── Rendering ─── */
    function renderAll() {
        renderStats();
        renderSuites();
        renderHistoryTable();
        updateCounts();
    }

    function renderStats() {
        var totalSuites = STATE.suites.length;
        var totalCases = STATE.suites.reduce(function (sum, s) { return sum + s.cases.length; }, 0);
        var totalHistory = STATE.history.length;
        var passed = STATE.history.filter(function (h) { return h.result === 'pass'; }).length;
        var failed = STATE.history.filter(function (h) { return h.result === 'fail'; }).length;
        var passRate = totalHistory > 0 ? Math.round((passed / totalHistory) * 100) : 0;
        var totalDuration = STATE.history.reduce(function (sum, h) { return sum + (h.duration || 0); }, 0);
        var avgDuration = totalHistory > 0 ? Math.round(totalDuration / totalHistory) : 0;

        setText('tsTotalSuites', totalSuites);
        setText('tsSuitesSub', totalSuites + ' active collection' + (totalSuites !== 1 ? 's' : ''));
        setText('tsTotalCases', totalCases);
        setText('tsCasesSub', totalCases + ' case' + (totalCases !== 1 ? 's' : '') + ' across all suites');
        setText('tsPassRate', passRate + '%');
        setText('tsPassSub', passed + ' passed, ' + failed + ' failed');
        setText('tsAvgDuration', avgDuration + ' ms');
        setText('tsDurationSub', 'Across ' + totalHistory + ' test run' + (totalHistory !== 1 ? 's' : ''));
        setText('tsTotalFailures', failed);
        setText('tsFailuresSub', failed + ' failure' + (failed !== 1 ? 's' : '') + ' in history');
    }

    function renderSuites() {
        var container = document.getElementById('tsSuitesContainer');
        var empty = document.getElementById('tsSuitesEmpty');
        if (!container) return;

        var filteredSuites = getFilteredSuites();

        if (!filteredSuites.length) {
            container.innerHTML = '<div class="text-center text-muted py-4"><i class="fa-solid fa-flask fa-2x mb-2 d-block"></i>' +
                (STATE.suites.length ? 'No suites match the current filter criteria.' : 'No test suites yet. Click <strong>"New Suite"</strong> to create one.') +
                '</div>';
            return;
        }

        container.innerHTML = filteredSuites.map(function (suite) {
            var caseRows = suite.cases.map(function (tc) {
                var statusBadge = tc.status === 'pass' ? '<span class="ts-history-pass"><i class="fa-solid fa-circle-check me-1"></i>Pass</span>'
                    : tc.status === 'fail' ? '<span class="ts-history-fail"><i class="fa-solid fa-circle-xmark me-1"></i>Fail</span>'
                        : '<span class="ts-history-pending"><i class="fa-solid fa-clock me-1"></i>Pending</span>';
                var apiPill = '<span class="ts-case-api-pill ' + tc.apiType + '">' + tc.apiType.toUpperCase() + '</span>';
                var fileInfo = tc.fileName ? '<span class="ts-case-file">' + escapeHtml(tc.fileName) + '</span>' : '';
                var durationInfo = tc.lastDuration ? tc.lastDuration + ' ms' : '--';

                return '<div class="ts-case-row">' +
                    '<div class="ts-case-info">' +
                    apiPill +
                    '<div>' +
                    '<div class="ts-case-name">' + escapeHtml(tc.name) + '</div>' +
                    '<div class="d-flex align-items-center gap-2">' + fileInfo + '<span class="ts-case-file">' + escapeHtml(tc.application) + '</span></div>' +
                    '</div>' +
                    '</div>' +
                    '<div class="d-flex align-items-center gap-3 flex-shrink-0">' +
                    '<span class="fs-7 text-muted">' + durationInfo + '</span>' +
                    '<div class="ts-case-status">' + statusBadge + '</div>' +
                    '<button class="btn btn-sm btn-outline-primary" onclick="window.TS_MODULE.runCase(\'' + suite.id + '\',\'' + tc.id + '\')" title="Run Case"><i class="fa-solid fa-play"></i></button>' +
                    '</div>' +
                    '</div>';
            }).join('');

            var casesCount = suite.cases.length;
            var passedCount = suite.cases.filter(function (c) { return c.status === 'pass'; }).length;
            var failedCount = suite.cases.filter(function (c) { return c.status === 'fail'; }).length;

            return '<div class="ts-suite-card">' +
                '<div class="ts-suite-header" onclick="window.TS_MODULE.toggleSuite(\'' + suite.id + '\')">' +
                '<div class="ts-suite-header-left">' +
                '<button class="ts-suite-expand-btn" id="ts-expand-' + suite.id + '" aria-label="Expand suite"><i class="fa-solid fa-chevron-right"></i></button>' +
                '<div>' +
                '<div class="ts-suite-name">' + escapeHtml(suite.name) + '</div>' +
                '<div class="fs-7 text-muted">' + escapeHtml(suite.description || '') + '</div>' +
                '</div>' +
                '</div>' +
                '<div class="ts-suite-meta">' +
                '<span class="badge bg-light text-dark border"><span class="ts-case-api-pill ' + suite.apiType + '" style="font-size:0.6rem;">' + suite.apiType.toUpperCase() + '</span></span>' +
                '<span><i class="fa-solid fa-vial me-1"></i>' + casesCount + ' cases</span>' +
                (passedCount > 0 ? '<span class="ts-history-pass"><i class="fa-solid fa-circle-check"></i> ' + passedCount + '</span>' : '') +
                (failedCount > 0 ? '<span class="ts-history-fail"><i class="fa-solid fa-circle-xmark"></i> ' + failedCount + '</span>' : '') +
                '</div>' +
                '<div class="ts-suite-actions">' +
                '<button class="btn btn-sm btn-outline-success" onclick="event.stopPropagation();window.TS_MODULE.runSuite(\'' + suite.id + '\')" title="Run All"><i class="fa-solid fa-play"></i></button>' +
                '<button class="btn btn-sm btn-outline-secondary" onclick="event.stopPropagation();window.TS_MODULE.editSuite(\'' + suite.id + '\')" title="Edit"><i class="fa-solid fa-pen"></i></button>' +
                '<button class="btn btn-sm btn-outline-danger" onclick="event.stopPropagation();window.TS_MODULE.deleteSuite(\'' + suite.id + '\')" title="Delete"><i class="fa-solid fa-trash-can"></i></button>' +
                '</div>' +
                '</div>' +
                '<div class="ts-suite-body" id="ts-body-' + suite.id + '">' +
                caseRows +
                '</div>' +
                '</div>';
        }).join('');
    }

    function getFilteredSuites() {
        var nameQuery = (document.getElementById('tsFilterName')?.value || '').trim().toLowerCase();
        var apiType = document.getElementById('tsFilterApiType')?.value || 'all';
        var status = document.getElementById('tsFilterStatus')?.value || 'all';

        return STATE.suites.filter(function (suite) {
            if (nameQuery && !suite.name.toLowerCase().includes(nameQuery) &&
                !suite.cases.some(function (c) { return c.name.toLowerCase().includes(nameQuery); })) {
                return false;
            }
            if (apiType !== 'all' && suite.apiType !== apiType) return false;
            if (status !== 'all') {
                var hasMatch = suite.cases.some(function (c) { return c.status === status; });
                if (!hasMatch) return false;
            }
            return true;
        });
    }

    /* ─── Suite Toggle ─── */
    function toggleSuite(suiteId) {
        var body = document.getElementById('ts-body-' + suiteId);
        var btn = document.getElementById('ts-expand-' + suiteId);
        if (!body || !btn) return;
        body.classList.toggle('expanded');
        btn.classList.toggle('expanded');
    }

    /* ─── History Table ─── */
    function renderHistoryTable() {
        var tbody = document.getElementById('tsHistoryTbody');
        if (!tbody) return;

        var filtered = getFilteredHistory();

        if (!filtered.length) {
            tbody.innerHTML = '<tr><td colspan="8" class="text-center text-muted py-3">No execution history yet.</td></tr>';
            return;
        }

        tbody.innerHTML = filtered.map(function (entry) {
            var resultBadge = entry.result === 'pass'
                ? '<span class="badge badge-status-healthy"><i class="fa-solid fa-circle-check me-1"></i>Pass</span>'
                : entry.result === 'fail'
                    ? '<span class="badge badge-status-danger"><i class="fa-solid fa-circle-xmark me-1"></i>Fail</span>'
                    : '<span class="badge badge-status-pending"><i class="fa-solid fa-clock me-1"></i>Pending</span>';

            var apiPill = '<span class="ts-case-api-pill ' + entry.apiType + '" style="font-size:0.65rem;">' + entry.apiType.toUpperCase() + '</span>';

            return '<tr>' +
                '<td class="text-nowrap fs-7">' + escapeHtml(entry.timestamp) + '</td>' +
                '<td class="fw-semibold fs-7">' + escapeHtml(entry.suiteName) + '</td>' +
                '<td class="fs-7">' + escapeHtml(entry.caseName) + '</td>' +
                '<td>' + apiPill + '</td>' +
                '<td class="fs-7">' + escapeHtml(entry.application || '--') + '</td>' +
                '<td class="text-center">' + resultBadge + '</td>' +
                '<td class="text-center fs-7">' + (entry.duration || '--') + ' ms</td>' +
                '<td class="text-center">' +
                '<button class="btn btn-sm btn-outline-info" onclick="window.TS_MODULE.viewHistory(\'' + entry.id + '\')"><i class="fa-solid fa-eye"></i></button>' +
                '</td>' +
                '</tr>';
        }).join('');
    }

    function getFilteredHistory() {
        var nameQuery = (document.getElementById('tsFilterName')?.value || '').trim().toLowerCase();
        var apiType = document.getElementById('tsFilterApiType')?.value || 'all';
        var status = document.getElementById('tsFilterStatus')?.value || 'all';

        return STATE.history.filter(function (entry) {
            if (nameQuery && !entry.caseName.toLowerCase().includes(nameQuery) &&
                !entry.suiteName.toLowerCase().includes(nameQuery)) {
                return false;
            }
            if (apiType !== 'all' && entry.apiType !== apiType) return false;
            if (status !== 'all' && entry.result !== status) return false;
            return true;
        });
    }

    /* ─── Pagination ─── */
    function registerPagination() {
        var pageSizeSelect = document.getElementById('tsHistoryPageSize');
        var pagination = document.getElementById('tsHistoryPagination');
        var summary = document.getElementById('tsHistoryPaginationSummary');
        if (!pageSizeSelect || !pagination || !summary) return;

        STATE.paginationState = { currentPage: 1 };

        pageSizeSelect.addEventListener('change', function () {
            STATE.paginationState.currentPage = 1;
            applyPagination();
        });

        pagination.querySelectorAll('a[data-page]').forEach(function (anchor) {
            anchor.addEventListener('click', function (event) {
                event.preventDefault();
                var pageAttr = anchor.getAttribute('data-page');
                if (pageAttr === 'prev') STATE.paginationState.currentPage -= 1;
                else if (pageAttr === 'next') STATE.paginationState.currentPage += 1;
                else STATE.paginationState.currentPage = Number(pageAttr) || 1;
                applyPagination();
            });
        });

        applyPagination();
    }

    function applyPagination() {
        var pageSizeSelect = document.getElementById('tsHistoryPageSize');
        var pagination = document.getElementById('tsHistoryPagination');
        var summary = document.getElementById('tsHistoryPaginationSummary');
        var tbody = document.getElementById('tsHistoryTbody');
        if (!pageSizeSelect || !pagination || !summary || !tbody) return;

        var pageSize = Math.max(1, Number(pageSizeSelect.value) || 10);
        var allRows = Array.from(tbody.children);
        var total = allRows.length;
        var totalPages = Math.max(1, Math.ceil(total / pageSize));
        var state = STATE.paginationState || { currentPage: 1 };

        if (state.currentPage < 1) state.currentPage = 1;
        if (state.currentPage > totalPages) state.currentPage = totalPages;

        allRows.forEach(function (row, index) {
            row.classList.toggle('page-hidden', index < (state.currentPage - 1) * pageSize || index >= state.currentPage * pageSize);
        });

        pagination.querySelectorAll('a[data-page]').forEach(function (anchor) {
            var pageAttr = anchor.getAttribute('data-page');
            var item = anchor.closest('.page-item');
            if (!item) return;

            if (pageAttr === 'prev') {
                item.classList.toggle('disabled', state.currentPage === 1);
                item.classList.remove('active');
                return;
            }
            if (pageAttr === 'next') {
                item.classList.toggle('disabled', state.currentPage >= totalPages);
                item.classList.remove('active');
                return;
            }
            var page = Number(pageAttr);
            var shouldHide = Number.isFinite(page) && page > totalPages;
            item.classList.toggle('d-none', shouldHide);
            item.classList.toggle('active', page === state.currentPage && !shouldHide);
            item.classList.remove('disabled');
        });

        var from = total === 0 ? 0 : (state.currentPage - 1) * pageSize + 1;
        var to = Math.min(state.currentPage * pageSize, total);
        summary.innerHTML = 'Showing <strong>' + from + ' to ' + to + '</strong> of <strong>' + total + '</strong> records';
    }

    /* ─── Filters ─── */
    function setupFilters() {
        var applyBtn = document.getElementById('tsFilterApplyBtn');
        var resetBtn = document.getElementById('tsFilterResetBtn');

        if (applyBtn) {
            applyBtn.addEventListener('click', function () {
                renderSuites();
                renderHistoryTable();
                applyPagination();
                if (!document.getElementById('tsHistoryGraphView')?.classList.contains('d-none')) {
                    buildHistoryGraph();
                }
            });
        }
        if (resetBtn) {
            resetBtn.addEventListener('click', function () {
                var nameInput = document.getElementById('tsFilterName');
                var apiSelect = document.getElementById('tsFilterApiType');
                var statusSelect = document.getElementById('tsFilterStatus');
                if (nameInput) nameInput.value = '';
                if (apiSelect) apiSelect.value = 'all';
                if (statusSelect) statusSelect.value = 'all';
                renderSuites();
                renderHistoryTable();
                applyPagination();
                if (!document.getElementById('tsHistoryGraphView')?.classList.contains('d-none')) {
                    buildHistoryGraph();
                }
            });
        }
    }

    /* ─── View Toggles ─── */
    function setupViewToggles() {
        document.getElementById('tsHistoryListViewBtn')?.addEventListener('click', function () {
            setHistoryView('list', true);
        });
        document.getElementById('tsHistoryGraphViewBtn')?.addEventListener('click', function () {
            setHistoryView('graph', true);
        });
    }

    function setHistoryView(view, persist) {
        var isGraph = view === 'graph';
        var listView = document.getElementById('tsHistoryListView');
        var graphView = document.getElementById('tsHistoryGraphView');
        var listBtn = document.getElementById('tsHistoryListViewBtn');
        var graphBtn = document.getElementById('tsHistoryGraphViewBtn');
        if (!listView || !graphView || !listBtn || !graphBtn) return;

        listView.classList.toggle('d-none', isGraph);
        graphView.classList.toggle('d-none', !isGraph);
        listBtn.classList.toggle('active', !isGraph);
        graphBtn.classList.toggle('active', isGraph);
        listBtn.setAttribute('aria-pressed', String(!isGraph));
        graphBtn.setAttribute('aria-pressed', String(isGraph));

        if (isGraph) buildHistoryGraph();
        if (persist) AppStorage.set(STATE.VIEW_KEY, view);
    }

    function setupMetricToggles() {
        document.querySelectorAll('#tsHistoryGraphView .ts-metric-toggle [data-metric]').forEach(function (button) {
            button.addEventListener('click', function () {
                var metric = button.getAttribute('data-metric') || 'passfail';
                setGraphMetric(metric, true);
            });
        });
    }

    function setGraphMetric(metric, persist) {
        var allowed = new Set(['passfail', 'type', 'suite']);
        var normalized = allowed.has(metric) ? metric : 'passfail';

        document.querySelectorAll('#tsHistoryGraphView .ts-metric-toggle [data-metric]').forEach(function (button) {
            var isActive = button.getAttribute('data-metric') === normalized;
            button.classList.toggle('active', isActive);
            button.setAttribute('aria-pressed', String(isActive));
        });

        if (persist) AppStorage.set(STATE.METRIC_KEY, normalized);
        buildHistoryGraph();
    }

    function restoreSavedViews() {
        var savedView = AppStorage.get(STATE.VIEW_KEY, APP.DEFAULTS.TS_HISTORY_VIEW);
        setHistoryView(savedView, false);
        var savedMetric = AppStorage.get(STATE.METRIC_KEY, APP.DEFAULTS.TS_GRAPH_METRIC);
        setGraphMetric(savedMetric, false);
    }

    /* ─── History Graph ─── */
    function buildHistoryGraph() {
        var rowsContainer = document.getElementById('tsHistoryGraphRows');
        var pieCenter = document.getElementById('tsHistoryPieCenter');
        var chartCanvas = document.getElementById('tsHistoryChartCanvas');
        var durationCanvas = document.getElementById('tsDurationChartCanvas');
        if (!rowsContainer || !pieCenter || !chartCanvas || !durationCanvas) return;

        // Destroy existing charts
        if (STATE.historyChart) { STATE.historyChart.destroy(); STATE.historyChart = null; }
        if (STATE.durationChart) { STATE.durationChart.destroy(); STATE.durationChart = null; }

        var filtered = getFilteredHistory();
        var metric = document.querySelector('#tsHistoryGraphView .ts-metric-toggle .active')?.getAttribute('data-metric') || 'passfail';
        var isDarkMode = document.documentElement.getAttribute('data-bs-theme') === 'dark';
        var paletteColors = isDarkMode
            ? ['#4ade80', '#f87171', '#94a3b8', '#60a5fa', '#fbbf24', '#a78bfa', '#f472b6', '#34d399']
            : ['#16a34a', '#dc2626', '#64748b', '#2563eb', '#d97706', '#7c3aed', '#db2777', '#059669'];

        if (!filtered.length) {
            rowsContainer.innerHTML = '<div class="small text-muted">No history data to display.</div>';
            chartCanvas.style.visibility = 'hidden';
            durationCanvas.style.visibility = 'hidden';
            pieCenter.textContent = 'No Data';
            return;
        }

        chartCanvas.style.visibility = 'visible';
        durationCanvas.style.visibility = 'visible';

        var slices = [];
        var metricLabel = '';

        if (metric === 'passfail') {
            metricLabel = 'Pass / Fail';
            var passCount = filtered.filter(function (h) { return h.result === 'pass'; }).length;
            var failCount = filtered.filter(function (h) { return h.result === 'fail'; }).length;
            slices = [
                { label: 'Pass', value: passCount, color: paletteColors[0] },
                { label: 'Fail', value: failCount, color: paletteColors[1] }
            ].filter(function (s) { return s.value > 0; });
        } else if (metric === 'type') {
            metricLabel = 'By API Type';
            var soapCount = filtered.filter(function (h) { return h.apiType === 'soap'; }).length;
            var restCount = filtered.filter(function (h) { return h.apiType === 'rest'; }).length;
            slices = [
                { label: 'SOAP', value: soapCount, color: paletteColors[3] },
                { label: 'REST', value: restCount, color: paletteColors[0] }
            ].filter(function (s) { return s.value > 0; });
        } else {
            metricLabel = 'By Suite';
            var suiteMap = {};
            filtered.forEach(function (h) {
                suiteMap[h.suiteName] = (suiteMap[h.suiteName] || 0) + 1;
            });
            var colorIdx = 0;
            slices = Object.keys(suiteMap).map(function (name) {
                return {
                    label: name,
                    value: suiteMap[name],
                    color: paletteColors[colorIdx++ % paletteColors.length]
                };
            });
        }

        var totalValue = slices.reduce(function (sum, s) { return sum + s.value; }, 0);
        if (totalValue <= 0) {
            rowsContainer.innerHTML = '<div class="small text-muted">No measurable values.</div>';
            chartCanvas.style.visibility = 'hidden';
            pieCenter.textContent = metricLabel;
            return;
        }

        var rootStyle = getComputedStyle(document.documentElement);
        var chartBorderColor = rootStyle.getPropertyValue('--ux-bg-primary').trim() || '#ffffff';

        STATE.historyChart = new Chart(chartCanvas, {
            type: 'doughnut',
            data: {
                labels: slices.map(function (s) { return s.label; }),
                datasets: [{
                    data: slices.map(function (s) { return s.value; }),
                    backgroundColor: slices.map(function (s) { return s.color; }),
                    borderColor: chartBorderColor,
                    borderWidth: 2,
                    hoverOffset: 8
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                cutout: '62%',
                animation: { animateRotate: true, animateScale: true },
                plugins: {
                    legend: { display: false },
                    tooltip: {
                        callbacks: {
                            label: function (context) {
                                var label = context.label || '';
                                var val = context.parsed || 0;
                                var pct = totalValue > 0 ? ((val / totalValue) * 100).toFixed(1) : 0;
                                return label + ': ' + val + ' (' + pct + '%)';
                            }
                        }
                    }
                }
            }
        });

        pieCenter.textContent = metricLabel;

        // Build legend
        rowsContainer.innerHTML = slices.map(function (s) {
            var pct = totalValue > 0 ? ((s.value / totalValue) * 100).toFixed(1) : 0;
            return '<div class="ts-legend-row">' +
                '<span class="ts-legend-dot" style="background:' + s.color + ';"></span>' +
                '<span class="ts-legend-label">' + escapeHtml(s.label) + '</span>' +
                '<span class="ts-legend-value">' + s.value + ' (' + pct + '%)</span>' +
                '</div>';
        }).join('');

        // Build duration trend bar chart
        var recentHistory = filtered.slice().sort(function (a, b) {
            return a.timestamp.localeCompare(b.timestamp);
        }).slice(-20);

        STATE.durationChart = new Chart(durationCanvas, {
            type: 'bar',
            data: {
                labels: recentHistory.map(function (h) { return h.caseName.substring(0, 18); }),
                datasets: [{
                    label: 'Duration (ms)',
                    data: recentHistory.map(function (h) { return h.duration || 0; }),
                    backgroundColor: recentHistory.map(function (h) {
                        return h.result === 'pass' ? paletteColors[0] : paletteColors[1];
                    }),
                    borderColor: chartBorderColor,
                    borderWidth: 1,
                    borderRadius: 3
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                plugins: {
                    legend: { display: false },
                    tooltip: {
                        callbacks: {
                            afterLabel: function (context) {
                                var entry = recentHistory[context.dataIndex];
                                return 'Status: ' + (entry.result === 'pass' ? 'Pass' : 'Fail') +
                                    '\nSuite: ' + entry.suiteName;
                            }
                        }
                    }
                },
                scales: {
                    x: {
                        display: true,
                        ticks: { font: { size: 9 }, maxRotation: 45 },
                        grid: { display: false }
                    },
                    y: {
                        beginAtZero: true,
                        ticks: { font: { size: 9 } },
                        grid: { color: isDarkMode ? 'rgba(255,255,255,0.06)' : 'rgba(0,0,0,0.06)' }
                    }
                }
            }
        });
    }

    /* ─── Suite CRUD ─── */
    function addSuite() {
        var name = prompt('Enter suite name:');
        if (!name) return;
        var app = prompt('Application name (e.g. Payment Gateway Service):');
        if (!app) return;
        var apiType = prompt('API type (soap or rest):', 'soap');
        if (!apiType || (apiType !== 'soap' && apiType !== 'rest')) {
            showActionToast('API type must be "soap" or "rest".', 'warning');
            return;
        }
        var desc = prompt('Description (optional):') || '';
        STATE.suites.push({
            id: 'suite-' + (STATE.suiteIdCounter++),
            name: name,
            app: app,
            apiType: apiType,
            description: desc,
            cases: []
        });
        renderAll();
        showActionToast('Suite "' + name + '" created.', 'success');
    }

    function editSuite(suiteId) {
        var suite = STATE.suites.find(function (s) { return s.id === suiteId; });
        if (!suite) return;
        var name = prompt('Suite name:', suite.name);
        if (!name) return;
        suite.name = name;
        suite.description = prompt('Description:', suite.description) || suite.description;
        renderAll();
        showActionToast('Suite updated.', 'success');
    }

    function deleteSuite(suiteId) {
        var suite = STATE.suites.find(function (s) { return s.id === suiteId; });
        if (!suite) return;
        if (!confirm('Delete suite "' + suite.name + '" and all its test cases?')) return;
        STATE.suites = STATE.suites.filter(function (s) { return s.id !== suiteId; });
        renderAll();
        showActionToast('Suite deleted.', 'secondary');
    }

    /* ─── Run Suite / Case ─── */
    function runSuite(suiteId) {
        var suite = STATE.suites.find(function (s) { return s.id === suiteId; });
        if (!suite) return;
        if (!suite.cases.length) {
            showActionToast('Suite "' + suite.name + '" has no test cases.', 'warning');
            return;
        }
        showActionToast('Running suite "' + suite.name + '" (' + suite.cases.length + ' cases)...', 'info');

        var completed = 0;
        suite.cases.forEach(function (tc) {
            var delay = 300 + Math.round(Math.random() * 700);
            setTimeout(function () {
                var passed = Math.random() > 0.25;
                var duration = 50 + Math.round(Math.random() * 350);
                tc.status = passed ? 'pass' : 'fail';
                tc.lastRun = formatTimestamp(new Date());
                tc.lastDuration = duration;

                STATE.history.unshift({
                    id: 'hist-' + (STATE.historyIdCounter++),
                    timestamp: tc.lastRun,
                    suiteId: suite.id,
                    suiteName: suite.name,
                    caseId: tc.id,
                    caseName: tc.name,
                    fileName: tc.fileName,
                    application: tc.application,
                    apiType: tc.apiType,
                    action: tc.action,
                    result: tc.status,
                    duration: duration,
                    error: passed ? null : 'Assertion failed: Expected status 200, got ' + (400 + Math.round(Math.random() * 100)),
                    responseSummary: passed ? 'Completed successfully' : 'Unexpected response'
                });

                completed++;
                if (completed === suite.cases.length) {
                    renderAll();
                    var passedCount = suite.cases.filter(function (c) { return c.status === 'pass'; }).length;
                    showActionToast('Suite "' + suite.name + '" completed: ' + passedCount + '/' + suite.cases.length + ' passed.', passedCount === suite.cases.length ? 'success' : 'warning');
                    if (!document.getElementById('tsHistoryGraphView')?.classList.contains('d-none')) {
                        buildHistoryGraph();
                    }
                }
            }, delay);
        });
    }

    function runCase(suiteId, caseId) {
        var suite = STATE.suites.find(function (s) { return s.id === suiteId; });
        if (!suite) return;
        var tc = suite.cases.find(function (c) { return c.id === caseId; });
        if (!tc) return;

        showActionToast('Running test case "' + tc.name + '"...', 'info');

        setTimeout(function () {
            var passed = Math.random() > 0.2;
            var duration = 30 + Math.round(Math.random() * 300);
            tc.status = passed ? 'pass' : 'fail';
            tc.lastRun = formatTimestamp(new Date());
            tc.lastDuration = duration;

            STATE.history.unshift({
                id: 'hist-' + (STATE.historyIdCounter++),
                timestamp: tc.lastRun,
                suiteId: suite.id,
                suiteName: suite.name,
                caseId: tc.id,
                caseName: tc.name,
                fileName: tc.fileName,
                application: tc.application,
                apiType: tc.apiType,
                action: tc.action,
                result: tc.status,
                duration: duration,
                error: passed ? null : 'Assertion failed: Expected status 200, got ' + (400 + Math.round(Math.random() * 100)),
                responseSummary: passed ? 'Completed successfully' : 'Unexpected HTTP response'
            });

            renderAll();
            showActionToast('Case "' + tc.name + '" ' + (passed ? 'passed' : 'failed') + ' (' + duration + ' ms).', passed ? 'success' : 'error');
            if (!document.getElementById('tsHistoryGraphView')?.classList.contains('d-none')) {
                buildHistoryGraph();
            }
        }, 500 + Math.round(Math.random() * 500));
    }

    /* ─── History Detail ─── */
    function viewHistory(histId) {
        var entry = STATE.history.find(function (h) { return h.id === histId; });
        if (!entry) return;

        var modal = document.getElementById('tsCaseDetailModal');
        var body = document.getElementById('tsCaseDetailBody');
        if (!modal || !body) return;

        var resultIcon = entry.result === 'pass'
            ? '<i class="fa-solid fa-circle-check text-success fa-lg"></i>'
            : '<i class="fa-solid fa-circle-xmark text-danger fa-lg"></i>';

        body.innerHTML = '<div class="row g-3 mb-3">' +
            '<div class="col-md-6">' +
            '<div class="mb-2"><strong>Timestamp:</strong><br><span class="fs-7">' + escapeHtml(entry.timestamp) + '</span></div>' +
            '<div class="mb-2"><strong>Suite:</strong><br><span class="fs-7">' + escapeHtml(entry.suiteName) + '</span></div>' +
            '<div class="mb-2"><strong>Test Case:</strong><br><span class="fs-7 fw-semibold">' + escapeHtml(entry.caseName) + '</span></div>' +
            '</div>' +
            '<div class="col-md-6">' +
            '<div class="mb-2"><strong>Result:</strong><br>' + resultIcon + ' <span class="fs-7 fw-semibold">' + (entry.result === 'pass' ? 'Passed' : 'Failed') + '</span></div>' +
            '<div class="mb-2"><strong>Duration:</strong><br><span class="fs-7">' + (entry.duration || '--') + ' ms</span></div>' +
            '<div class="mb-2"><strong>API Type:</strong><br><span class="ts-case-api-pill ' + entry.apiType + '">' + entry.apiType.toUpperCase() + '</span></div>' +
            '</div>' +
            '<div class="col-12">' +
            '<div class="mb-2"><strong>Application:</strong><br><span class="fs-7">' + escapeHtml(entry.application || '--') + '</span></div>' +
            (entry.fileName ? '<div class="mb-2"><strong>Request File:</strong><br><span class="fs-7">' + escapeHtml(entry.fileName) + '</span></div>' : '') +
            '</div>' +
            '<div class="col-12">' +
            '<h6 class="fw-bold mt-2">Response Summary</h6>' +
            '<div class="border rounded p-3 font-monospace" style="font-size:0.82rem;background:var(--ux-bg-secondary);">' +
            escapeHtml(entry.responseSummary || 'No response data') +
            '</div>' +
            '</div>' +
            (entry.error ? '<div class="col-12">' +
                '<h6 class="fw-bold mt-1 text-danger">Error Details</h6>' +
                '<div class="border rounded p-3 font-monospace text-danger" style="font-size:0.82rem;background:var(--ux-bg-secondary);">' +
                escapeHtml(entry.error) +
                '</div>' +
                '</div>' : '') +
            '</div>';

        var bsModal = bootstrap.Modal.getInstance(modal);
        if (!bsModal) {
            bsModal = new bootstrap.Modal(modal);
        }
        bsModal.show();
    }

    /* ─── Clear History ─── */
    function clearHistory() {
        if (!confirm('Clear all execution history records?')) return;
        STATE.history = [];
        STATE.suites.forEach(function (s) {
            s.cases.forEach(function (c) {
                c.status = 'pending';
                c.lastRun = null;
                c.lastDuration = null;
            });
        });
        renderAll();
        if (!document.getElementById('tsHistoryGraphView')?.classList.contains('d-none')) {
            buildHistoryGraph();
        }
        showActionToast('History cleared.', 'secondary');
    }

    /* ─── Utility ─── */
    function setText(id, value) {
        var el = document.getElementById(id);
        if (el) el.textContent = String(value);
    }

    function escapeHtml(value) {
        return String(value ?? '')
            .replace(/&/g, '&amp;').replace(/</g, '&lt;')
            .replace(/>/g, '&gt;').replace(/"/g, '&quot;')
            .replace(/'/g, '&#39;');
    }

    function updateCounts() {
        var countEl = document.getElementById('tsHistoryCount');
        if (countEl) countEl.textContent = STATE.history.length + ' records';
    }

    /* ─── Public API ─── */
    window.TS_MODULE = {
        init: init,
        addSuite: addSuite,
        editSuite: editSuite,
        deleteSuite: deleteSuite,
        runSuite: runSuite,
        runCase: runCase,
        toggleSuite: toggleSuite,
        viewHistory: viewHistory,
        clearHistory: clearHistory
    };

    /* ─── Auto-init ─── */
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', init);
    } else {
        init();
    }

})();
