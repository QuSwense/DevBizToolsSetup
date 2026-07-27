/**
 * DevBizToolsSuite - REST API Test Module
 * Handles REST API registry, operations, execution, and history.
 */
(function () {
    'use strict';

    /* ─── Module State ─── */
    const STATE = {
        apis: [],
        history: [],
        historyIdCounter: 100
    };

    /* ─── Initialization ─── */
    function init() {
        if (!document.getElementById('restExecApplication')) {
            setTimeout(init, 50);
            return;
        }

        loadData();
        populateAppDropdowns();
        renderApisTable();
        renderFilesTable();
        renderHistoryTable();
        updateCounts();
        initializeTooltips();
    }

    function loadData() {
        var dataStore = window.DATA || {};
        STATE.apis = Array.isArray(dataStore.restApiRegistry) ? JSON.parse(JSON.stringify(dataStore.restApiRegistry)) : [];

        var rawHistory = Array.isArray(dataStore.restHistory) ? dataStore.restHistory : [];
        STATE.history = rawHistory.map(function (entry) {
            return {
                id: 'rh-' + (STATE.historyIdCounter++),
                timestamp: entry.timestamp || '',
                endpoint: entry.endpoint || '',
                method: entry.method || 'GET',
                status: entry.status || 0,
                statusClass: entry.statusClass || 'bg-success',
                duration: entry.duration || '--',
                action: entry.action || ''
            };
        });
    }

    /* ─── App Dropdowns ─── */
    function populateAppDropdowns() {
        var execSel = document.getElementById('restExecApplication');
        var swagSel = document.getElementById('restSwaggerApplication');
        if (!execSel) return;

        execSel.innerHTML = '<option value="">-- Select Application --</option>';
        if (swagSel) swagSel.innerHTML = '<option value="">-- Select Application --</option>';

        STATE.apis.forEach(function (api) {
            var opt = document.createElement('option');
            opt.value = api.id;
            opt.textContent = api.name;
            execSel.appendChild(opt);
            if (swagSel) {
                var opt2 = document.createElement('option');
                opt2.value = api.id;
                opt2.textContent = api.name;
                swagSel.appendChild(opt2);
            }
        });

        execSel.addEventListener('change', onAppChange);
    }

    function onAppChange() {
        var sel = document.getElementById('restExecApplication');
        var opSel = document.getElementById('restExecOperation');
        var methodInput = document.getElementById('restExecMethod');
        var urlInput = document.getElementById('restExecUrl');
        if (!opSel || !methodInput || !urlInput) return;

        opSel.innerHTML = '<option value="">-- Select Operation --</option>';
        var apiId = sel.value;
        var api = STATE.apis.find(function (a) { return a.id === apiId; });

        if (api && api.operations) {
            urlInput.value = api.baseUrl || '';
            api.operations.forEach(function (op) {
                var opt = document.createElement('option');
                opt.value = op.id;
                opt.textContent = op.method + ' ' + op.path + ' — ' + (op.summary || op.operationId);
                opt.dataset.method = op.method;
                opt.dataset.path = op.path;
                opSel.appendChild(opt);
            });
        } else {
            urlInput.value = '';
            methodInput.value = '';
        }

        opSel.addEventListener('change', function () {
            var selected = opSel.options[opSel.selectedIndex];
            if (selected && selected.value) {
                methodInput.value = selected.dataset.method || '';
                var baseUrl = urlInput.value.replace(/\/+$/, '');
                var path = (selected.dataset.path || '').replace(/\/+/g, '/');
                urlInput.value = baseUrl + path;
            } else {
                methodInput.value = '';
            }
        });
    }

    /* ─── Execute REST Call ─── */
    function executeRestCall() {
        var appSel = document.getElementById('restExecApplication');
        var opSel = document.getElementById('restExecOperation');
        var urlInput = document.getElementById('restExecUrl');
        var methodInput = document.getElementById('restExecMethod');

        var appName = appSel.options[appSel.selectedIndex] ? appSel.options[appSel.selectedIndex].text : '';
        var url = urlInput.value;
        var method = methodInput.value || 'GET';

        if (!appSel.value) { showActionToast('Please select an application.', 'warning'); return; }
        if (!url) { showActionToast('Please provide a request URL.', 'warning'); return; }

        showActionToast('Executing ' + method + ' ' + url + '...', 'info');

        var panel = document.getElementById('restResponsePanel');
        var statusEl = document.getElementById('restResponseStatusCode');
        var timeEl = document.getElementById('restResponseTime');
        var ttfbEl = document.getElementById('restResponseTtfb');
        var sizeEl = document.getElementById('restResponseSize');
        var bodyEl = document.getElementById('restResponseBody');

        panel.style.display = 'block';
        statusEl.textContent = 'Executing...';
        statusEl.className = 'badge badge-status-checking';
        statusEl.innerHTML = '<i class="fa-solid fa-spinner fa-spin me-1"></i>Executing';
        timeEl.textContent = '--';
        ttfbEl.textContent = 'TTFB: --';
        sizeEl.textContent = 'Size: --';
        setEditorContent(bodyEl, '');

        var ttfb = 20 + Math.round(Math.random() * 80);
        var totalTime = ttfb + 40 + Math.round(Math.random() * 150);

        setTimeout(function () {
            var statusCode = 200;
            var statusText = 'OK';

            var sampleResponse = JSON.stringify({
                success: true,
                data: {
                    id: Math.floor(Math.random() * 1000),
                    message: 'Request completed successfully',
                    timestamp: new Date().toISOString()
                }
            }, null, 2);

            statusEl.textContent = statusCode + ' ' + statusText;
            statusEl.className = 'badge badge-status-healthy';
            timeEl.textContent = totalTime + ' ms';
            ttfbEl.textContent = 'TTFB: ' + ttfb + ' ms';
            sizeEl.textContent = 'Size: ' + sampleResponse.length + ' bytes';
            setEditorContent(bodyEl, sampleResponse);

            STATE.history.unshift({
                id: 'rh-' + (STATE.historyIdCounter++),
                timestamp: new Date().toISOString().replace('T', ' ').substring(0, 19),
                endpoint: url.length > 60 ? '...' + url.substring(url.length - 60) : url,
                method: method,
                status: statusCode,
                statusClass: 'bg-success',
                duration: totalTime + ' ms',
                action: 'Load'
            });

            renderHistoryTable();
            updateCounts();
            showActionToast('REST call completed successfully.', 'success');
        }, 500 + Math.round(Math.random() * 300));
    }

    /* ─── API CRUD ─── */
    function renderApisTable() {
        var tbody = document.getElementById('restApisTbody');
        if (!tbody) return;
        if (!STATE.apis.length) {
            tbody.innerHTML = '<tr><td colspan="6" class="text-center text-muted py-3">No registered REST APIs.</td></tr>';
            return;
        }
        tbody.innerHTML = STATE.apis.map(function (api, idx) {
            var opsHtml = (api.operations || []).map(function (op) {
                var methodBadge = 'bg-' + (op.method === 'GET' ? 'success' : op.method === 'POST' ? 'primary' : op.method === 'PUT' ? 'warning' : 'danger');
                return '<div class="rest-op-row d-flex align-items-center gap-2 py-1">' +
                    '<span class="badge ' + methodBadge + ' fs-8">' + op.method + '</span>' +
                    '<code class="fs-8">' + escapeHtml(op.path) + '</code>' +
                    '<span class="text-muted fs-8">' + escapeHtml(op.summary || op.operationId || '') + '</span>' +
                    '</div>';
            }).join('');
            return '<tr>' +
                '<td class="fw-semibold">' + escapeHtml(api.name) + '</td>' +
                '<td class="text-truncate" style="max-width:180px;"><code class="fs-8">' + escapeHtml(api.baseUrl) + '</code></td>' +
                '<td><span class="badge bg-light text-dark border">' + escapeHtml(api.authType || 'None') + '</span></td>' +
                '<td class="fs-7">' + escapeHtml(api.registeredDate || '--') + '</td>' +
                '<td>' +
                '<button class="btn btn-sm btn-outline-info" data-bs-toggle="collapse" data-bs-target="#restOps-collapse-' + idx + '">' +
                '<i class="fa-solid fa-list me-1"></i>' + (api.operations ? api.operations.length : 0) + ' Ops</button>' +
                '<div class="collapse mt-1" id="restOps-collapse-' + idx + '">' + opsHtml + '</div>' +
                '</td>' +
                '<td class="text-center">' +
                '<div class="btn-group btn-group-sm">' +
                '<button class="btn btn-outline-secondary" onclick="window.REST_MODULE.editApi(' + idx + ')" title="Edit"><i class="fa-solid fa-pen"></i></button>' +
                '<button class="btn btn-outline-danger" onclick="window.REST_MODULE.deleteApi(' + idx + ')" title="Delete"><i class="fa-solid fa-trash-can"></i></button>' +
                '</div>' +
                '</td>' +
                '</tr>';
        }).join('');
    }

    function addApi() {
        var name = prompt('Enter API name:');
        if (!name) return;
        var baseUrl = prompt('Enter Base URL:');
        if (!baseUrl) return;
        STATE.apis.push({
            id: 'api-' + Date.now(),
            name: name,
            baseUrl: baseUrl,
            authType: 'None',
            registeredDate: new Date().toISOString().split('T')[0],
            operations: []
        });
        renderApisTable();
        populateAppDropdowns();
        updateCounts();
        showActionToast('API "' + name + '" added.', 'success');
    }

    function editApi(idx) {
        var api = STATE.apis[idx];
        if (!api) return;
        var name = prompt('API name:', api.name);
        if (!name) return;
        var url = prompt('Base URL:', api.baseUrl);
        if (!url) return;
        api.name = name;
        api.baseUrl = url;
        renderApisTable();
        populateAppDropdowns();
        showActionToast('API updated.', 'success');
    }

    function deleteApi(idx) {
        var api = STATE.apis[idx];
        if (!api) return;
        if (!confirm('Delete API "' + api.name + '"?')) return;
        STATE.apis.splice(idx, 1);
        renderApisTable();
        populateAppDropdowns();
        updateCounts();
        showActionToast('API deleted.', 'secondary');
    }

    /* ─── Swagger ─── */
    function updateSwagger() {
        var sel = document.getElementById('restSwaggerApplication');
        var url = document.getElementById('restSwaggerUrl');
        var preview = document.getElementById('restSwaggerPreview');
        if (!sel || !url || !preview) return;
        var apiId = sel.value;
        if (!apiId) { showActionToast('Please select an application.', 'warning'); return; }
        var api = STATE.apis.find(function (a) { return a.id === apiId; });
        if (api) url.value = api.baseUrl + '/swagger/v1/swagger.json';
        setEditorContent(preview, JSON.stringify({
            openapi: '3.0.3',
            info: { title: api ? api.name : 'Unknown API', version: '1.0.0' },
            servers: [{ url: api ? api.baseUrl : '' }],
            paths: api && api.operations ? api.operations.reduce(function (acc, op) {
                var pathKey = op.path || '/';
                if (!acc[pathKey]) acc[pathKey] = {};
                acc[pathKey][op.method.toLowerCase()] = {
                    operationId: op.operationId,
                    summary: op.summary || '',
                    responses: { '200': { description: 'Successful response' } }
                };
                return acc;
            }, {}) : {}
        }, null, 2));
        showActionToast('OpenAPI spec updated.', 'success');
    }

    function saveSwagger() {
        showActionToast('OpenAPI configuration saved.', 'success');
    }

    /* ─── Request Files ─── */
    function renderFilesTable() {
        var tbody = document.getElementById('restFilesTbody');
        if (!tbody) return;
        var sampleFiles = [
            { name: 'get_inventory_items.json', endpoint: '.../inventory/items', method: 'GET', lastModified: '2026-07-24 14:30' },
            { name: 'create_customer.json', endpoint: '.../customers', method: 'POST', lastModified: '2026-07-23 09:15' },
            { name: 'update_billing_event.json', endpoint: '.../billing/events/123', method: 'PUT', lastModified: '2026-07-22 16:45' }
        ];
        tbody.innerHTML = sampleFiles.map(function (f) {
            var methodBadge = 'bg-' + (f.method === 'GET' ? 'success' : f.method === 'POST' ? 'primary' : f.method === 'PUT' ? 'warning' : 'danger');
            return '<tr>' +
                '<td class="fw-semibold"><i class="fa-regular fa-file-code text-primary me-1"></i>' + escapeHtml(f.name) + '</td>' +
                '<td class="text-truncate" style="max-width:180px;"><code class="fs-8">' + escapeHtml(f.endpoint) + '</code></td>' +
                '<td><span class="badge ' + methodBadge + ' fs-8">' + f.method + '</span></td>' +
                '<td class="fs-7">' + escapeHtml(f.lastModified) + '</td>' +
                '</tr>';
        }).join('');
    }

    /* ─── History ─── */
    function renderHistoryTable() {
        var tbody = document.getElementById('restHistoryTbody');
        if (!tbody) return;
        if (!STATE.history.length) {
            tbody.innerHTML = '<tr><td colspan="6" class="text-center text-muted py-3">No REST execution history yet.</td></tr>';
            return;
        }
        tbody.innerHTML = STATE.history.map(function (entry, idx) {
            var methodBadge = 'bg-' + (entry.method === 'GET' ? 'success' : entry.method === 'POST' ? 'primary' : entry.method === 'PUT' ? 'warning' : 'danger');
            var statusBadge = entry.status >= 200 && entry.status < 300 ? 'badge-status-healthy'
                : entry.status >= 400 ? 'badge-status-danger' : 'badge-status-pending';
            return '<tr>' +
                '<td class="text-nowrap fs-7">' + escapeHtml(entry.timestamp) + '</td>' +
                '<td class="text-truncate" style="max-width:200px;"><code class="fs-8">' + escapeHtml(entry.endpoint) + '</code></td>' +
                '<td><span class="badge ' + methodBadge + ' fs-8">' + entry.method + '</span></td>' +
                '<td class="text-center"><span class="badge ' + statusBadge + '">' + entry.status + '</span></td>' +
                '<td class="text-center fs-7">' + escapeHtml(entry.duration) + '</td>' +
                '<td class="text-center">' +
                '<button class="btn btn-sm btn-outline-info" onclick="window.REST_MODULE.viewHistory(' + idx + ')"><i class="fa-solid fa-eye"></i></button>' +
                '</td>' +
                '</tr>';
        }).join('');
    }

    function viewHistory(idx) {
        var entry = STATE.history[idx];
        if (!entry) return;
        showActionToast('Timestamp: ' + entry.timestamp + ' | ' + entry.method + ' ' + entry.endpoint + ' | Status: ' + entry.status, 'info');
    }

    function clearHistory() {
        if (!confirm('Clear all REST execution history?')) return;
        STATE.history = [];
        renderHistoryTable();
        updateCounts();
        showActionToast('History cleared.', 'secondary');
    }

    /* ─── Utility ─── */
    function updateCounts() {
        var apiCount = document.getElementById('restApisCount');
        var histCount = document.getElementById('restHistoryCount');
        if (apiCount) apiCount.textContent = STATE.apis.length + ' APIs';
        if (histCount) histCount.textContent = STATE.history.length + ' records';
    }

    function clearForm() {
        document.getElementById('restExecApplication').value = '';
        document.getElementById('restExecOperation').innerHTML = '<option value="">-- Select Operation --</option>';
        document.getElementById('restExecMethod').value = '';
        document.getElementById('restExecUrl').value = '';
        setEditorContent('restExecBody', '');
        setEditorContent('restResponseBody', '');
        document.getElementById('restExecHeadersContainer').innerHTML = '';
        document.getElementById('restResponsePanel').style.display = 'none';
    }

    function addHeaderRow() {
        var container = document.getElementById('restExecHeadersContainer');
        if (!container) return;
        var row = document.createElement('div');
        row.className = 'rest-exec-header-row row g-2 mb-1';
        row.innerHTML = '<div class="col-5"><input type="text" class="form-control form-control-sm rest-header-name" placeholder="Header Name"></div>' +
            '<div class="col-5"><input type="text" class="form-control form-control-sm rest-header-value" placeholder="Header Value"></div>' +
            '<div class="col-2"><button class="btn btn-sm btn-outline-danger w-100" onclick="this.closest(\'.rest-exec-header-row\').remove()"><i class="fa-solid fa-trash-can"></i></button></div>';
        container.appendChild(row);
    }

    function escapeHtml(value) {
        return String(value ?? '')
            .replace(/&/g, '&amp;').replace(/</g, '&lt;')
            .replace(/>/g, '&gt;').replace(/"/g, '&quot;')
            .replace(/'/g, '&#39;');
    }

    /* ─── Public API ─── */
    window.REST_MODULE = {
        init: init,
        execute: executeRestCall,
        clearForm: clearForm,
        addHeaderRow: addHeaderRow,
        addApi: addApi,
        editApi: editApi,
        deleteApi: deleteApi,
        updateSwagger: updateSwagger,
        saveSwagger: saveSwagger,
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
