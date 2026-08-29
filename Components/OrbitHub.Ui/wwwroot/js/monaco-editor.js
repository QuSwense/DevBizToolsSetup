// Service Hub Enterprise — Monaco Editor integration module
// Ships with the OrbitHub.Ui component library.
// Provides parameterized editor/diff-editor creation, stats, and lifecycle management.
// Loaded via CDN AMD loader (monaco-editor@0.52.0).
//
(function () {
    'use strict';

    const MONACO_BASE = 'https://cdn.jsdelivr.net/npm/monaco-editor@0.52.0/min/vs';
    let monacoReady = false;
    let pendingQueue = [];

    function onMonacoReady(callback) {
        // Use shared global queue so both scripts get notified
        if (window.__monacoReady) { callback(); return; }
        if (!window.__monacoReadyCallbacks) window.__monacoReadyCallbacks = [];
        window.__monacoReadyCallbacks.push(callback);
    }

    function firePending() {
        window.__monacoReady = true;
        var q = window.__monacoReadyCallbacks || [];
        window.__monacoReadyCallbacks = [];
        for (var i = 0; i < q.length; i++) q[i]();
    }

    function bootstrapMonaco() {
        if (document.querySelector('script[data-monaco-loader]')) return;
        var loader = document.createElement('script');
        loader.setAttribute('data-monaco-loader', '1');
        loader.src = MONACO_BASE + '/loader.js';
        loader.onload = function () {
            require.config({ paths: { vs: MONACO_BASE } });
            require(['vs/editor/editor.main'], function () {
                firePending();
            });
        };
        loader.onerror = function () {
            console.error('[monaco-editor] Failed to load Monaco Editor from CDN');
        };
        document.head.appendChild(loader);
    }

    function normalizeFontFamily(fontFamily) {
        var raw = (fontFamily || '').toString().trim();
        if (!raw) {
            return "'JetBrains Mono', 'Menlo', 'Consolas', monospace";
        }

        var known = {
            'jetbrains mono': "'JetBrains Mono', 'Menlo', 'Consolas', monospace",
            'fira code': "'Fira Code', 'JetBrains Mono', 'Menlo', monospace",
            'cascadia code': "'Cascadia Code', 'Consolas', 'Menlo', monospace",
            'menlo': "'Menlo', 'Monaco', 'Consolas', monospace",
            'consolas': "'Consolas', 'Menlo', 'Monaco', monospace",
            'monaco': "'Monaco', 'Menlo', 'Consolas', monospace"
        };

        var mapped = known[raw.toLowerCase()];
        return mapped || raw;
    }

    function buildEditorOpts(content, opts) {
        opts = opts || {};
        return {
            value: content || '',
            language: opts.language || 'xml',
            readOnly: opts.readOnly || false,
            minimap: { enabled: opts.minimap === true },
            scrollBeyondLastLine: false,
            lineNumbers: opts.lineNumbers !== false ? 'on' : 'off',
            renderLineHighlight: opts.renderLineHighlight || 'line',
            fontSize: opts.fontSize || 11,
            fontFamily: normalizeFontFamily(opts.fontFamily),
            wordWrap: opts.wordWrap !== false ? 'on' : 'off',
            automaticLayout: true,
            theme: opts.theme || 'vs-dark',
            padding: { top: opts.paddingTop || 8, bottom: opts.paddingBottom || 8 },
            bracketPairColorization: { enabled: opts.bracketPairColorization !== false },
            autoClosingBrackets: opts.autoClosingBrackets || 'always',
            autoClosingQuotes: opts.autoClosingQuotes || 'always',
            formatOnPaste: opts.formatOnPaste !== false,
            tabSize: opts.tabSize || 2,
            folding: opts.folding !== false,
            glyphMargin: opts.glyphMargin === true,
            snippetSuggestions: opts.snippetSuggestions || 'inline',
            quickSuggestions: opts.quickSuggestions !== false,
            selectionHighlight: true,
            occurrencesHighlight: true,
            renderWhitespace: opts.renderWhitespace || 'selection',
            smoothScrolling: true,
            cursorBlinking: 'smooth',
            cursorSmoothCaretAnimation: 'on',
            links: true,
            contextmenu: true,
            mouseWheelZoom: opts.mouseWheelZoom === true,
            multiCursorModifier: 'alt',
            dragAndDrop: true,
            suggest: {
                showMethods: true,
                showFunctions: true,
                showConstructors: true,
                showFields: true,
                showVariables: true,
                showClasses: true,
                showStructs: true,
                showInterfaces: true,
                showModules: true,
                showProperties: true,
                showEvents: true,
                showOperators: true,
                showUnits: true,
                showValues: true,
                showConstants: true,
                showEnums: true,
                showEnumMembers: true,
                showKeywords: true,
                showWords: true,
                showColors: true,
                showFiles: true,
                showReferences: true,
                showSnippets: true
            }
        };
    }

    // ── Public API ──

    window.monacoEditor = {
        _editors: {},
        _searchState: {},

        /// Creates an editable/code Monaco editor with configurable options.
        /// containerId: DOM element id
        /// content: initial code content
        /// opts: { language, theme, readOnly, fontSize, fontFamily, wordWrap, lineNumbers, minimap, ... }
        /// dotNetRef: optional DotNetObjectReference for content change callback (must have OnMonacoContentChanged method)
        /// returns: Promise that resolves when the editor is created
        createEditor: function (containerId, content, opts, dotNetRef) {
            return new Promise(function (resolve) {
                onMonacoReady(function () {
                    var container = document.getElementById(containerId);
                    if (!container) { resolve(null); return; }

                    // Dispose existing
                    window.monacoEditor._disposeEditor(containerId);

                    var editor = monaco.editor.create(container, buildEditorOpts(content, opts));

                    // Listen for content changes - call back to .NET if reference provided
                    function publishState() {
                        if (dotNetRef && typeof dotNetRef.invokeMethodAsync === 'function') {
                            var stats = window.monacoEditor.getEditorStats(containerId);
                            dotNetRef.invokeMethodAsync('OnMonacoEditorStateChanged', stats);
                        }
                    }

                    if (dotNetRef && typeof dotNetRef.invokeMethodAsync === 'function') {
                        editor.getModel().onDidChangeContent(function () {
                            var value = editor.getValue();
                            dotNetRef.invokeMethodAsync('OnMonacoContentChanged', value);
                            publishState();
                        });

                        editor.onDidChangeCursorPosition(function () {
                            publishState();
                        });

                        editor.onDidChangeCursorSelection(function () {
                            publishState();
                        });

                        editor.onMouseMove(function () {
                            publishState();
                        });
                    }

                    window.monacoEditor._editors[containerId] = editor;
                    publishState();
                    resolve(editor);
                });
            });
        },

        /// Creates a side-by-side Monaco diff editor for comparing two versions.
        /// containerId: DOM element id
        /// originalContent: original/older version content
        /// modifiedContent: modified/newer version content
        /// opts: { language, theme, readOnly, fontSize, wordWrap, lineNumbers, minimap,
        ///        originalLabel, modifiedLabel, ignoreTrimWhitespace, ignoreCase }
        /// returns: Promise that resolves when the diff editor is created
        createDiffEditor: function (containerId, originalContent, modifiedContent, opts) {
            return new Promise(function (resolve) {
                onMonacoReady(function () {
                    var container = document.getElementById(containerId);
                    if (!container) { resolve(null); return; }

                    window.monacoEditor._disposeEditor(containerId);

                    opts = opts || {};
                    var lang = opts.language || 'xml';

                    var originalModel = monaco.editor.createModel(originalContent || '', lang);
                    var modifiedModel = monaco.editor.createModel(modifiedContent || '', lang);

                    var diffEditor = monaco.editor.createDiffEditor(container, {
                        enableSplitViewResizing: true,
                        renderSideBySide: opts.renderSideBySide !== false,
                        readOnly: opts.readOnly !== false,
                        ignoreTrimWhitespace: opts.ignoreTrimWhitespace === true,
                        renderIndicators: true,
                        enableCollapseWidget: true,
                        isInEmbeddedEditor: false,
                        automaticLayout: true,
                        fontSize: opts.fontSize || 11,
                        fontFamily: opts.fontFamily || "'JetBrains Mono', 'Menlo', 'Consolas', monospace",
                        wordWrap: opts.wordWrap !== false ? 'on' : 'off',
                        lineNumbers: opts.lineNumbers !== false ? 'on' : 'off',
                        theme: opts.theme || 'vs-dark',
                        minimap: { enabled: opts.minimap === true },
                        renderMarginRevertIcon: false,
                        diffCodeLens: false,
                        originalEditable: false,
                        hideUnchangedRegions: {
                            enabled: opts.hideUnchangedRegions === true,
                            revealLineCount: opts.revealLineCount || 20,
                            minimumLineCount: opts.minimumLineCount || 10
                        }
                    });

                    diffEditor.setModel({
                        original: originalModel,
                        modified: modifiedModel
                    });

                    window.monacoEditor._editors[containerId] = diffEditor;
                    resolve(diffEditor);
                });
            });
        },

        /// Disposes an editor/diff-editor by container id.
        disposeEditor: function (containerId) {
            window.monacoEditor._disposeEditor(containerId);
        },

        _disposeEditor: function (containerId) {
            var ed = window.monacoEditor._editors[containerId];
            if (ed) {
                try {
                    if (ed.getModel) {
                        var m = ed.getModel();
                        if (m) {
                            if (m.original) { try { m.original.dispose(); } catch (e) { /* ignore */ } }
                            if (m.modified) { try { m.modified.dispose(); } catch (e) { /* ignore */ } }
                        }
                    }
                    ed.dispose();
                } catch (e) {
                    console.warn('[monaco-editor] Error disposing editor:', e);
                }
                delete window.monacoEditor._editors[containerId];
            }

            delete window.monacoEditor._searchState[containerId];
        },

        /// Gets the current content from a regular editor (not diff).
        getEditorContent: function (containerId) {
            var ed = window.monacoEditor._editors[containerId];
            if (ed && ed.getValue) return ed.getValue();
            if (ed && ed.getModel && ed.getModel().getValue) return ed.getModel().getValue();
            return null;
        },

        /// Sets the content of a regular editor.
        setEditorContent: function (containerId, content) {
            var ed = window.monacoEditor._editors[containerId];
            if (ed && ed.getModel) {
                var model = ed.getModel();
                if (model && typeof model.setValue === 'function') {
                    model.setValue(content || '');
                }
            }
        },

        /// Sets the language of an existing editor.
        setEditorLanguage: function (containerId, language) {
            var ed = window.monacoEditor._editors[containerId];
            if (ed && ed.getModel) {
                var model = ed.getModel();
                if (model) {
                    monaco.editor.setModelLanguage(model, language === 'text' ? 'plaintext' : (language || 'xml'));
                }
            }
        },

        /// Sets the theme of all editors.
        setEditorTheme: function (theme) {
            monaco.editor.setTheme(theme || 'vs-dark');
        },

        /// Sets a single option on an editor (e.g. fontSize, wordWrap, readOnly).
        setEditorOption: function (containerId, key, value) {
            var ed = window.monacoEditor._editors[containerId];
            if (ed && ed.updateOptions) {
                var opt = {};
                if (key === 'wordWrap') {
                    opt.wordWrap = value ? 'on' : 'off';
                } else if (key === 'lineNumbers') {
                    opt.lineNumbers = value ? 'on' : 'off';
                } else if (key === 'minimap') {
                    opt.minimap = { enabled: value === true };
                } else if (key === 'fontFamily') {
                    opt.fontFamily = normalizeFontFamily(value);
                } else {
                    opt[key] = value;
                }
                ed.updateOptions(opt);

                if (key === 'fontFamily' && monaco.editor && monaco.editor.remeasureFonts) {
                    monaco.editor.remeasureFonts();
                    if (ed.layout) {
                        ed.layout();
                    }
                }
            }
        },

        /// Gets editor stats: lines, chars, cursor position, selection.
        getEditorStats: function (containerId) {
            var ed = window.monacoEditor._editors[containerId];
            if (!ed) return null;
            var model = ed.getModel ? ed.getModel() : null;
            if (!model) return null;
            var content = model.getValue() || '';
            var lines = content.split('\n');
            var selection = ed.getSelection ? ed.getSelection() : null;
            var cursor = ed.getPosition ? ed.getPosition() : null;
            var selectedRanges = ed.getSelections ? ed.getSelections() : null;
            var selectedChars = 0;
            if (selectedRanges) {
                for (var i = 0; i < selectedRanges.length; i++) {
                    var r = selectedRanges[i];
                    selectedChars += model.getValueInRange(r).length;
                }
            }
            return {
                totalLines: lines.length,
                nonEmptyLines: lines.filter(function (l) { return l.trim().length > 0; }).length,
                blankLines: lines.filter(function (l) { return l.trim().length === 0; }).length,
                totalChars: content.length,
                charsNoSpaces: content.replace(/\s/g, '').length,
                selectedChars: selectedChars,
                lineNumber: cursor ? cursor.lineNumber : 1,
                columnNumber: cursor ? cursor.column : 1,
                characterPosition: cursor ? model.getOffsetAt(cursor) : 0
            };
        },

        /// Gets diff-specific stats: additions, deletions, modifications, total differences.
        getDiffStats: function (containerId) {
            var ed = window.monacoEditor._editors[containerId];
            if (!ed || !ed.getLineChanges) return null;
            var changes = ed.getLineChanges() || [];
            var additions = 0, deletions = 0, modifications = 0;
            for (var i = 0; i < changes.length; i++) {
                var c = changes[i];
                if (c.modifiedEndLineNumber - c.modifiedStartLineNumber >= 0 &&
                    c.originalEndLineNumber - c.originalStartLineNumber === 0) {
                    additions++;
                } else if (c.originalEndLineNumber - c.originalStartLineNumber >= 0 &&
                    c.modifiedEndLineNumber - c.modifiedStartLineNumber === 0) {
                    deletions++;
                } else {
                    modifications++;
                }
            }
            return {
                totalDifferences: changes.length,
                additions: additions,
                deletions: deletions,
                modifications: modifications,
                changes: changes
            };
        },

        /// Executes a Monaco command by ID (e.g. 'editor.action.formatDocument').
        executeCommand: function (containerId, commandId) {
            var ed = window.monacoEditor._editors[containerId];
            if (!ed) return;

            if (commandId === 'undo' || commandId === 'redo') {
                ed.trigger('toolbar', commandId, null);
                return;
            }

            if (ed.getAction) {
                var action = ed.getAction(commandId);
                if (action && action.run) {
                    action.run();
                    return;
                }
            }

            if (ed.trigger) {
                ed.trigger('toolbar', commandId, null);
            }
        },

        /// Searches for query in the current editor and jumps to the next match.
        searchInEditor: function (containerId, query) {
            var ed = window.monacoEditor._editors[containerId];
            if (!ed || !query) return false;

            var model = ed.getModel ? ed.getModel() : null;
            if (!model || !model.findMatches) return false;

            var state = window.monacoEditor._searchState[containerId] || { query: '', index: -1, matches: [] };
            if (state.query !== query) {
                state.query = query;
                state.matches = model.findMatches(query, true, false, false, null, true);
                state.index = -1;
            }

            if (!state.matches || state.matches.length === 0) {
                window.monacoEditor._searchState[containerId] = state;
                return false;
            }

            state.index = (state.index + 1) % state.matches.length;
            var range = state.matches[state.index].range;
            ed.setSelection(range);
            ed.revealRangeInCenter(range);
            ed.focus();

            window.monacoEditor._searchState[containerId] = state;
            return true;
        },

        /// Moves cursor to the given line number and reveals it.
        goToLine: function (containerId, lineNumber) {
            var ed = window.monacoEditor._editors[containerId];
            if (!ed || !lineNumber || lineNumber < 1) return;

            var model = ed.getModel ? ed.getModel() : null;
            if (!model || !model.getLineCount) return;

            var maxLine = model.getLineCount();
            var targetLine = Math.min(Math.max(1, lineNumber), maxLine);
            var pos = { lineNumber: targetLine, column: 1 };

            ed.setPosition(pos);
            ed.revealPositionInCenter(pos);
            ed.focus();
        },

        /// Focuses the editor.
        focusEditor: function (containerId) {
            var ed = window.monacoEditor._editors[containerId];
            if (ed && ed.focus) ed.focus();
        },

        /// Navigates to the next or previous diff in a diff editor.
        navigateDiff: function (containerId, direction) {
            var ed = window.monacoEditor._editors[containerId];
            if (!ed) return;
            if (direction === 'next') {
                ed.revealNextChange();
            } else if (direction === 'previous') {
                ed.revealPreviousChange();
            }
        },

        /// Swaps original and modified in a diff editor (re-creates the diff).
        swapDiff: function (containerId) {
            var ed = window.monacoEditor._editors[containerId];
            if (!ed) return;
            var m = ed.getModel();
            if (!m) return;
            var origContent = m.original ? m.original.getValue() : '';
            var modContent = m.modified ? m.modified.getValue() : '';
            // Re-create with swapped content
            var opts = {
                language: m.original && m.original.getLanguageId ? m.original.getLanguageId() : 'xml',
                theme: ed.getOption ? ed.getOption(monaco.editor.EditorOption.theme) : 'vs-dark',
                fontSize: ed.getOption ? ed.getOption(monaco.editor.EditorOption.fontSize) : 11,
                wordWrap: ed.getRawOptions ? ed.getRawOptions().wordWrap : 'on',
                lineNumbers: ed.getRawOptions ? ed.getRawOptions().lineNumbers : 'on',
                renderSideBySide: true,
                readOnly: true,
                minimap: false
            };
            window.monacoEditor._disposeEditor(containerId);
            window.monacoEditor.createDiffEditor(containerId, modContent, origContent, opts);
        },

        /// Toggles diff editor between side-by-side and inline view.
        toggleDiffViewMode: function (containerId, sideBySide) {
            var ed = window.monacoEditor._editors[containerId];
            if (ed && ed.updateOptions) {
                ed.updateOptions({ renderSideBySide: sideBySide });
            }
        },

        /// Resizes all editors (call when container becomes visible or window resizes).
        resizeAll: function () {
            for (var key in window.monacoEditor._editors) {
                var ed = window.monacoEditor._editors[key];
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
        if (window.monacoEditor) window.monacoEditor.resizeAll();
    });
})();