/**
 * DevBizToolsSuite - PDF Viewer & Artifact Storage Module
 * Handles artifact list rendering, zoom/page controls, and mock PDF viewing.
 */
(function () {
    'use strict';

    /* ─── Module State ─── */
    const STATE = {
        artifacts: [],
        currentIndex: -1,
        zoomLevel: 100,
        currentPage: 1,
        totalPages: 1
    };

    /* ─── Initialization ─── */
    function init() {
        if (!document.getElementById('pdfArtifactList')) {
            setTimeout(init, 50);
            return;
        }

        loadArtifacts();
        renderArtifactList();
        updateFileCount();
        bindControls();
        initializeTooltips();
    }

    /* ─── Sample Artifacts ─── */
    function loadArtifacts() {
        STATE.artifacts = [
            { name: 'Q3_Financial_Report.pdf', size: '2.4 MB', uploader: 'jane.smith', pages: 12 },
            { name: 'API_Specification_v3.pdf', size: '1.1 MB', uploader: 'john.doe', pages: 8 },
            { name: 'System_Architecture_Diagram.pdf', size: '4.7 MB', uploader: 'admin', pages: 5 },
            { name: 'Deployment_Playbook_2026.pdf', size: '0.8 MB', uploader: 'jane.smith', pages: 3 },
            { name: 'Security_Audit_Results.pdf', size: '3.2 MB', uploader: 'admin', pages: 15 },
            { name: 'Network_Topology_Overview.pdf', size: '2.9 MB', uploader: 'john.doe', pages: 6 }
        ];
        STATE.totalPages = 1;
    }

    /* ─── Render Artifact List ─── */
    function renderArtifactList() {
        var list = document.getElementById('pdfArtifactList');
        if (!list) return;

        list.innerHTML = STATE.artifacts.map(function (art, idx) {
            var activeClass = idx === STATE.currentIndex ? ' active' : '';
            return '<button type="button" class="list-group-item list-group-item-action d-flex align-items-center gap-3' + activeClass + '" data-artifact-index="' + idx + '">' +
                '<i class="fa-regular fa-file-pdf fa-xl" style="color:var(--ux-danger);"></i>' +
                '<div class="flex-grow-1 min-width-0">' +
                '<div class="fw-semibold text-truncate">' + escapeHtml(art.name) + '</div>' +
                '<div class="fs-7 text-muted">' + escapeHtml(art.size) + ' &middot; by ' + escapeHtml(art.uploader) + '</div>' +
                '</div>' +
                '<span class="badge bg-light text-dark border fs-8">' + art.pages + ' pgs</span>' +
                '</button>';
        }).join('');

        // Click handler
        list.querySelectorAll('[data-artifact-index]').forEach(function (btn) {
            btn.addEventListener('click', function () {
                var idx = parseInt(this.dataset.artifactIndex, 10);
                selectArtifact(idx);
            });
        });
    }

    /* ─── Select Artifact ─── */
    function selectArtifact(idx) {
        if (idx < 0 || idx >= STATE.artifacts.length) return;
        STATE.currentIndex = idx;
        STATE.currentPage = 1;

        var art = STATE.artifacts[idx];
        STATE.totalPages = art.pages || 1;

        // Update active state
        document.querySelectorAll('#pdfArtifactList .list-group-item').forEach(function (el, i) {
            el.classList.toggle('active', i === idx);
        });

        // Show viewer mock
        var placeholder = document.getElementById('pdfViewerPlaceholder');
        var canvas = document.getElementById('pdfViewerCanvas');
        if (placeholder) placeholder.classList.add('d-none');
        if (canvas) canvas.classList.remove('d-none');

        // Update mock content
        var mockTitle = document.getElementById('pdfMockTitle');
        var mockPages = document.getElementById('pdfMockPages');
        var mockContent = document.getElementById('pdfMockContent');
        if (mockTitle) mockTitle.textContent = art.name;
        if (mockPages) mockPages.textContent = 'Page ' + STATE.currentPage + ' of ' + STATE.totalPages;
        if (mockContent) {
            mockContent.textContent = 'Displaying page ' + STATE.currentPage + ' of "' + art.name + '". Use the navigation controls above to browse pages. This is a simulated PDF preview.';
        }

        updatePageInfo();
        updateZoomLevel();
        updateFileCount();
        showActionToast('Opened: ' + art.name, 'info');
    }

    /* ─── Controls ─── */
    function bindControls() {
        document.getElementById('pdfZoomIn')?.addEventListener('click', function () {
            STATE.zoomLevel = Math.min(200, STATE.zoomLevel + 10);
            updateZoomLevel();
        });

        document.getElementById('pdfZoomOut')?.addEventListener('click', function () {
            STATE.zoomLevel = Math.max(50, STATE.zoomLevel - 10);
            updateZoomLevel();
        });

        document.getElementById('pdfPrevPage')?.addEventListener('click', function () {
            if (STATE.currentPage > 1) {
                STATE.currentPage--;
                updatePageContent();
                updatePageInfo();
            }
        });

        document.getElementById('pdfNextPage')?.addEventListener('click', function () {
            if (STATE.currentPage < STATE.totalPages) {
                STATE.currentPage++;
                updatePageContent();
                updatePageInfo();
            }
        });

        document.getElementById('pdfDownload')?.addEventListener('click', function () {
            if (STATE.currentIndex < 0) {
                showActionToast('No document selected.', 'warning');
                return;
            }
            showActionToast('Downloading ' + STATE.artifacts[STATE.currentIndex].name + '...', 'success');
        });
    }

    function updateZoomLevel() {
        var el = document.getElementById('pdfZoomLevel');
        if (el) el.textContent = STATE.zoomLevel + '%';
    }

    function updatePageInfo() {
        var el = document.getElementById('pdfPageInfo');
        if (el) el.textContent = STATE.currentPage + ' / ' + STATE.totalPages;
    }

    function updatePageContent() {
        var mockContent = document.getElementById('pdfMockContent');
        var mockPages = document.getElementById('pdfMockPages');
        if (mockContent) {
            mockContent.textContent = 'Displaying page ' + STATE.currentPage + ' of "' + (STATE.artifacts[STATE.currentIndex]?.name || 'Document') + '". Content for page ' + STATE.currentPage + '.';
        }
        if (mockPages && STATE.artifacts[STATE.currentIndex]) {
            mockPages.textContent = 'Page ' + STATE.currentPage + ' of ' + STATE.artifacts[STATE.currentIndex].pages;
        }
    }

    /* ─── Utility ─── */
    function updateFileCount() {
        var el = document.getElementById('pdfFileCount');
        if (el) el.textContent = STATE.artifacts.length + ' files';
    }

    function escapeHtml(value) {
        return String(value ?? '')
            .replace(/&/g, '&amp;').replace(/</g, '&lt;')
            .replace(/>/g, '&gt;').replace(/"/g, '&quot;')
            .replace(/'/g, '&#39;');
    }

    /* ─── Auto-init ─── */
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', init);
    } else {
        init();
    }

})();
