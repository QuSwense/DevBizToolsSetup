/**
 * DevBizToolsSuite - SOAP API Test Module
 * Handles SOAP application registry, test suites, execution, and history.
 */
(function () {
    'use strict';

    /* ─── Module State ─── */
    const STATE = {
        apps: [],
        suites: [],
        history: [],
        historyIdCounter: 300,
        suiteIdCounter: 1
    };

    /* ─── Initialization ─── */
    function init() {
        if (!document.getElementById('soapExecApplication')) {
            setTimeout(init, 50);
            return;
        }

        loadData();
        populateAppDropdowns();
        populateSoapFiles();
        renderSoapAppsTable();
        renderSuitesTable();
        renderHistoryTable();
        setupAuthToggle();
        updateCounts();
        initializeTooltips();
    }

    function loadData() {
        const dataStore = window.DATA || {};
        STATE.apps = Array.isArray(dataStore.soapApps) ? dataStore.soapApps : [];

        const rawHistory = Array.isArray(dataStore.soapHistory) ? dataStore.soapHistory : [];
        STATE.history = rawHistory.map(function (entry) {
            return {
                id: 'hist-' + (STATE.historyIdCounter++),
                timestamp: entry.timestamp || '',
                application: entry.application || '',
                soapAction: entry.soapAction || '',
                endpoint: entry.endpoint || '',
                httpStatus: entry.status || 0,
                statusText: entry.statusText || '',
                ttfb: entry.ttfb || '--',
                totalTime: entry.duration || '--',
                contentType: entry.contentType || '',
                contentLength: entry.contentLength || '',
                responseHeaders: entry.responseHeaders || [],
                responseBody: entry.responseBody || '',
                faultCode: entry.faultCode || null,
                faultString: entry.faultString || null,
                faultActor: entry.faultActor || null,
                faultDetail: entry.faultDetail || null,
                assertions: entry.assertions || []
            };
        });

        // Initialize test suites from sample
        STATE.suites = [
            { id: 'suite-1', name: 'Payment Smoke Tests', app: 'Payment Gateway Service', description: 'Core payment flow verification', cases: 3 },
            { id: 'suite-2', name: 'Customer Account Validation', app: 'Customer Account Service', description: 'Account CRUD test cases', cases: 2 }
        ];
        STATE.suiteIdCounter = 3;
    }

    /* ─── App Dropdowns ─── */
    function populateAppDropdowns() {
        const execSel = document.getElementById('soapExecApplication');
        const wsdlSel = document.getElementById('soapWsdlApplication');
        if (!execSel) return;

        execSel.innerHTML = '<option value="">-- Select Application --</option>';
        if (wsdlSel) wsdlSel.innerHTML = '<option value="">-- Select Application --</option>';

        STATE.apps.forEach(function (app) {
            var opt = document.createElement('option');
            opt.value = app.name;
            opt.textContent = app.name;
            execSel.appendChild(opt);
            if (wsdlSel) {
                var opt2 = document.createElement('option');
                opt2.value = app.name;
                opt2.textContent = app.name;
                wsdlSel.appendChild(opt2);
            }
        });

        execSel.addEventListener('change', onAppChange);
    }

    function onAppChange() {
        var sel = document.getElementById('soapExecApplication');
        var actionSel = document.getElementById('soapExecSoapAction');
        var endpointInput = document.getElementById('soapExecEndpointUrl');
        if (!actionSel || !endpointInput) return;

        actionSel.innerHTML = '<option value="">-- Select Action --</option>';
        var appName = sel.value;
        var app = STATE.apps.find(function (a) { return a.name === appName; });

        if (app) {
            endpointInput.value = app.wsdlUrl ? app.wsdlUrl.replace('?wsdl', '') : '';
            (app.soapActions || []).forEach(function (action) {
                var opt = document.createElement('option');
                opt.value = action.name;
                opt.textContent = action.name + (action.summary ? ' — ' + action.summary : '');
                actionSel.appendChild(opt);
            });
        } else {
            endpointInput.value = '';
        }
    }

    /* ─── SOAP Request Files ─── */
    function populateSoapFiles() {
        var tbody = document.getElementById('soapFilesTbody');
        if (!tbody) return;
        var files = (window.DATA && Array.isArray(window.DATA.soapRequestFiles)) ? window.DATA.soapRequestFiles : [];
        if (!files.length) {
            tbody.innerHTML = '<tr><td colspan="5" class="text-center text-muted py-3">No SOAP request files found.</td></tr>';
            return;
        }
        tbody.innerHTML = files.map(function (f) {
            return '<tr>' +
                '<td class="fw-semibold"><i class="fa-regular fa-file-code text-primary me-1"></i>' + escapeHtml(f.name) + '</td>' +
                '<td>' + escapeHtml(f.application) + '</td>' +
                '<td><code class="fs-8">' + escapeHtml(f.actionName || f.soapAction) + '</code></td>' +
                '<td>' + escapeHtml(f.payloadSize) + '</td>' +
                '<td>' + escapeHtml(f.lastModified) + '</td>' +
                '</tr>';
        }).join('');
    }

    /* ─── Registered Apps Table ─── */
    function renderSoapAppsTable() {
        var tbody = document.getElementById('soapAppsTbody');
        if (!tbody) return;
        if (!STATE.apps.length) {
            tbody.innerHTML = '<tr><td colspan="6" class="text-center text-muted py-3">No registered applications.</td></tr>';
            return;
        }
        tbody.innerHTML = STATE.apps.map(function (app, idx) {
            var actionsHtml = (app.soapActions || []).map(function (a) {
                return '<div class="soap-action-row d-flex align-items-center gap-2 py-1">' +
                    '<span class="badge bg-light text-dark border fs-8">' + escapeHtml(a.name) + '</span>' +
                    '<span class="text-muted fs-8">' + escapeHtml(a.summary || '') + '</span>' +
                    '</div>';
            }).join('');
            return '<tr>' +
                '<td class="fw-semibold">' + escapeHtml(app.name) + '</td>' +
                '<td class="text-truncate" style="max-width:180px;"><code class="fs-8">' + escapeHtml(app.wsdlUrl) + '</code></td>' +
                '<td>' + escapeHtml(app.description || '') + '</td>' +
                '<td class="fs-7">' + escapeHtml(app.registeredDate || '--') + '</td>' +
                '<td>' +
                '<button class="btn btn-sm btn-outline-info" data-bs-toggle="collapse" data-bs-target="#soapActions-collapse-' + idx + '">' +
                '<i class="fa-solid fa-list me-1"></i>' + (app.soapActions ? app.soapActions.length : 0) + ' Actions</button>' +
                '<div class="collapse mt-1" id="soapActions-collapse-' + idx + '">' + actionsHtml + '</div>' +
                '</td>' +
                '<td class="text-center">' +
                '<div class="btn-group btn-group-sm">' +
                '<button class="btn btn-outline-secondary" onclick="window.SOAP_MODULE.editApp(' + idx + ')" title="Edit"><i class="fa-solid fa-pen"></i></button>' +
                '<button class="btn btn-outline-danger" onclick="window.SOAP_MODULE.deleteApp(' + idx + ')" title="Delete"><i class="fa-solid fa-trash-can"></i></button>' +
                '</div>' +
                '</td>' +
                '</tr>';
        }).join('');
    }

    /* ─── Test Suites ─── */
    function renderSuitesTable() {
        var tbody = document.getElementById('soapSuiteTbody');
        var footer = document.getElementById('soapSuiteEmpty');
        if (!tbody) return;
        if (!STATE.suites.length) {
            tbody.innerHTML = '';
            if (footer) footer.style.display = 'block';
            return;
        }
        if (footer) footer.style.display = 'none';
        tbody.innerHTML = STATE.suites.map(function (suite, idx) {
            return '<tr>' +
                '<td class="fw-semibold">' + escapeHtml(suite.name) + '</td>' +
                '<td>' + escapeHtml(suite.app) + '</td>' +
                '<td>' + escapeHtml(suite.description || '') + '</td>' +
                '<td class="text-center"><span class="badge bg-light text-dark border">' + (suite.cases || 0) + '</span></td>' +
                '<td class="text-center">' +
                '<div class="btn-group btn-group-sm">' +
                '<button class="btn btn-outline-primary" onclick="window.SOAP_MODULE.runSuite(' + idx + ')" title="Run"><i class="fa-solid fa-play"></i></button>' +
                '<button class="btn btn-outline-secondary" onclick="window.SOAP_MODULE.editSuite(' + idx + ')" title="Edit"><i class="fa-solid fa-pen"></i></button>' +
                '<button class="btn btn-outline-danger" onclick="window.SOAP_MODULE.deleteSuite(' + idx + ')" title="Delete"><i class="fa-solid fa-trash-can"></i></button>' +
                '</div>' +
                '</td>' +
                '</tr>';
        }).join('');
    }

    /* ─── History ─── */
    function renderHistoryTable() {
        var tbody = document.getElementById('soapHistoryTbody');
        if (!tbody) return;
        if (!STATE.history.length) {
            tbody.innerHTML = '<tr><td colspan="10" class="text-center text-muted py-3">No execution history yet.</td></tr>';
            return;
        }
        tbody.innerHTML = STATE.history.map(function (entry, idx) {
            var statusBadge = entry.httpStatus >= 200 && entry.httpStatus < 300 ? 'badge-status-healthy'
                : entry.httpStatus >= 400 && entry.httpStatus < 500 ? 'badge-status-warning'
                    : 'badge-status-danger';
            var passed = entry.assertions.filter(function (a) { return a.passed; }).length;
            var total = entry.assertions.length || 0;
            var assertText = total > 0 ? passed + '/' + total : '--';
            var assertBadge = passed === total && total > 0 ? 'badge-status-healthy'
                : (passed > 0 ? 'badge-status-warning' : 'badge-status-pending');
            var faultBadge = entry.faultCode
                ? '<span class="badge badge-status-danger fs-8">Yes</span>'
                : '<span class="badge badge-status-healthy fs-8">None</span>';

            return '<tr>' +
                '<td class="text-nowrap fs-7">' + escapeHtml(entry.timestamp) + '</td>' +
                '<td>' + escapeHtml(entry.application || '--') + '</td>' +
                '<td><code class="fs-8">' + escapeHtml(entry.soapAction || '--') + '</code></td>' +
                '<td class="text-truncate" style="max-width:160px;">' + escapeHtml(entry.endpoint) + '</td>' +
                '<td class="text-center"><span class="badge ' + statusBadge + '">' + entry.httpStatus + '</span></td>' +
                '<td class="text-center fs-7">' + escapeHtml(entry.ttfb) + '</td>' +
                '<td class="text-center fs-7">' + escapeHtml(entry.totalTime) + '</td>' +
                '<td class="text-center"><span class="badge ' + assertBadge + ' fs-8">' + assertText + '</span></td>' +
                '<td class="text-center">' + faultBadge + '</td>' +
                '<td class="text-center">' +
                '<button class="btn btn-sm btn-outline-info" onclick="window.SOAP_MODULE.viewHistory(' + idx + ')"><i class="fa-solid fa-eye"></i></button>' +
                '</td>' +
                '</tr>';
        }).join('');
    }

    /* ─── Update Counts ─── */
    function updateCounts() {
        var appCount = document.getElementById('soapAppsCount');
        var suiteCount = document.getElementById('soapSuiteCount');
        var fileCount = document.getElementById('soapFilesCount');
        var histCount = document.getElementById('soapHistoryCount');
        if (appCount) appCount.textContent = STATE.apps.length + ' apps';
        if (suiteCount) suiteCount.textContent = STATE.suites.length + ' suites';
        if (fileCount) {
            var files = (window.DATA && Array.isArray(window.DATA.soapRequestFiles)) ? window.DATA.soapRequestFiles : [];
            fileCount.textContent = files.length + ' files';
        }
        if (histCount) histCount.textContent = STATE.history.length + ' records';
    }

    /* ─── Auth Toggle ─── */
    function setupAuthToggle() {
        var authSelect = document.getElementById('soapExecAuthType');
        if (!authSelect) return;
        authSelect.addEventListener('change', function () {
            var val = this.value;
            document.querySelectorAll('.soap-auth-basic, .soap-auth-bearer, .soap-auth-wssecurity')
                .forEach(function (el) { el.style.display = 'none'; });
            if (val === 'basic') {
                document.querySelectorAll('.soap-auth-basic').forEach(function (el) { el.style.display = 'block'; });
            } else if (val === 'bearer') {
                document.querySelectorAll('.soap-auth-bearer').forEach(function (el) { el.style.display = 'block'; });
            } else if (val === 'ws-security') {
                document.querySelectorAll('.soap-auth-wssecurity').forEach(function (el) { el.style.display = 'block'; });
            }
        });
    }

    /* ─── Execute SOAP Call ─── */
    function executeSoapCall() {
        var appName = document.getElementById('soapExecApplication').value;
        var actionName = document.getElementById('soapExecSoapAction').value;
        var endpoint = document.getElementById('soapExecEndpointUrl').value;

        if (!appName) { showActionToast('Please select an application.', 'warning'); return; }
        if (!actionName) { showActionToast('Please select a SOAPAction.', 'warning'); return; }
        if (!endpoint) { showActionToast('Please provide a target endpoint URL.', 'warning'); return; }

        showActionToast('Executing SOAP call...', 'info');

        var panel = document.getElementById('soapResponsePanel');
        var statusEl = document.getElementById('soapResponseStatusCode');
        var timeEl = document.getElementById('soapResponseTime');
        var ttfbEl = document.getElementById('soapResponseTtfb');
        var sizeEl = document.getElementById('soapResponseContentLength');
        var assertEl = document.getElementById('soapResponseAssertionBadge');
        var bodyEl = document.getElementById('soapResponseBody');

        panel.style.display = 'block';
        statusEl.textContent = 'Executing...';
        statusEl.className = 'badge badge-status-checking';
        statusEl.innerHTML = '<i class="fa-solid fa-spinner fa-spin me-1"></i>Executing';
        timeEl.textContent = '--';
        ttfbEl.textContent = 'TTFB: --';
        sizeEl.textContent = 'Size: --';
        assertEl.innerHTML = '';
        setEditorContent(bodyEl, '');

        var ttfb = 35 + Math.round(Math.random() * 120);
        var totalTime = ttfb + 80 + Math.round(Math.random() * 300);

        setTimeout(function () {
            var statusCode = 200;
            var statusText = 'OK';
            var contentType = 'text/xml; charset=utf-8';
            var contentLength = (1200 + Math.round(Math.random() * 800)).toString();

            var sampleResponse = '<?xml version="1.0" encoding="utf-8"?>\n' +
                '<Envelope xmlns="http://schemas.xmlsoap.org/soap/envelope/">\n' +
                '  <Body>\n' +
                '    <' + actionName + 'Response xmlns="http://tempuri.org/">\n' +
                '      <Result>Success</Result>\n' +
                '      <TransactionId>TXN-' + Math.floor(100000 + Math.random() * 900000) + '</TransactionId>\n' +
                '    </' + actionName + 'Response>\n' +
                '  </Body>\n' +
                '</Envelope>';

            var assertions = [
                { name: 'HTTP Status Code', expected: '200', actual: String(statusCode), passed: true },
                { name: 'SLA Response Time', expected: '< 3000 ms', actual: totalTime + ' ms', passed: totalTime < 3000 },
                { name: 'SOAP Fault Present', expected: 'false', actual: 'No', passed: true }
            ];

            statusEl.textContent = statusCode + ' ' + statusText;
            statusEl.className = 'badge badge-status-healthy';
            timeEl.textContent = totalTime + ' ms';
            ttfbEl.textContent = 'TTFB: ' + ttfb + ' ms';
            sizeEl.textContent = 'Size: ' + contentLength + ' bytes';
            setEditorContent(bodyEl, sampleResponse);

            var passed = assertions.filter(function (a) { return a.passed; }).length;
            var total = assertions.length;
            var assertBadge = passed === total ? 'badge-status-healthy' : 'badge-status-warning';
            assertEl.innerHTML = '<span class="badge ' + assertBadge + '">' + passed + '/' + total + ' passed</span>';

            // Add to history
            STATE.history.unshift({
                id: 'hist-' + (STATE.historyIdCounter++),
                timestamp: new Date().toISOString().replace('T', ' ').substring(0, 19),
                application: appName,
                soapAction: actionName,
                endpoint: endpoint,
                httpStatus: statusCode,
                statusText: statusText,
                ttfb: ttfb + ' ms',
                totalTime: totalTime + ' ms',
                contentType: contentType,
                contentLength: contentLength,
                responseHeaders: [],
                responseBody: sampleResponse,
                faultCode: null,
                faultString: null,
                faultActor: null,
                faultDetail: null,
                assertions: assertions
            });

            renderHistoryTable();
            updateCounts();
            showActionToast('SOAP call completed successfully.', 'success');
        }, 800 + Math.round(Math.random() * 400));
    }

    /* ─── App CRUD ─── */
    function addApp() {
        var name = prompt('Enter application name:');
        if (!name) return;
        var wsdl = prompt('Enter WSDL URL:');
        if (!wsdl) return;
        STATE.apps.push({ name: name, wsdlUrl: wsdl, description: '', registeredDate: new Date().toISOString().split('T')[0], soapActions: [] });
        renderSoapAppsTable();
        populateAppDropdowns();
        updateCounts();
        showActionToast('Application "' + name + '" added.', 'success');
    }

    function editApp(idx) {
        var app = STATE.apps[idx];
        if (!app) return;
        var name = prompt('Application name:', app.name);
        if (!name) return;
        var wsdl = prompt('WSDL URL:', app.wsdlUrl);
        if (!wsdl) return;
        app.name = name;
        app.wsdlUrl = wsdl;
        renderSoapAppsTable();
        populateAppDropdowns();
        showActionToast('Application updated.', 'success');
    }

    function deleteApp(idx) {
        var app = STATE.apps[idx];
        if (!app) return;
        if (!confirm('Delete application "' + app.name + '"?')) return;
        STATE.apps.splice(idx, 1);
        renderSoapAppsTable();
        populateAppDropdowns();
        updateCounts();
        showActionToast('Application deleted.', 'secondary');
    }

    /* ─── Suite CRUD ─── */
    function addSuite() {
        var name = prompt('Enter suite name:');
        if (!name) return;
        var app = prompt('Application name:');
        if (!app) return;
        var desc = prompt('Description (optional):') || '';
        STATE.suites.push({ id: 'suite-' + (STATE.suiteIdCounter++), name: name, app: app, description: desc, cases: 0 });
        renderSuitesTable();
        updateCounts();
        showActionToast('Suite "' + name + '" added.', 'success');
    }

    function editSuite(idx) {
        var suite = STATE.suites[idx];
        if (!suite) return;
        var name = prompt('Suite name:', suite.name);
        if (!name) return;
        suite.name = name;
        suite.description = prompt('Description:', suite.description) || suite.description;
        renderSuitesTable();
        showActionToast('Suite updated.', 'success');
    }

    function deleteSuite(idx) {
        var suite = STATE.suites[idx];
        if (!suite) return;
        if (!confirm('Delete suite "' + suite.name + '"?')) return;
        STATE.suites.splice(idx, 1);
        renderSuitesTable();
        updateCounts();
        showActionToast('Suite deleted.', 'secondary');
    }

    function runSuite(idx) {
        var suite = STATE.suites[idx];
        if (!suite) return;
        showActionToast('Running suite "' + suite.name + '"...', 'info');
        setTimeout(function () {
            showActionToast('Suite "' + suite.name + '" passed all tests.', 'success');
        }, 1500);
    }

    /* ─── WSDL ─── */
    function updateWsdl() {
        var sel = document.getElementById('soapWsdlApplication');
        var url = document.getElementById('soapWsdlUrl');
        var preview = document.getElementById('soapWsdlPreview');
        if (!sel || !url || !preview) return;
        var appName = sel.value;
        if (!appName) { showActionToast('Please select an application.', 'warning'); return; }
        var app = STATE.apps.find(function (a) { return a.name === appName; });
        if (app) url.value = app.wsdlUrl || url.value;
        setEditorContent(preview, '<?xml version="1.0" encoding="utf-8"?>\n' +
            '<wsdl:definitions xmlns:wsdl="http://schemas.xmlsoap.org/wsdl/"\n' +
            '                  xmlns:soap="http://schemas.xmlsoap.org/wsdl/soap/"\n' +
            '                  targetNamespace="http://tempuri.org/">\n' +
            '  <!-- WSDL for ' + escapeHtml(appName) + ' -->\n' +
            '  <wsdl:types>\n' +
            '    <schema targetNamespace="http://tempuri.org/">\n' +
            '      <element name="' + escapeHtml(appName.replace(/\\s/g, '')) + 'Request" type="xsd:string"/>\n' +
            '      <element name="' + escapeHtml(appName.replace(/\\s/g, '')) + 'Response" type="xsd:string"/>\n' +
            '    </schema>\n' +
            '  </wsdl:types>\n' +
            '</wsdl:definitions>');
        showActionToast('WSDL updated for ' + appName, 'success');
    }

    function saveWsdl() {
        showActionToast('WSDL configuration saved.', 'success');
    }

    /* ─── History ─── */
    function viewHistory(idx) {
        var entry = STATE.history[idx];
        if (!entry) return;
        var modalHtml = '<div class="modal fade" id="soapHistoryDetailModal" tabindex="-1">' +
            '<div class="modal-dialog modal-lg modal-dialog-scrollable">' +
            '<div class="modal-content">' +
            '<div class="modal-header">' +
            '<h5 class="modal-title"><i class="fa-solid fa-receipt me-2"></i>Execution Detail</h5>' +
            '<button type="button" class="btn-close" data-bs-dismiss="modal"></button>' +
            '</div>' +
            '<div class="modal-body">' +
            '<div class="row g-2 mb-3">' +
            '<div class="col-md-4"><strong>Timestamp:</strong><br><span class="fs-7">' + escapeHtml(entry.timestamp) + '</span></div>' +
            '<div class="col-md-4"><strong>Application:</strong><br><span class="fs-7">' + escapeHtml(entry.application) + '</span></div>' +
            '<div class="col-md-4"><strong>SOAPAction:</strong><br><code class="fs-8">' + escapeHtml(entry.soapAction) + '</code></div>' +
            '<div class="col-12"><strong>Endpoint:</strong><br><code class="fs-8">' + escapeHtml(entry.endpoint) + '</code></div>' +
            '</div>' +
            '<h6 class="fw-bold">Response Body</h6>' +
            '<pre class="border rounded p-3 font-monospace" style="max-height:300px;overflow:auto;font-size:0.78rem;background:var(--ux-bg-secondary);">' + escapeHtml(entry.responseBody || 'N/A') + '</pre>' +
            '</div>' +
            '<div class="modal-footer">' +
            '<button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Close</button>' +
            '</div>' +
            '</div>' +
            '</div>' +
            '</div>';

        var existing = document.getElementById('soapHistoryDetailModal');
        if (existing) existing.remove();
        document.body.insertAdjacentHTML('beforeend', modalHtml);
        var modal = new bootstrap.Modal(document.getElementById('soapHistoryDetailModal'));
        modal.show();
        document.getElementById('soapHistoryDetailModal').addEventListener('hidden.bs.modal', function () {
            this.remove();
        });
    }

    function clearHistory() {
        if (!confirm('Clear all execution history records?')) return;
        STATE.history = [];
        renderHistoryTable();
        updateCounts();
        showActionToast('History cleared.', 'secondary');
    }

    /* ─── Utility ─── */
    function clearForm() {
        document.getElementById('soapExecApplication').value = '';
        document.getElementById('soapExecSoapAction').innerHTML = '<option value="">-- Select Action --</option>';
        document.getElementById('soapExecEndpointUrl').value = '';
        setEditorContent('soapExecBody', '');
        setEditorContent('soapResponseBody', '');
        document.getElementById('soapExecHeadersContainer').innerHTML = '';
        document.getElementById('soapResponsePanel').style.display = 'none';
    }

    function addHeaderRow() {
        var container = document.getElementById('soapExecHeadersContainer');
        if (!container) return;
        var row = document.createElement('div');
        row.className = 'soap-exec-header-row row g-2 mb-1';
        row.innerHTML = '<div class="col-5"><input type="text" class="form-control form-control-sm soap-header-name" placeholder="Header Name"></div>' +
            '<div class="col-5"><input type="text" class="form-control form-control-sm soap-header-value" placeholder="Header Value"></div>' +
            '<div class="col-2"><button class="btn btn-sm btn-outline-danger w-100" onclick="this.closest(\'.soap-exec-header-row\').remove()"><i class="fa-solid fa-trash-can"></i></button></div>';
        container.appendChild(row);
    }

    function escapeHtml(value) {
        return String(value ?? '')
            .replace(/&/g, '&amp;').replace(/</g, '&lt;')
            .replace(/>/g, '&gt;').replace(/"/g, '&quot;')
            .replace(/'/g, '&#39;');
    }

    /* ─── Public API ─── */
    window.SOAP_MODULE = {
        init: init,
        execute: executeSoapCall,
        clearForm: clearForm,
        addHeaderRow: addHeaderRow,
        addApp: addApp,
        editApp: editApp,
        deleteApp: deleteApp,
        addSuite: addSuite,
        editSuite: editSuite,
        deleteSuite: deleteSuite,
        runSuite: runSuite,
        updateWsdl: updateWsdl,
        saveWsdl: saveWsdl,
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
