// Service Hub Enterprise — Monaco Editor integration for WSDL Sync
// Provides XML-aware read-only editors and side-by-side diff views
// using Monaco Editor loaded from CDN.
//
(function () {
    'use strict';

    const MONACO_BASE = 'https://cdn.jsdelivr.net/npm/monaco-editor@0.52.0/min/vs';
    let monacoReady = false;
    let pendingQueue = [];

    function onMonacoReady(callback) {
        if (monacoReady) { callback(); return; }
        pendingQueue.push(callback);
    }

    function firePending() {
        monacoReady = true;
        var q = pendingQueue;
        pendingQueue = [];
        for (var i = 0; i < q.length; i++) q[i]();
    }

    // Load Monaco AMD loader, then require the editor module
    function bootstrapMonaco() {
        if (document.querySelector('script[data-monaco-loader]')) return;
        var loader = document.createElement('script');
        loader.setAttribute('data-monaco-loader', '1');
        loader.src = MONACO_BASE + '/loader.js';
        loader.onload = function () {
            require.config({ paths: { vs: MONACO_BASE } });
            require(['vs/editor/editor.main'], function () {
                // Define XML language tokens for syntax highlighting (Monaco already has XML built-in)
                firePending();
            });
        };
        loader.onerror = function () {
            console.error('[wsdl-monaco] Failed to load Monaco Editor from CDN');
        };
        document.head.appendChild(loader);
    }

    // ── Public API ──

    window.wsdlMonaco = {
        _editors: {},

        /// Creates a read-only Monaco editor for displaying WSDL/XML content.
        /// containerId: DOM element id
        /// content: XML string content
        /// returns: Promise that resolves when the editor is created
        createEditor: function (containerId, content) {
            return new Promise(function (resolve) {
                onMonacoReady(function () {
                    var container = document.getElementById(containerId);
                    if (!container) { resolve(null); return; }

                    // Dispose existing
                    if (window.wsdlMonaco._editors[containerId]) {
                        window.wsdlMonaco._editors[containerId].dispose();
                    }

                    var editor = monaco.editor.create(container, {
                        value: content || '',
                        language: 'xml',
                        readOnly: true,
                        minimap: { enabled: false },
                        scrollBeyondLastLine: false,
                        lineNumbers: 'on',
                        renderLineHighlight: 'none',
                        fontSize: 11,
                        fontFamily: "'JetBrains Mono', 'Menlo', 'Consolas', monospace",
                        wordWrap: 'on',
                        automaticLayout: true,
                        theme: 'vs-dark',
                        padding: { top: 8, bottom: 8 }
                    });

                    window.wsdlMonaco._editors[containerId] = editor;
                    resolve(editor);
                });
            });
        },

        /// Creates a side-by-side Monaco diff editor for comparing two WSDL versions.
        /// containerId: DOM element id
        /// originalContent: previous WSDL version content
        /// modifiedContent: current WSDL version content
        /// returns: Promise that resolves when the diff editor is created
        createDiffEditor: function (containerId, originalContent, modifiedContent) {
            return new Promise(function (resolve) {
                onMonacoReady(function () {
                    var container = document.getElementById(containerId);
                    if (!container) { resolve(null); return; }

                    // Dispose existing
                    if (window.wsdlMonaco._editors[containerId]) {
                        window.wsdlMonaco._editors[containerId].dispose();
                    }

                    var originalModel = monaco.editor.createModel(originalContent || '', 'xml');
                    var modifiedModel = monaco.editor.createModel(modifiedContent || '', 'xml');

                    var diffEditor = monaco.editor.createDiffEditor(container, {
                        readOnly: true,
                        minimap: { enabled: false },
                        scrollBeyondLastLine: false,
                        fontSize: 11,
                        fontFamily: "'JetBrains Mono', 'Menlo', 'Consolas', monospace",
                        wordWrap: 'on',
                        automaticLayout: true,
                        theme: 'vs-dark',
                        renderSideBySide: true,
                        enableSplitViewResizing: true,
                        padding: { top: 8, bottom: 8 },
                        renderOverviewRuler: false
                    });

                    diffEditor.setModel({
                        original: originalModel,
                        modified: modifiedModel
                    });

                    window.wsdlMonaco._editors[containerId] = diffEditor;
                    resolve(diffEditor);
                });
            });
        },

        /// Disposes an editor/diff-editor by container id.
        disposeEditor: function (containerId) {
            var ed = window.wsdlMonaco._editors[containerId];
            if (ed) {
                // For diff editors, dispose the models too
                if (ed.getModel) {
                    var m = ed.getModel();
                    if (m) {
                        if (m.original) m.original.dispose();
                        if (m.modified) m.modified.dispose();
                    }
                }
                ed.dispose();
                delete window.wsdlMonaco._editors[containerId];
            }
        },

        /// Updates the content of an existing regular editor (not diff).
        updateEditorContent: function (containerId, content) {
            var ed = window.wsdlMonaco._editors[containerId];
            if (ed && ed.getModel) {
                var model = ed.getModel();
                if (model && typeof model.setValue === 'function') {
                    model.setValue(content || '');
                }
            }
        },

        /// Generates an inline XML diff summary comparing two WSDL/XML strings.
        /// Renders a colour-coded side-by-side view with added/removed/unchanged lines.
        /// containerId: DOM element id
        /// originalContent: previous/older XML
        /// modifiedContent: newer/current XML
        /// labelOriginal: label for the left pane (e.g. version name)
        /// labelModified: label for the right pane
        compareXml: function (containerId, originalContent, modifiedContent, labelOriginal, labelModified) {
            return new Promise(function (resolve) {
                var container = document.getElementById(containerId);
                if (!container) { resolve(null); return; }

                // Clear previous content
                container.innerHTML = '';

                // Normalise both strings for line-by-line diff
                var origLines = (originalContent || '').split('\n');
                var modLines = (modifiedContent || '').split('\n');

                // Simple LCS-based word-level diff display
                var html = '';
                html += '<div style="display:grid;grid-template-columns:1fr 1fr;gap:0;font-family:\'JetBrains Mono\',\'Menlo\',\'Consolas\',monospace;font-size:11px;line-height:1.5;height:100%">';

                // Left pane — original
                html += '<div style="overflow:auto;border-right:1px solid var(--sh-border);background:#1e1e1e">';
                html += '<div style="padding:6px 10px;background:#2d2d2d;border-bottom:1px solid #3c3c3c;font-size:11px;color:#9d9d9d;font-weight:600;position:sticky;top:0;z-index:1">';
                html += (labelOriginal || 'Original') + '</div>';
                html += '<div style="padding:4px 0">';

                for (var i = 0; i < origLines.length; i++) {
                    var line = escHtml(origLines[i]);
                    var lineNum = (i + 1).toString().padStart(4, ' ');
                    var removed = (i < modLines.length && origLines[i] !== modLines[i]) || i >= modLines.length;
                    // Check if this line exists in modified
                    var inModified = modLines.indexOf(origLines[i]) !== -1;
                    if (!inModified && origLines[i].trim() !== '') {
                        html += '<div style="padding:0 10px;background:rgba(220,53,69,0.12);color:#f08080;display:flex">';
                        html += '<span style="color:#555;width:36px;flex-shrink:0;user-select:none">' + lineNum + '</span>';
                        html += '<span style="flex:1">' + line + '</span></div>';
                    } else {
                        html += '<div style="padding:0 10px;color:#c0c0c0;display:flex">';
                        html += '<span style="color:#555;width:36px;flex-shrink:0;user-select:none">' + lineNum + '</span>';
                        html += '<span style="flex:1">' + line + '</span></div>';
                    }
                }
                html += '</div></div>';

                // Right pane — modified
                html += '<div style="overflow:auto;background:#1e1e1e">';
                html += '<div style="padding:6px 10px;background:#2d2d2d;border-bottom:1px solid #3c3c3c;font-size:11px;color:#9d9d9d;font-weight:600;position:sticky;top:0;z-index:1">';
                html += (labelModified || 'Modified') + '</div>';
                html += '<div style="padding:4px 0">';

                for (var j = 0; j < modLines.length; j++) {
                    var line2 = escHtml(modLines[j]);
                    var lineNum2 = (j + 1).toString().padStart(4, ' ');
                    var inOriginal = origLines.indexOf(modLines[j]) !== -1;
                    if (!inOriginal && modLines[j].trim() !== '') {
                        html += '<div style="padding:0 10px;background:rgba(40,167,69,0.12);color:#7dcea0;display:flex">';
                        html += '<span style="color:#555;width:36px;flex-shrink:0;user-select:none">' + lineNum2 + '</span>';
                        html += '<span style="flex:1">' + line2 + '</span></div>';
                    } else {
                        html += '<div style="padding:0 10px;color:#c0c0c0;display:flex">';
                        html += '<span style="color:#555;width:36px;flex-shrink:0;user-select:none">' + lineNum2 + '</span>';
                        html += '<span style="flex:1">' + line2 + '</span></div>';
                    }
                }
                html += '</div></div>';
                html += '</div>';

                container.innerHTML = html;
                resolve(container);
            });
        },

        /// Creates an editable Monaco editor for XML editing (used by Templates editor).
        /// containerId: DOM element id
        /// content: initial XML string content
        /// dotNetRef: optional DotNetObjectReference for content change callback (must have OnMonacoContentChanged method)
        /// returns: Promise that resolves when the editor is created
        createXmlEditor: function (containerId, content, dotNetRef) {
            return new Promise(function (resolve) {
                onMonacoReady(function () {
                    var container = document.getElementById(containerId);
                    if (!container) { resolve(null); return; }

                    // Dispose existing
                    if (window.wsdlMonaco._editors[containerId]) {
                        window.wsdlMonaco._editors[containerId].dispose();
                    }

                    var editor = monaco.editor.create(container, {
                        value: content || '',
                        language: 'xml',
                        readOnly: false,
                        minimap: { enabled: false },
                        scrollBeyondLastLine: false,
                        lineNumbers: 'on',
                        renderLineHighlight: 'line',
                        fontSize: 11,
                        fontFamily: "'JetBrains Mono', 'Menlo', 'Consolas', monospace",
                        wordWrap: 'on',
                        automaticLayout: true,
                        theme: 'vs-dark',
                        padding: { top: 8, bottom: 8 },
                        bracketPairColorization: { enabled: true },
                        autoClosingBrackets: 'always',
                        autoClosingQuotes: 'always',
                        formatOnPaste: true,
                        tabSize: 2
                    });

                    // Listen for content changes - call back to .NET if reference provided
                    if (dotNetRef && typeof dotNetRef.invokeMethodAsync === 'function') {
                        editor.getModel().onDidChangeContent(function () {
                            var value = editor.getValue();
                            dotNetRef.invokeMethodAsync('OnMonacoContentChanged', value);
                        });
                    }

                    window.wsdlMonaco._editors[containerId] = editor;
                    resolve(editor);
                });
            });
        },

        /// Gets the current content from an editor by container id.
        getEditorContent: function (containerId) {
            var ed = window.wsdlMonaco._editors[containerId];
            if (ed && ed.getValue) return ed.getValue();
            if (ed && ed.getModel && ed.getModel().getValue) return ed.getModel().getValue();
            return null;
        },

        /// Resizes all editors (call when container becomes visible or window resizes)
        resizeAll: function () {
            for (var key in window.wsdlMonaco._editors) {
                var ed = window.wsdlMonaco._editors[key];
                if (ed && ed.layout) ed.layout();
            }
        }
    };

    // Helper: escape HTML entities
    function escHtml(str) {
        if (!str) return '';
        return str.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
    }

    // Auto-bootstrap on script load
    bootstrapMonaco();

    // Resize editors when window resizes
    window.addEventListener('resize', function () {
        if (window.wsdlMonaco) window.wsdlMonaco.resizeAll();
    });

})();
