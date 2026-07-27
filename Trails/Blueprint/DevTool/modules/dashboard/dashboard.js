/**
 * DevBizToolsSuite - Dashboard Module
 * Handles application performance table, chart views, service utilization,
 * filter panel, pagination, and quick actions.
 */
(function () {
    'use strict';

    /* ─── Module State ─── */
    const STATE = {
        appPerformanceChart: null,
        serviceUtilizationChart: null,
        tableSortState: new Map(),
        paginationRegistry: new Map(),
        APP_PERFORMANCE_VIEW_KEY: APP.STORAGE_KEYS.DASHBOARD_APP_PERF_VIEW,
        APP_PERFORMANCE_METRIC_KEY: APP.STORAGE_KEYS.DASHBOARD_APP_PERF_METRIC,
        SERVICE_UTIL_VIEW_KEY: APP.STORAGE_KEYS.DASHBOARD_SERVICE_UTIL_VIEW
    };

    /* ─── Initialization ─── */
    function init() {
        if (!document.getElementById('appPerformanceTable')) {
            // Module HTML not loaded yet — retry
            setTimeout(init, 50);
            return;
        }

        populateDataDrivenSections();
        setupDashboardFilters();
        setupViewToggles();
        setupMetricToggles();
        setupQuickActions();
        registerPagination();
        restoreSavedViews();
        initializeTooltips();
        bindTableActions();
    }

    /* ─── Data Population ─── */
    function populateDataDrivenSections() {
        const dataStore = window.DATA || {};

        const escapeHtml = value => String(value ?? '')
            .replace(/&/g, '&amp;').replace(/</g, '&lt;')
            .replace(/>/g, '&gt;').replace(/"/g, '&quot;')
            .replace(/'/g, '&#39;');

        const formatNumber = value => {
            const numeric = Number(value);
            return Number.isFinite(numeric) ? Math.round(numeric).toLocaleString() : '0';
        };

        const normalizeArray = value => Array.isArray(value) ? value : [];
        const appStats = normalizeArray(dataStore.appPerformance);

        if (appStats.length) {
            const tbody = document.querySelector('#appPerformanceTable tbody');
            if (tbody) {
                const statusBadgeClass = statusText => {
                    const s = String(statusText || '').toLowerCase();
                    if (s.includes('healthy') || s.includes('active') || s.includes('connected')) return 'badge-status-healthy';
                    if (s.includes('watch') || s.includes('check')) return 'badge-status-warning';
                    if (s.includes('risk') || s.includes('fail') || s.includes('error') || s.includes('disconnected')) return 'badge-status-danger';
                    return 'badge-status-pending';
                };

                tbody.innerHTML = appStats.map(item => {
                    const appName = item.applicationName || item.app || item.name || 'Unknown Application';
                    const apiRaw = String(item.apiType || item.api || 'REST').toLowerCase();
                    const apiType = apiRaw === 'soap' ? 'soap' : 'rest';
                    const calls = Number(item.totalApiCalls ?? item.calls ?? item.baseCalls ?? 0);
                    const successRate = Number(item.successRate ?? item.success ?? 0);
                    const responseTime = Number(item.avgResponseTime ?? item.responseTime ?? item.response ?? 0);
                    const status = item.status || 'Healthy';

                    return `
                        <tr data-base-calls="${Number.isFinite(calls) ? Math.max(0, Math.round(calls)) : 0}">
                            <td data-col="app" class="fw-semibold">${escapeHtml(appName)}</td>
                            <td data-col="api"><span class="api-pill ${apiType}">${apiType.toUpperCase()}</span></td>
                            <td data-col="calls">${formatNumber(calls)}</td>
                            <td data-col="success">${Number.isFinite(successRate) ? successRate.toFixed(1) : '0.0'}%</td>
                            <td data-col="response">${Number.isFinite(responseTime) ? Math.round(responseTime) : 0} ms</td>
                            <td data-col="status"><span class="badge ${statusBadgeClass(status)}">${escapeHtml(status)}</span></td>
                        </tr>
                    `;
                }).join('');
            }
        }

        refreshDashboardChips();
        buildAppPerformanceGraph();
        if (!document.getElementById('serviceUtilGraphView')?.classList.contains('d-none')) {
            buildServiceUtilizationGraph();
        }
    }

    function refreshDashboardChips() {
        const visibleRows = Array.from(document.querySelectorAll('#appPerformanceTable tbody tr'))
            .filter(row => !row.classList.contains('filter-hidden'));
        const trackedValue = document.getElementById('dashboardTrackedAppsValue');
        const trafficValue = document.getElementById('dashboardTrafficMixValue');

        if (trackedValue) {
            trackedValue.textContent = `${visibleRows.length} (SOAP + REST)`;
        }

        if (trafficValue) {
            let soapCalls = 0, restCalls = 0;
            visibleRows.forEach(row => {
                const api = (row.querySelector('[data-col="api"]')?.textContent || '').trim().toLowerCase();
                const calls = Number.parseInt((row.querySelector('[data-col="calls"]')?.textContent || '0').replace(/[^\d]/g, ''), 10) || 0;
                if (api === 'soap') soapCalls += calls;
                else if (api === 'rest') restCalls += calls;
            });
            const total = soapCalls + restCalls;
            const soapPct = total ? Math.round((soapCalls / total) * 100) : 0;
            const restPct = total ? Math.round((restCalls / total) * 100) : 0;
            trafficValue.textContent = `SOAP ${soapPct}% | REST ${restPct}%`;
        }
    }

    /* ─── Dashboard Filters ─── */
    function setupDashboardFilters() {
        const appNameInput = document.getElementById('dashboardAppNameFilter');
        const apiTypeSelect = document.getElementById('dashboardApiTypeFilter');
        const callWindowSelect = document.getElementById('dashboardCallWindowFilter');
        const successMinInput = document.getElementById('dashboardSuccessRateFilter');
        const responseMaxInput = document.getElementById('dashboardResponseTimeFilter');
        const statusSelect = document.getElementById('dashboardStatusFilter');
        const applyBtn = document.getElementById('dashboardFilterApplyBtn');
        const resetBtn = document.getElementById('dashboardFilterResetBtn');

        const controls = [appNameInput, apiTypeSelect, callWindowSelect, successMinInput, responseMaxInput, statusSelect];
        if (controls.some(c => !c) || !applyBtn || !resetBtn) return;

        const parseNumber = v => Number.parseFloat(String(v ?? '').replace(/[^\d.]/g, '')) || 0;

        const callFactors = { '24h': 1, '7d': 7, '30d': 30 };
        const callLabels = { '24h': '24h', '7d': '1 Week', '30d': '1 Month' };

        const applyWindowToCalls = () => {
            const factor = callFactors[callWindowSelect.value] || 1;
            document.querySelectorAll('#appPerformanceTable tbody tr').forEach(row => {
                const baseCalls = Number.parseInt(row.getAttribute('data-base-calls') || '0', 10) || 0;
                const adjusted = Math.round(baseCalls * factor);
                const callsCell = row.querySelector('[data-col="calls"]');
                if (callsCell) callsCell.textContent = adjusted.toLocaleString();
            });
            const header = document.getElementById('appCallsHeader');
            if (header) header.textContent = `Total API Calls (${callLabels[callWindowSelect.value] || '24h'})`;
        };

        const applyCriteria = (showToast = false) => {
            applyWindowToCalls();

            const appQuery = appNameInput.value.trim().toLowerCase();
            const apiType = apiTypeSelect.value;
            const minSuccess = parseNumber(successMinInput.value);
            const maxResponse = parseNumber(responseMaxInput.value);
            const status = statusSelect.value;

            document.querySelectorAll('#appPerformanceTable tbody tr').forEach(row => {
                const app = row.querySelector('[data-col="app"]')?.textContent.trim().toLowerCase() || '';
                const rowApi = row.querySelector('[data-col="api"]')?.textContent.trim().toLowerCase() || '';
                const rowSuccess = parseNumber(row.querySelector('[data-col="success"]')?.textContent || '0');
                const rowResponse = parseNumber(row.querySelector('[data-col="response"]')?.textContent || '0');
                const rowStatus = row.querySelector('[data-col="status"]')?.textContent.trim().toLowerCase() || '';

                const matchApp = !appQuery || app.includes(appQuery);
                const matchApiType = apiType === 'all' || rowApi === apiType;
                const matchSuccess = !successMinInput.value || rowSuccess >= minSuccess;
                const matchResponse = !responseMaxInput.value || rowResponse <= maxResponse;
                const matchStatus = status === 'all' || rowStatus === status;

                row.classList.toggle('filter-hidden', !(matchApp && matchApiType && matchSuccess && matchResponse && matchStatus));
            });

            refreshDashboardChips();

            const pagState = STATE.paginationRegistry.get('#appPerformanceTable tbody');
            if (pagState) { pagState.currentPage = 1; applyPaginationState(pagState); }

            buildAppPerformanceGraph();

            if (showToast) showActionToast('Application criteria applied.', 'info');
        };

        applyBtn.addEventListener('click', () => applyCriteria(true));

        resetBtn.addEventListener('click', () => {
            appNameInput.value = '';
            apiTypeSelect.value = 'all';
            callWindowSelect.value = '24h';
            successMinInput.value = '';
            responseMaxInput.value = '';
            statusSelect.value = 'all';
            applyCriteria(false);
            showActionToast('Application criteria reset.', 'secondary');
        });

        callWindowSelect.addEventListener('change', () => applyCriteria(false));
        applyCriteria(false);
    }

    /* ─── View Toggles ─── */
    function setupViewToggles() {
        document.getElementById('appPerfListViewBtn')?.addEventListener('click', () => setAppPerformanceView('list', true));
        document.getElementById('appPerfGraphViewBtn')?.addEventListener('click', () => setAppPerformanceView('graph', true));
        document.getElementById('serviceUtilListViewBtn')?.addEventListener('click', () => setServiceUtilizationView('list', true));
        document.getElementById('serviceUtilGraphViewBtn')?.addEventListener('click', () => setServiceUtilizationView('graph', true));
    }

    function setupMetricToggles() {
        document.querySelectorAll('#appPerformanceMetricToggle [data-metric]').forEach(button => {
            button.addEventListener('click', () => {
                const metric = button.getAttribute('data-metric') || 'calls';
                setAppPerformanceMetric(metric, true);
            });
        });
    }

    /* ─── Quick Actions ─── */
    function setupQuickActions() {
        document.getElementById('quickRunHealthBtn')?.addEventListener('click', () => {
            ModuleLoader.navigate('health-checks');
            // The health module will auto-run after navigation
        });

        document.getElementById('quickExportSummaryBtn')?.addEventListener('click', exportDashboardSummary);
        document.getElementById('quickSyncSpecsBtn')?.addEventListener('click', () => {
            ModuleLoader.navigate('soap-api-test', 'wsdl');
            showActionToast('WSDL/Swagger sync queued for update.', 'info');
        });
        document.getElementById('quickReviewAccessBtn')?.addEventListener('click', () => {
            ModuleLoader.navigate('settings', 'access');
            showActionToast('Redirected to pending access review.', 'secondary');
        });
    }

    /* ─── Pagination ─── */
    function registerPagination() {
        const config = {
            tableBodySelector: '#appPerformanceTable tbody',
            pageSizeSelectId: 'appPerformancePageSize',
            paginationId: 'appPerformancePagination',
            summaryId: 'appPerformancePaginationSummary',
            itemLabel: 'applications'
        };

        const state = { ...config, currentPage: 1 };
        STATE.paginationRegistry.set(config.tableBodySelector, state);

        document.getElementById(config.pageSizeSelectId)?.addEventListener('change', () => {
            state.currentPage = 1;
            applyPaginationState(state);
        });

        document.getElementById(config.paginationId)?.querySelectorAll('a[data-page]').forEach(anchor => {
            anchor.addEventListener('click', event => {
                event.preventDefault();
                const pageAttr = anchor.getAttribute('data-page');
                if (pageAttr === 'prev') state.currentPage -= 1;
                else if (pageAttr === 'next') state.currentPage += 1;
                else state.currentPage = Number(pageAttr) || 1;
                applyPaginationState(state);
            });
        });

        applyPaginationState(state);
    }

    function applyPaginationState(state) {
        const body = document.querySelector(state.tableBodySelector);
        const pageSizeSelect = document.getElementById(state.pageSizeSelectId);
        const pagination = document.getElementById(state.paginationId);
        const summary = document.getElementById(state.summaryId);
        if (!body || !pageSizeSelect || !pagination || !summary) return;

        const pageSize = Math.max(1, Number(pageSizeSelect.value) || 10);
        const rows = Array.from(body.children);
        const filteredRows = rows.filter(row => !row.classList.contains('filter-hidden'));
        const total = filteredRows.length;
        const totalPages = Math.max(1, Math.ceil(total / pageSize));

        if (state.currentPage < 1) state.currentPage = 1;
        if (state.currentPage > totalPages) state.currentPage = totalPages;

        const startIndex = (state.currentPage - 1) * pageSize;
        const endIndex = startIndex + pageSize;

        rows.forEach(row => row.classList.add('page-hidden'));
        filteredRows.forEach((row, index) => {
            row.classList.toggle('page-hidden', index < startIndex || index >= endIndex);
        });

        pagination.querySelectorAll('a[data-page]').forEach(anchor => {
            const pageAttr = anchor.getAttribute('data-page');
            const item = anchor.closest('.page-item');
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
            const page = Number(pageAttr);
            const shouldHide = Number.isFinite(page) && page > totalPages;
            item.classList.toggle('d-none', shouldHide);
            item.classList.toggle('active', page === state.currentPage && !shouldHide);
            item.classList.remove('disabled');
        });

        const from = total === 0 ? 0 : startIndex + 1;
        const to = Math.min(endIndex, total);
        summary.innerHTML = `Showing <strong>${from} to ${to}</strong> of <strong>${total}</strong> ${state.itemLabel}`;
    }

    /* ─── View Restoration ─── */
    function restoreSavedViews() {
        const savedServiceUtil = AppStorage.get(STATE.SERVICE_UTIL_VIEW_KEY, APP.DEFAULTS.DASHBOARD_SERVICE_UTIL_VIEW);
        setServiceUtilizationView(savedServiceUtil, false);

        const savedMetric = AppStorage.get(STATE.APP_PERFORMANCE_METRIC_KEY, APP.DEFAULTS.DASHBOARD_APP_PERF_METRIC);
        setAppPerformanceMetric(savedMetric, false);

        const savedView = AppStorage.get(STATE.APP_PERFORMANCE_VIEW_KEY, APP.DEFAULTS.DASHBOARD_APP_PERF_VIEW);
        setAppPerformanceView(savedView, false);
    }

    /* ─── App Performance Chart ─── */
    function setAppPerformanceView(view = 'list', persist = true) {
        const normalizedView = view === 'graph' ? 'graph' : 'list';
        const listView = document.getElementById('appPerformanceListView');
        const graphView = document.getElementById('appPerformanceGraphView');
        const footer = document.getElementById('appPerformanceFooter');
        const listBtn = document.getElementById('appPerfListViewBtn');
        const graphBtn = document.getElementById('appPerfGraphViewBtn');

        if (!listView || !graphView || !footer || !listBtn || !graphBtn) return;

        const isGraph = normalizedView === 'graph';
        listView.classList.toggle('d-none', isGraph);
        graphView.classList.toggle('d-none', !isGraph);
        footer.classList.toggle('d-none', isGraph);

        listBtn.classList.toggle('active', !isGraph);
        graphBtn.classList.toggle('active', isGraph);
        listBtn.setAttribute('aria-pressed', String(!isGraph));
        graphBtn.setAttribute('aria-pressed', String(isGraph));

        if (isGraph) buildAppPerformanceGraph();

        if (persist) AppStorage.set(STATE.APP_PERFORMANCE_VIEW_KEY, normalizedView);
    }

    function setAppPerformanceMetric(metric = 'calls', persist = true) {
        const allowed = new Set(['calls', 'success', 'response', 'status']);
        const normalizedMetric = allowed.has(metric) ? metric : 'calls';
        document.documentElement.setAttribute('data-app-perf-metric', normalizedMetric);

        document.querySelectorAll('#appPerformanceMetricToggle [data-metric]').forEach(button => {
            const isActive = button.getAttribute('data-metric') === normalizedMetric;
            button.classList.toggle('active', isActive);
            button.setAttribute('aria-pressed', String(isActive));
        });

        if (persist) AppStorage.set(STATE.APP_PERFORMANCE_METRIC_KEY, normalizedMetric);
        buildAppPerformanceGraph();
    }

    function buildAppPerformanceGraph() {
        const rowsContainer = document.getElementById('appPerformanceGraphRows');
        const countBadge = document.getElementById('appPerformanceGraphCount');
        const pieChart = document.getElementById('appPerformancePieChart');
        const pieCenter = document.getElementById('appPerformancePieCenter');
        const chartCanvas = document.getElementById('appPerformanceChartCanvas');

        if (!rowsContainer || !countBadge || !pieChart || !pieCenter || !chartCanvas) return;

        if (STATE.appPerformanceChart) {
            STATE.appPerformanceChart.destroy();
            STATE.appPerformanceChart = null;
            hideAppChartTooltip();
        }

        const parseNumber = v => Number.parseFloat(String(v ?? '').replace(/[^\d.]/g, '')) || 0;
        const parseIntValue = v => Number.parseInt(String(v ?? '').replace(/[^\d]/g, ''), 10) || 0;

        const rows = Array.from(document.querySelectorAll('#appPerformanceTable tbody tr'))
            .filter(row => !row.classList.contains('filter-hidden'));

        const metric = document.documentElement.getAttribute('data-app-perf-metric') || 'calls';
        const isDarkMode = document.documentElement.getAttribute('data-bs-theme') === 'dark';
        const paletteColors = isDarkMode
            ? ['#67e8f9', '#60a5fa', '#a78bfa', '#f472b6', '#f59e0b', '#4ade80', '#f87171', '#c4b5fd']
            : ['#0ea5e9', '#2563eb', '#6366f1', '#db2777', '#ea580c', '#16a34a', '#dc2626', '#7c3aed'];
        const statusColors = isDarkMode
            ? { healthy: '#4ade80', watch: '#fbbf24', risk: '#f87171', unknown: '#94a3b8' }
            : { healthy: '#16a34a', watch: '#d97706', risk: '#dc2626', unknown: '#64748b' };

        const appStats = rows.map(row => {
            const app = row.querySelector('[data-col="app"]')?.textContent.trim() || 'Unknown';
            const api = row.querySelector('[data-col="api"]')?.textContent.trim() || 'N/A';
            return {
                app, api,
                callsText: row.querySelector('[data-col="calls"]')?.textContent.trim() || '0',
                successText: row.querySelector('[data-col="success"]')?.textContent.trim() || '0%',
                responseText: row.querySelector('[data-col="response"]')?.textContent.trim() || '0 ms',
                statusText: row.querySelector('[data-col="status"]')?.textContent.trim() || 'Unknown',
                calls: parseIntValue(row.querySelector('[data-col="calls"]')?.textContent),
                success: parseNumber(row.querySelector('[data-col="success"]')?.textContent),
                response: parseNumber(row.querySelector('[data-col="response"]')?.textContent)
            };
        });

        rowsContainer.innerHTML = '';

        if (!appStats.length) {
            countBadge.textContent = '0 apps';
            rowsContainer.innerHTML = '<div class="small text-muted">No applications match the current filter criteria.</div>';
            chartCanvas.style.visibility = 'hidden';
            pieCenter.textContent = 'No Data';
            hideAppChartTooltip();
            return;
        }

        chartCanvas.style.visibility = 'visible';
        let slices = [];
        let metricLabel = 'Calls';

        if (metric === 'status') {
            metricLabel = 'Status Mix';
            const groups = {
                healthy: { label: 'Healthy', value: 0, color: statusColors.healthy },
                watch: { label: 'Watch', value: 0, color: statusColors.watch },
                risk: { label: 'At Risk', value: 0, color: statusColors.risk },
                unknown: { label: 'Unknown', value: 0, color: statusColors.unknown }
            };
            appStats.forEach(item => {
                const s = item.statusText.toLowerCase();
                if (s.includes('healthy')) groups.healthy.value += 1;
                else if (s.includes('watch')) groups.watch.value += 1;
                else if (s.includes('risk')) groups.risk.value += 1;
                else groups.unknown.value += 1;
            });
            slices = Object.values(groups).filter(g => g.value > 0);
        } else {
            if (metric === 'success') metricLabel = 'Success %';
            else if (metric === 'response') metricLabel = 'Response Time';
            slices = appStats.map((item, i) => ({
                label: item.app, api: item.api,
                value: metric === 'success' ? item.success : metric === 'response' ? item.response : item.calls,
                color: paletteColors[i % paletteColors.length],
                callsText: item.callsText, successText: item.successText,
                responseText: item.responseText, statusText: item.statusText
            })).filter(s => s.value > 0);
        }

        const totalValue = slices.reduce((sum, s) => sum + s.value, 0);
        if (totalValue <= 0) {
            countBadge.textContent = `${appStats.length} app${appStats.length === 1 ? '' : 's'}`;
            rowsContainer.innerHTML = '<div class="small text-muted">No measurable values for selected metric.</div>';
            chartCanvas.style.visibility = 'hidden';
            pieCenter.textContent = metricLabel;
            hideAppChartTooltip();
            return;
        }

        chartCanvas.style.visibility = 'visible';
        const rootStyle = getComputedStyle(document.documentElement);
        const chartBorderColor = rootStyle.getPropertyValue('--ux-bg-primary').trim() || '#ffffff';

        STATE.appPerformanceChart = new Chart(chartCanvas, {
            type: 'doughnut',
            data: {
                labels: slices.map(s => s.label),
                datasets: [{
                    data: slices.map(s => s.value),
                    backgroundColor: slices.map(s => s.color),
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
                        enabled: false,
                        external: context => renderAppChartTooltip(context, slices, metric, totalValue)
                    }
                }
            }
        });

        chartCanvas.addEventListener('mouseleave', hideAppChartTooltip);
        pieChart.addEventListener('mouseleave', hideAppChartTooltip);

        const centerValue = metric === 'status' ? `${Math.round(totalValue)} apps`
            : metric === 'response' ? `${Math.round(totalValue)} ms`
                : metric === 'success' ? `${totalValue.toFixed(1)} pts`
                    : `${Math.round(totalValue).toLocaleString()}`;
        pieCenter.innerHTML = `${metricLabel}<br>${centerValue}`;

        slices.forEach(slice => {
            const percent = (slice.value / totalValue) * 100;
            const valueText = metric === 'status' ? `${slice.value} app${slice.value === 1 ? '' : 's'}`
                : metric === 'response' ? `${Math.round(slice.value)} ms`
                    : metric === 'success' ? `${slice.value.toFixed(1)}%`
                        : Math.round(slice.value).toLocaleString();

            const legend = document.createElement('div');
            legend.className = 'app-pie-legend-item';
            legend.innerHTML = `
                <span class="app-pie-swatch" style="background:${slice.color}"></span>
                <span class="app-pie-label">${slice.label}</span>
                <span class="app-pie-value">${valueText} (${percent.toFixed(1)}%)</span>
            `;
            rowsContainer.appendChild(legend);
        });

        countBadge.textContent = metric === 'status'
            ? `${appStats.length} app${appStats.length === 1 ? '' : 's'} | 4 states`
            : `${appStats.length} app${appStats.length === 1 ? '' : 's'} | ${metricLabel}`;
    }

    function renderAppChartTooltip(context, slices, metric, totalValue) {
        const { chart, tooltip } = context;
        let tooltipEl = document.getElementById('appPerformanceChartTooltip');
        if (!tooltipEl) {
            tooltipEl = document.createElement('div');
            tooltipEl.id = 'appPerformanceChartTooltip';
            tooltipEl.className = 'app-chart-tooltip';
            document.body.appendChild(tooltipEl);
        }

        if (!tooltip || !tooltip.dataPoints || !tooltip.dataPoints.length) {
            tooltipEl.style.opacity = '0';
            return;
        }

        const dataIndex = tooltip.dataPoints[0]?.dataIndex;
        const slice = Number.isInteger(dataIndex) ? slices[dataIndex] : null;
        if (!slice) { tooltipEl.style.opacity = '0'; return; }

        const percent = totalValue > 0 ? (slice.value / totalValue) * 100 : 0;
        const valueText = metric === 'status' ? `${slice.value} app${slice.value === 1 ? '' : 's'}`
            : metric === 'response' ? `${Math.round(slice.value)} ms`
                : metric === 'success' ? `${slice.value.toFixed(1)}%`
                    : Math.round(slice.value).toLocaleString();

        const lines = [`${valueText} (${percent.toFixed(1)}%)`];
        if (metric !== 'status') {
            lines.push(`API: ${slice.api}`, `Calls: ${slice.callsText}`, `Success: ${slice.successText}`,
                `Avg RT: ${slice.responseText}`, `Status: ${slice.statusText}`);
        }

        tooltipEl.innerHTML = `<div class="title">${slice.label}</div>${lines.map(l => `<div class="line">${l}</div>`).join('')}`;

        const rect = chart.canvas.getBoundingClientRect();
        const pageX = rect.left + window.scrollX + tooltip.caretX;
        const pageY = rect.top + window.scrollY + tooltip.caretY;
        tooltipEl.style.left = `${Math.max(window.scrollX + 10, Math.min(pageX + 14, window.scrollX + window.innerWidth - tooltipEl.offsetWidth - 10))}px`;
        tooltipEl.style.top = `${Math.max(window.scrollY + 10, Math.min(pageY + 14, window.scrollY + window.innerHeight - tooltipEl.offsetHeight - 10))}px`;
        tooltipEl.style.opacity = '1';
    }

    function hideAppChartTooltip() {
        const el = document.getElementById('appPerformanceChartTooltip');
        if (el) el.style.opacity = '0';
    }

    /* ─── Service Utilization ─── */
    function setServiceUtilizationView(view = 'list', persist = true) {
        const normalizedView = view === 'graph' ? 'graph' : 'list';
        const listView = document.getElementById('serviceUtilListView');
        const graphView = document.getElementById('serviceUtilGraphView');
        const listBtn = document.getElementById('serviceUtilListViewBtn');
        const graphBtn = document.getElementById('serviceUtilGraphViewBtn');
        if (!listView || !graphView || !listBtn || !graphBtn) return;

        const isGraph = normalizedView === 'graph';
        listView.classList.toggle('d-none', isGraph);
        graphView.classList.toggle('d-none', !isGraph);
        listBtn.classList.toggle('active', !isGraph);
        graphBtn.classList.toggle('active', isGraph);
        listBtn.setAttribute('aria-pressed', String(!isGraph));
        graphBtn.setAttribute('aria-pressed', String(isGraph));

        if (isGraph) {
            buildServiceUtilizationGraph();
            requestAnimationFrame(() => STATE.serviceUtilizationChart?.resize());
        }

        if (persist) AppStorage.set(STATE.SERVICE_UTIL_VIEW_KEY, normalizedView);
    }

    function buildServiceUtilizationGraph() {
        const canvas = document.getElementById('serviceUtilizationChart');
        const cardBody = canvas?.closest('.card-body');
        if (!canvas || !cardBody) return;

        const items = Array.from(cardBody.querySelectorAll('.service-util-item'));
        if (!items.length) return;

        const labels = [];
        const values = [];
        items.forEach(item => {
            const label = (item.getAttribute('data-label') || '').trim();
            const value = Number.parseFloat(item.getAttribute('data-utilization') || '0');
            if (label && Number.isFinite(value)) {
                labels.push(label);
                values.push(Math.max(0, Math.min(100, value)));
            }
        });

        if (!labels.length) return;

        if (STATE.serviceUtilizationChart) {
            STATE.serviceUtilizationChart.destroy();
            STATE.serviceUtilizationChart = null;
        }

        const isDark = document.documentElement.getAttribute('data-bs-theme') === 'dark';
        const barColors = isDark ? ['#67e8f9', '#60a5fa', '#4ade80', '#f59e0b'] : ['#0284c7', '#2563eb', '#16a34a', '#d97706'];
        const gridColor = isDark ? 'rgba(148, 163, 184, 0.24)' : 'rgba(100, 116, 139, 0.24)';
        const tickColor = isDark ? '#cbd5e1' : '#334155';
        const borderColor = isDark ? '#0f172a' : '#ffffff';

        STATE.serviceUtilizationChart = new Chart(canvas, {
            type: 'bar',
            data: {
                labels,
                datasets: [{
                    label: 'Utilization',
                    data: values,
                    backgroundColor: barColors.slice(0, labels.length),
                    borderColor,
                    borderWidth: 1,
                    borderRadius: 8,
                    borderSkipped: false,
                    maxBarThickness: 36
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                animation: { duration: 450 },
                plugins: {
                    legend: { display: false },
                    tooltip: {
                        enabled: true,
                        backgroundColor: 'rgba(15, 23, 42, 0.96)',
                        titleColor: '#ffffff',
                        bodyColor: '#dbeafe',
                        borderColor: 'rgba(148, 163, 184, 0.55)',
                        borderWidth: 1,
                        callbacks: {
                            title: items => items[0]?.label || 'Service',
                            label: ctx => `${ctx.parsed.y}% utilized`,
                            afterLabel: ctx => ctx.parsed.y >= 85 ? 'Status: High utilization'
                                : ctx.parsed.y >= 65 ? 'Status: Moderate utilization' : 'Status: Low utilization'
                        }
                    }
                },
                scales: {
                    x: { ticks: { color: tickColor, font: { size: 11, weight: 600 } }, grid: { color: 'transparent' } },
                    y: { beginAtZero: true, max: 100, ticks: { color: tickColor, callback: v => `${v}%` }, grid: { color: gridColor } }
                }
            }
        });
    }

    /* ─── Export ─── */
    function exportDashboardSummary() {
        const appRows = Array.from(document.querySelectorAll('#appPerformanceTable tbody tr'))
            .filter(row => !row.classList.contains('filter-hidden'));
        const parseIntValue = v => Number.parseInt(String(v).replace(/[^\d]/g, ''), 10) || 0;
        const parseFloatValue = v => Number.parseFloat(String(v).replace(/[^\d.]/g, '')) || 0;

        const stats = appRows.map(row => {
            const cells = row.querySelectorAll('td');
            return {
                app: cells[0]?.textContent.trim() || 'Unknown',
                api: cells[1]?.textContent.trim() || 'N/A',
                calls: parseIntValue(cells[2]?.textContent),
                success: parseFloatValue(cells[3]?.textContent),
                response: parseFloatValue(cells[4]?.textContent)
            };
        });

        const totalCalls = stats.reduce((s, i) => s + i.calls, 0);
        const avgSuccess = stats.length ? stats.reduce((s, i) => s + i.success, 0) / stats.length : 0;
        const avgResponse = stats.length ? stats.reduce((s, i) => s + i.response, 0) / stats.length : 0;

        const lines = [
            `DevBizToolsSuite Daily Summary - ${new Date().toLocaleString()}`,
            '',
            `Total API Calls (24h): ${totalCalls.toLocaleString()}`,
            `Average Success Rate: ${avgSuccess.toFixed(2)}%`,
            `Average Response Time: ${Math.round(avgResponse)} ms`,
            `Tracked Applications: ${stats.length}`,
            '',
            'Application Breakdown:',
            ...stats.map(i => `- ${i.app} [${i.api}] | Calls: ${i.calls.toLocaleString()} | Success: ${i.success.toFixed(1)}% | Avg RT: ${Math.round(i.response)} ms`)
        ];

        const blob = new Blob([lines.join('\n')], { type: 'text/plain;charset=utf-8' });
        const url = URL.createObjectURL(blob);
        const link = document.createElement('a');
        link.href = url;
        link.download = 'devbiztools-daily-summary.txt';
        document.body.appendChild(link);
        link.click();
        link.remove();
        URL.revokeObjectURL(url);
        showActionToast('Daily summary exported.', 'success');
    }

    /* ─── Bind Table Actions ─── */
    function bindTableActions() {
        document.querySelectorAll('[data-action="sort-table"]').forEach(link => {
            link.addEventListener('click', event => {
                event.preventDefault();
                const selector = link.getAttribute('data-table-selector');
                const column = Number(link.getAttribute('data-sort-column') || '1');
                if (!selector) { showActionToast('Sort target not found.', 'warning'); return; }
                sortTableRows(selector, column);
            });
        });

        document.querySelectorAll('[data-action="clear-filter"]').forEach(link => {
            link.addEventListener('click', event => {
                event.preventDefault();
                const inputId = link.getAttribute('data-filter-input');
                const input = inputId ? document.getElementById(inputId) : null;
                if (input) {
                    input.value = '';
                    input.dispatchEvent(new Event('input', { bubbles: true }));
                    showActionToast('Filter cleared.', 'secondary');
                } else {
                    showActionToast('Nothing to clear.', 'warning');
                }
            });
        });
    }

    function sortTableRows(tableBodySelector, columnIndex) {
        const body = document.querySelector(tableBodySelector);
        if (!body) return;

        const direction = STATE.tableSortState.get(tableBodySelector) === 'asc' ? 'desc' : 'asc';
        STATE.tableSortState.set(tableBodySelector, direction);

        const rows = Array.from(body.children);
        rows.sort((a, b) => {
            const aText = (a.children[columnIndex]?.textContent || '').trim().toLowerCase();
            const bText = (b.children[columnIndex]?.textContent || '').trim().toLowerCase();
            return direction === 'asc' ? aText.localeCompare(bText) : bText.localeCompare(aText);
        });

        rows.forEach(row => body.appendChild(row));

        const pagState = STATE.paginationRegistry.get(tableBodySelector);
        if (pagState) applyPaginationState(pagState);
        buildAppPerformanceGraph();
        showActionToast(`Sorted ${direction === 'asc' ? 'ascending' : 'descending'}.`, 'info');
    }

    /* ─── Tooltip helpers ─── */
    function initializeTooltips() {
        if (typeof bootstrap === 'undefined' || !bootstrap.Tooltip) return;
        document.querySelectorAll('[title]:not([data-bs-toggle="pill"]):not([data-bs-toggle="tab"])').forEach(el => {
            const text = (el.getAttribute('title') || '').trim();
            if (!text) return;
            bootstrap.Tooltip.getOrCreateInstance(el, { container: 'body', trigger: 'hover focus' });
        });
    }

    /* ─── Bootstrap ─── */
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', init);
    } else {
        init();
    }
})();
