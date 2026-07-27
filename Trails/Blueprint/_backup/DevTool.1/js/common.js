/* ====================================================================
   DevBizToolsSuite - Common Router & Dynamic Module Loader
   ==================================================================== */

/**
 * Holds references to the current module's script and style elements
 * so they can be cleaned up when switching modules.
 */
const ModuleLoader = {
    currentModule: null,
    currentSubView: null,
    scriptElement: null,
    styleElement: document.getElementById('module-style'),

    /**
     * Load a module by folder name.
     * The folder must exist under modules/[folderName]/ and contain:
     *   - [folderName].html   (HTML snippet)
     *   - [folderName].js     (JS logic, IIFE-wrapped)
     *   - [folderName].css    (optional styles)
     *
     * @param {string} folderName - The module folder name (e.g. "dashboard", "soap-api-test")
     * @param {string} [subView]  - Optional sub-view identifier passed to the module's init
     */
    async loadModule(folderName, subView) {
        if (folderName === this.currentModule && subView === this.currentSubView) {
            return; // Already on this view
        }

        const appContent = document.getElementById('app-content');
        if (!appContent) return;

        // 1. Clean up previous module
        this.cleanupCurrentModule();

        // 2. Update current tracking
        this.currentModule = folderName;
        this.currentSubView = subView || null;

        // 3. Inject HTML
        try {
            const htmlResponse = await fetch(`modules/${folderName}/${folderName}.html`);
            if (!htmlResponse.ok) {
                throw new Error(`Failed to load module HTML: ${htmlResponse.status}`);
            }
            const html = await htmlResponse.text();
            appContent.innerHTML = html;

            // Remove fade-in class from parent if present, then re-add for animation
            appContent.classList.remove('tab-pane', 'fade', 'show', 'active');
            void appContent.offsetWidth; // Force reflow
        } catch (err) {
            console.error('[ModuleLoader] HTML load error:', err);
            appContent.innerHTML = `
                <div class="p-5 text-center">
                    <i class="fa-solid fa-triangle-exclamation text-danger fa-3x mb-3"></i>
                    <h5>Failed to load module: ${folderName}</h5>
                    <p class="text-muted">${err.message}</p>
                </div>
            `;
            return;
        }

        // 4. Swap module CSS
        if (this.styleElement) {
            const cssPath = `modules/${folderName}/${folderName}.css`;
            // Use a cache-busting query param to force reload if styles change
            this.styleElement.href = `${cssPath}?t=${Date.now()}`;
        }

        // 5. Load and execute module JS
        try {
            const jsResponse = await fetch(`modules/${folderName}/${folderName}.js`);
            if (!jsResponse.ok) {
                console.warn(`[ModuleLoader] No JS found for ${folderName}, skipping.`);
            } else {
                const jsCode = await jsResponse.text();
                const scriptId = 'module-script-' + folderName;

                // Remove any previous script with the same ID
                const oldScript = document.getElementById(scriptId);
                if (oldScript) oldScript.remove();

                const script = document.createElement('script');
                script.id = scriptId;
                script.type = 'text/javascript';
                script.textContent = jsCode;
                document.body.appendChild(script);
                this.scriptElement = script;
            }
        } catch (err) {
            console.warn('[ModuleLoader] JS load error:', err.message);
        }

        if (typeof initializeMonacoEditors === 'function') {
            initializeMonacoEditors();
        }

        // 6. Update sidebar active states
        this.updateSidebarState(folderName, subView);

        // 7. Update page title
        const moduleName = this.getModuleDisplayName(folderName);
        document.title = `DevBizToolsSuite - ${moduleName}`;
    },

    /**
     * Remove the current module's script and clean up state.
     */
    cleanupCurrentModule() {
        if (this.scriptElement) {
            this.scriptElement.remove();
            this.scriptElement = null;
        }

        if (Array.isArray(window.editorRegistry)) {
            window.editorRegistry.forEach(entry => {
                try {
                    entry.editor.dispose();
                } catch (err) {
                    console.warn('[ModuleLoader] Failed to dispose editor:', err);
                }
            });
            window.editorRegistry.length = 0;
        }

        window.activeEditor = null;
        // Note: We do NOT clear the style href — the next module will overwrite it.

        // Reset any module-specific globals that store state
        // (each module's IIFE should manage its own teardown if needed)
    },

    /**
     * Update the sidebar to highlight the active module and sub-view.
     */
    updateSidebarState(folderName, subView) {
        // Deactivate all nav links
        document.querySelectorAll('.nav-link-custom').forEach(el => el.classList.remove('active'));
        document.querySelectorAll('.submenu-item').forEach(el => el.classList.remove('active'));

        // Always collapse all submenus first
        document.querySelectorAll('.nav-submenu').forEach(el => el.classList.remove('expanded'));
        document.querySelectorAll('.nav-parent').forEach(el => el.classList.remove('expanded'));

        // Map folder name to nav id
        const navIdMap = {
            'dashboard': 'nav-dashboard',
            'soap-api-test': 'nav-soap',
            'rest-api-test': 'nav-rest',
            'pdf-viewer': 'nav-pdf',
            'health-checks': 'nav-health',
            'settings': 'nav-settings'
        };

        const navId = navIdMap[folderName];
        if (navId) {
            const navLink = document.getElementById(navId);
            if (navLink) {
                navLink.classList.add('active');

                // If this nav has a submenu, expand it
                const navGroup = navLink.closest('.nav-group');
                if (navGroup) {
                    const submenu = navGroup.querySelector('.nav-submenu');
                    const parent = navGroup.querySelector('.nav-parent');
                    if (submenu) submenu.classList.add('expanded');
                    if (parent) parent.classList.add('expanded');
                }
            }
        }

        // Highlight the specific sub-view if provided
        if (subView) {
            const submenuItem = document.querySelector(
                `.submenu-item[data-module="${folderName}"][data-subview="${subView}"]`
            );
            if (submenuItem) {
                submenuItem.classList.add('active');
            }
        } else {
            // If no sub-view, activate the first submenu item
            const firstSub = document.querySelector(
                `.submenu-item[data-module="${folderName}"]`
            );
            if (firstSub) firstSub.classList.add('active');
        }
    },

    /**
     * Get a human-readable display name for a module folder.
     */
    getModuleDisplayName(folderName) {
        const names = {
            'dashboard': 'Home',
            'soap-api-test': 'SOAP API Tester',
            'rest-api-test': 'REST API Tester',
            'pdf-viewer': 'PDF & Artifacts',
            'health-checks': 'Health Checks',
            'settings': 'Settings'
        };
        return names[folderName] || folderName;
    },

    /**
     * Navigate to a specific module and optionally a sub-view.
     * Updates the URL hash to enable back/forward navigation.
     */
    navigate(folderName, subView) {
        let hash = `#${folderName}`;
        if (subView) {
            hash += `/${subView}`;
        }
        window.location.hash = hash;
    }
};

/* ====================================================================
   Hash-based Router
   ==================================================================== */

/**
 * Parse the current hash and extract module name and optional sub-view.
 * Supported formats:
 *   #dashboard          → { module: 'dashboard', subView: null }
 *   #soap-api-test      → { module: 'soap-api-test', subView: null }
 *   #soap-api-test/wsdl → { module: 'soap-api-test', subView: 'wsdl' }
 */
function parseHash() {
    const hash = window.location.hash.replace('#', '').trim();
    if (!hash) {
        return { module: 'dashboard', subView: null };
    }

    const parts = hash.split('/');
    const moduleName = parts[0];
    const subView = parts.length > 1 ? parts.slice(1).join('/') : null;

    // Validate module exists
    const validModules = ['dashboard', 'soap-api-test', 'rest-api-test', 'pdf-viewer', 'health-checks', 'settings'];
    if (!validModules.includes(moduleName)) {
        return { module: 'dashboard', subView: null };
    }

    return { module: moduleName, subView };
}

/**
 * Handle hash change events — load the appropriate module.
 */
async function onHashChange() {
    const { module, subView } = parseHash();
    await ModuleLoader.loadModule(module, subView);
}

/* ====================================================================
   Font Settings Loader (applied on every page load)
   ==================================================================== */

/**
 * Load saved font settings from localStorage and apply to document root.
 * This runs on every page load so fonts are consistent across all modules.
 */
function loadGlobalFontSettings() {
    try {
        const raw = localStorage.getItem('devbiztools.font');
        if (!raw) return;

        const saved = JSON.parse(raw);
        const root = document.documentElement;

        if (saved.fontFamily) {
            root.style.setProperty('--font-family-base', saved.fontFamily);
            root.style.setProperty('--font-family-heading', saved.fontFamily);
        }
        if (saved.fontMonospace) {
            root.style.setProperty('--font-family-monospace', saved.fontMonospace);
        }
        if (saved.fontSizeBase) {
            root.style.setProperty('--font-size-base', saved.fontSizeBase);
            // Derive proportional sizes
            const base = parseFloat(saved.fontSizeBase) || 0.875;
            root.style.setProperty('--font-size-sm', (base * 0.94).toFixed(3) + 'rem');
            root.style.setProperty('--font-size-lg', (base * 1.14).toFixed(3) + 'rem');
            root.style.setProperty('--font-size-xl', (base * 1.43).toFixed(3) + 'rem');
            root.style.setProperty('--font-size-2xl', (base * 1.71).toFixed(3) + 'rem');
            if (saved.fontSizeHeadings) {
                const mult = parseFloat(saved.fontSizeHeadings) || 1.25;
                root.style.setProperty('--font-size-heading', (base * mult).toFixed(3) + 'rem');
            }
        }
    } catch (e) {
        // Ignore parse or storage errors
    }
}

// Apply font settings immediately when script loads
loadGlobalFontSettings();

/* ====================================================================
   Global Functions (shared across modules)
   ==================================================================== */

/* ====================================================================
   Monaco Editor Support
   ==================================================================== */

const editorRegistry = window.editorRegistry || [];
window.editorRegistry = editorRegistry;
window.activeEditor = window.activeEditor || null;

const editorDefaults = {
    theme: 'auto',
    fontFamily: "Consolas, 'Courier New', monospace",
    fontSize: 13,
    wordWrap: 'on',
    minimap: true
};

function getCurrentMonacoThemePreference(themePreference = editorDefaults.theme) {
    if (themePreference !== 'auto') {
        return themePreference;
    }
    return document.documentElement.getAttribute('data-bs-theme') === 'dark'
        ? 'corporate-dark'
        : 'corporate-light';
}

function defineMonacoThemes() {
    if (!window.monaco || !window.monaco.editor) {
        return;
    }

    monaco.editor.defineTheme('corporate-light', {
        base: 'vs',
        inherit: true,
        rules: [],
        colors: {
            'editor.background': '#f8fafc',
            'editor.lineHighlightBackground': '#dbeafe',
            'editorCursor.foreground': '#2563eb',
            'editor.selectionBackground': '#93c5fd66'
        }
    });

    monaco.editor.defineTheme('corporate-dark', {
        base: 'vs-dark',
        inherit: true,
        rules: [],
        colors: {
            'editor.background': '#0f172a',
            'editor.lineHighlightBackground': '#1e293b',
            'editorCursor.foreground': '#67e8f9',
            'editor.selectionBackground': '#22d3ee55'
        }
    });
}

function getDownloadMetadata(language, source, editorIndex) {
    const extByLanguage = {
        json: 'json',
        xml: 'xml',
        yaml: 'yml',
        markdown: 'md'
    };

    const mimeByLanguage = {
        json: 'application/json;charset=utf-8',
        xml: 'application/xml;charset=utf-8',
        yaml: 'text/yaml;charset=utf-8',
        markdown: 'text/markdown;charset=utf-8',
        plaintext: 'text/plain;charset=utf-8'
    };

    const extension = extByLanguage[language] || 'txt';
    const mime = mimeByLanguage[language] || 'text/plain;charset=utf-8';
    const labeledBlock = source.closest('.mb-3');
    const labelText = labeledBlock?.querySelector('label')?.textContent?.trim() || '';
    const base = labelText
        ? labelText.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/(^-|-$)/g, '')
        : `editor-${editorIndex + 1}`;

    return {
        fileName: `${base || `editor-${editorIndex + 1}`}.${extension}`,
        mime
    };
}

function createEditorHeader(editor, language, readOnly, source, editorIndex) {
    const header = document.createElement('div');
    header.className = 'editor-header d-flex align-items-center justify-content-between p-2 border-bottom';

    const leftGroup = document.createElement('div');
    leftGroup.className = 'd-flex align-items-center gap-2';

    const stateIcon = readOnly ? 'fa-solid fa-lock' : 'fa-solid fa-pen-to-square';
    leftGroup.innerHTML = `
        <span class="badge bg-secondary-subtle text-dark border d-flex align-items-center gap-1 fs-6 fw-normal px-2 py-1">
            <i class="fa-solid fa-code text-primary"></i> ${language.toUpperCase()}
        </span>
        <span class="badge bg-success-subtle text-success border d-flex align-items-center gap-1 px-2 py-1 fs-7">
            <i class="${stateIcon}"></i> ${readOnly ? 'Read-only' : 'Editable'}
        </span>
    `;

    const rightGroup = document.createElement('div');
    rightGroup.className = 'd-flex align-items-center gap-2';

    const findBtn = document.createElement('button');
    findBtn.type = 'button';
    findBtn.className = 'btn btn-outline-secondary btn-sm';
    findBtn.title = 'Find / Replace (Ctrl+F)';
    findBtn.innerHTML = '<i class="fa-solid fa-magnifying-glass"></i> <span class="d-none d-md-inline">Find</span>';
    findBtn.addEventListener('click', () => {
        editor.focus();
        editor.trigger('header', 'editor.action.startFindReplaceAction');
    });

    const formatBtn = document.createElement('button');
    formatBtn.type = 'button';
    formatBtn.className = 'btn btn-outline-primary btn-sm';
    formatBtn.title = 'Format Document';
    formatBtn.innerHTML = '<i class="fa-solid fa-wand-magic-sparkles"></i> <span class="d-none d-md-inline">Format</span>';
    formatBtn.addEventListener('click', () => {
        editor.focus();
        editor.trigger('formatButton', 'editor.action.formatDocument');
    });

    const customSlot = document.createElement('div');
    customSlot.className = 'custom-editor-actions d-flex align-items-center gap-2';

    const divider = document.createElement('div');
    divider.className = 'vr mx-1';

    const downloadBtn = document.createElement('button');
    downloadBtn.type = 'button';
    downloadBtn.className = 'btn btn-outline-secondary btn-sm';
    downloadBtn.title = 'Download Code';
    downloadBtn.innerHTML = '<i class="fa-solid fa-download"></i>';
    downloadBtn.addEventListener('click', () => {
        const { fileName, mime } = getDownloadMetadata(language, source, editorIndex);
        const blob = new Blob([editor.getValue()], { type: mime });
        const url = URL.createObjectURL(blob);
        const link = document.createElement('a');
        link.href = url;
        link.download = fileName;
        document.body.appendChild(link);
        link.click();
        link.remove();
        URL.revokeObjectURL(url);
    });

    const themeSelect = document.createElement('select');
    themeSelect.className = 'form-select form-select-sm';
    themeSelect.innerHTML = `
        <option value="auto">Auto (System)</option>
        <option value="corporate-light">Corporate Light</option>
        <option value="corporate-dark">Corporate Dark</option>
    `;
    themeSelect.value = editorDefaults.theme;
    themeSelect.addEventListener('change', event => {
        editorDefaults.theme = event.target.value;
        if (window.monaco) {
            monaco.editor.setTheme(getCurrentMonacoThemePreference(event.target.value));
        }
    });

    const fontSelect = document.createElement('select');
    fontSelect.className = 'form-select form-select-sm';
    fontSelect.innerHTML = `
        <option value="Consolas, 'Courier New', monospace">Consolas</option>
        <option value="'JetBrains Mono', Consolas, monospace">JetBrains Mono</option>
        <option value="'Fira Code', Consolas, monospace">Fira Code</option>
        <option value="Menlo, Monaco, monospace">Menlo</option>
    `;
    fontSelect.value = editorDefaults.fontFamily;
    fontSelect.addEventListener('change', event => {
        editor.updateOptions({ fontFamily: event.target.value });
    });

    const sizeSelect = document.createElement('select');
    sizeSelect.className = 'form-select form-select-sm';
    sizeSelect.innerHTML = `
        <option value="12">12 px</option>
        <option value="13" selected>13 px</option>
        <option value="14">14 px</option>
        <option value="16">16 px</option>
    `;
    sizeSelect.value = String(editorDefaults.fontSize);
    sizeSelect.addEventListener('change', event => {
        editor.updateOptions({ fontSize: Number(event.target.value) });
    });

    const wrapSelect = document.createElement('select');
    wrapSelect.className = 'form-select form-select-sm';
    wrapSelect.innerHTML = `
        <option value="on">On</option>
        <option value="off">Off</option>
        <option value="bounded">Bounded</option>
    `;
    wrapSelect.value = editorDefaults.wordWrap;
    wrapSelect.addEventListener('change', event => {
        editor.updateOptions({ wordWrap: event.target.value });
    });

    const minimapToggle = document.createElement('input');
    minimapToggle.className = 'form-check-input';
    minimapToggle.type = 'checkbox';
    minimapToggle.checked = editorDefaults.minimap;
    minimapToggle.addEventListener('change', event => {
        editor.updateOptions({ minimap: { enabled: event.target.checked } });
        editor.layout();
    });

    const settingsDropdown = document.createElement('div');
    settingsDropdown.className = 'dropdown';
    settingsDropdown.innerHTML = `
        <button class="btn btn-sm btn-outline-secondary dropdown-toggle" type="button" data-bs-toggle="dropdown" aria-expanded="false" data-bs-auto-close="outside">
            <i class="fa-solid fa-gear"></i>
        </button>
        <div class="dropdown-menu dropdown-menu-end p-3 shadow" style="min-width: 280px;">
            <h6 class="dropdown-header px-0 text-uppercase fw-bold text-muted">Editor View Options</h6>
        </div>
    `;

    const menuEl = settingsDropdown.querySelector('.dropdown-menu');
    const themeGroup = document.createElement('div');
    themeGroup.className = 'mb-2';
    themeGroup.innerHTML = '<label class="form-label form-label-sm mb-1">Theme</label>';
    themeGroup.appendChild(themeSelect);
    menuEl.appendChild(themeGroup);

    const fontGroup = document.createElement('div');
    fontGroup.className = 'mb-2';
    fontGroup.innerHTML = '<label class="form-label form-label-sm mb-1">Font Family</label>';
    fontGroup.appendChild(fontSelect);
    menuEl.appendChild(fontGroup);

    const rowDiv = document.createElement('div');
    rowDiv.className = 'row g-2 mb-2';
    rowDiv.innerHTML = `
        <div class="col-6"><label class="form-label form-label-sm mb-1">Font Size</label></div>
        <div class="col-6"><label class="form-label form-label-sm mb-1">Word Wrap</label></div>
    `;
    rowDiv.querySelector('.col-6:first-child').appendChild(sizeSelect);
    rowDiv.querySelector('.col-6:last-child').appendChild(wrapSelect);
    menuEl.appendChild(rowDiv);

    const switchDiv = document.createElement('div');
    switchDiv.className = 'form-check form-switch mt-2';
    switchDiv.appendChild(minimapToggle);
    const switchLabel = document.createElement('label');
    switchLabel.className = 'form-check-label small';
    switchLabel.textContent = 'Show Minimap';
    switchDiv.appendChild(switchLabel);
    menuEl.appendChild(switchDiv);

    rightGroup.append(findBtn, formatBtn, customSlot, divider, downloadBtn, settingsDropdown);
    header.append(leftGroup, rightGroup);

    return {
        header,
        controls: {
            theme: themeSelect
        }
    };
}

function setEditorContent(target, content) {
    const element = typeof target === 'string' ? document.getElementById(target) : target;
    if (!element) return;

    const text = content ?? '';
    const entry = editorRegistry.find(item => item.source === element);
    if (entry) {
        entry.editor.setValue(text);
        return;
    }

    if ('value' in element) {
        element.value = text;
    } else {
        element.textContent = text;
    }
}

function syncAllEditorSizes() {
    editorRegistry.forEach(entry => {
        try {
            entry.editor.layout();
        } catch (err) {
            console.warn('[Monaco] Layout failed:', err);
        }
    });
}

function initializeMonacoEditors() {
    if (!window.require || !window.monaco || !window.monaco.editor) {
        return;
    }

    defineMonacoThemes();

    const sources = document.querySelectorAll('.rich-editor-source');
    if (!sources.length) {
        return;
    }

    monaco.editor.setTheme(getCurrentMonacoThemePreference(editorDefaults.theme));

    sources.forEach((source, sourceIndex) => {
        if (source.dataset.monacoBound === '1') {
            return;
        }

        const shell = document.createElement('div');
        shell.className = 'editor-shell mb-2';
        const container = document.createElement('div');
        container.className = 'monaco-host editor-block';
        if (source.classList.contains('editor-tall')) {
            container.classList.add('editor-tall');
        }

        const isTextArea = source.tagName === 'TEXTAREA';
        const initialValue = isTextArea ? source.value : source.textContent;
        const language = source.getAttribute('data-editor-language') || 'plaintext';
        const readOnly = source.getAttribute('data-editor-readonly') === 'true';

        source.style.display = 'none';
        shell.appendChild(container);
        source.insertAdjacentElement('afterend', shell);

        const editor = monaco.editor.create(container, {
            value: initialValue,
            language,
            readOnly,
            automaticLayout: true,
            minimap: { enabled: editorDefaults.minimap },
            fontSize: editorDefaults.fontSize,
            fontFamily: editorDefaults.fontFamily,
            wordWrap: editorDefaults.wordWrap,
            glyphMargin: false,
            scrollBeyondLastLine: false,
            roundedSelection: true,
            smoothScrolling: true,
            bracketPairColorization: { enabled: true },
            guides: {
                bracketPairs: true,
                indentation: true
            },
            tabSize: 2,
            insertSpaces: true
        });

        if (!readOnly && isTextArea) {
            editor.onDidChangeModelContent(() => {
                source.value = editor.getValue();
            });
        }

        editor.onDidFocusEditorWidget(() => {
            window.activeEditor = editor;
        });

        const headerBundle = createEditorHeader(editor, language, readOnly, source, sourceIndex);
        shell.insertBefore(headerBundle.header, container);

        editorRegistry.push({ source, editor, controls: headerBundle.controls, header: headerBundle.header });
        source.dataset.monacoBound = '1';

        const shellObserver = new ResizeObserver(() => {
            editor.layout();
        });
        shellObserver.observe(shell);
    });

    if (!window.__devbiztoolsEditorBindingsInstalled) {
        window.addEventListener('resize', () => {
            syncAllEditorSizes();
        });

        document.querySelectorAll('[data-bs-toggle="tab"]').forEach(tabTrigger => {
            tabTrigger.addEventListener('shown.bs.tab', () => {
                setTimeout(() => syncAllEditorSizes(), 30);
            });
        });

        window.__devbiztoolsEditorBindingsInstalled = true;
    }

    setTimeout(() => {
        syncAllEditorSizes();
    }, 200);
}

window.initializeMonacoEditors = initializeMonacoEditors;
window.setEditorContent = setEditorContent;
window.syncAllEditorSizes = syncAllEditorSizes;

/**
 * Toggle sidebar collapsed state.
 */
function toggleSidebar() {
    const nextState = !document.documentElement.classList.contains('sidebar-collapsed');
    applySidebarState(nextState, true);
}

function applySidebarState(collapsed, persist = true) {
    document.documentElement.classList.toggle('sidebar-collapsed', collapsed);
    document.body.classList.toggle('sidebar-collapsed', collapsed);

    document.querySelectorAll('#sidebar .module-label, #sidebar .sidebar-heading, #sidebar .menu-divider')
        .forEach(el => el.classList.toggle('d-none', collapsed));

    document.querySelectorAll('#sidebar .nav-link-custom').forEach(link => {
        link.classList.toggle('justify-content-center', collapsed);
        link.classList.toggle('px-2', collapsed);
        link.classList.toggle('px-3', !collapsed);
    });

    if (collapsed) {
        document.querySelectorAll('#sidebar .nav-link-custom').forEach(link => {
            const moduleName = link.getAttribute('data-module-name');
            if (moduleName) link.setAttribute('title', moduleName);
        });
    } else {
        document.querySelectorAll('#sidebar .nav-link-custom').forEach(link => {
            link.removeAttribute('title');
        });
    }

    const toggleBtn = document.getElementById('sidebarToggleBtn');
    if (toggleBtn) {
        toggleBtn.setAttribute('title', collapsed ? 'Expand sidebar' : 'Collapse sidebar');
        toggleBtn.setAttribute('aria-label', collapsed ? 'Expand sidebar' : 'Collapse sidebar');
        toggleBtn.innerHTML = collapsed
            ? '<i class="fa-solid fa-angles-right"></i>'
            : '<i class="fa-solid fa-angles-left"></i>';
    }

    if (persist) {
        localStorage.setItem('devbiztools.sidebar.collapsed', collapsed ? '1' : '0');
    }

    // Resize Monaco editors if they exist
    setTimeout(() => {
        if (window.editorRegistry) {
            window.editorRegistry.forEach(entry => entry.editor.layout());
        }
    }, 280);
}

/**
 * Show a toast notification.
 */
function showActionToast(message, type = 'primary') {
    const id = 'appActionToastContainer';
    let container = document.getElementById(id);
    if (!container) {
        container = document.createElement('div');
        container.id = id;
        container.className = 'toast-container position-fixed top-0 end-0 p-3';
        container.style.zIndex = '1080';
        document.body.appendChild(container);
    }

    const toastEl = document.createElement('div');
    toastEl.className = `toast align-items-center text-bg-${type} border-0`;
    toastEl.setAttribute('role', 'status');
    toastEl.setAttribute('aria-live', 'polite');
    toastEl.setAttribute('aria-atomic', 'true');
    toastEl.innerHTML = `
        <div class="d-flex">
            <div class="toast-body">${message}</div>
            <button type="button" class="btn-close btn-close-white me-2 m-auto" data-bs-dismiss="toast" aria-label="Close"></button>
        </div>
    `;

    container.appendChild(toastEl);
    const toast = bootstrap.Toast.getOrCreateInstance(toastEl, { delay: 1800 });
    toast.show();
    toastEl.addEventListener('hidden.bs.toast', () => toastEl.remove());
}

/**
 * Initialize tooltips for all [title] elements.
 */
function initializeTooltips() {
    if (typeof bootstrap === 'undefined' || !bootstrap.Tooltip) return;

    document.querySelectorAll('[title]:not([data-bs-toggle="pill"]):not([data-bs-toggle="tab"])').forEach(element => {
        const text = (element.getAttribute('title') || '').trim();
        if (!text) return;
        const placement = element.getAttribute('data-tooltip-placement') || 'top';
        bootstrap.Tooltip.getOrCreateInstance(element, {
            container: 'body',
            trigger: 'hover focus',
            placement
        });
    });
}

/**
 * Set tooltip text on an element.
 */
function setTooltipText(element, text) {
    if (!element || !text) return;
    element.setAttribute('title', text);
    if (typeof bootstrap !== 'undefined' && bootstrap.Tooltip) {
        const tooltip = bootstrap.Tooltip.getInstance(element);
        if (tooltip) {
            tooltip.setContent({ '.tooltip-inner': text });
        }
    }
}

/* ====================================================================
   Sidebar Navigation Bindings
   ==================================================================== */

function initSidebarNavigation() {
    // Sidebar toggle
    const sidebarToggleBtn = document.getElementById('sidebarToggleBtn');
    if (sidebarToggleBtn) {
        sidebarToggleBtn.addEventListener('click', event => {
            event.preventDefault();
            toggleSidebar();
        });
    }

    // Home brand link
    document.getElementById('homeBrandLink')?.addEventListener('click', event => {
        event.preventDefault();
        ModuleLoader.navigate('dashboard');
    });

    // Nav links (top-level modules)
    document.querySelectorAll('#sidebar .nav-link-custom').forEach(link => {
        link.addEventListener('click', function (e) {
            const href = this.getAttribute('href');
            if (href && href.startsWith('#')) {
                // Let the hash-based router handle it
                // But for parent items (with submenu), toggle submenu if already active
                if (this.classList.contains('nav-parent') && this.classList.contains('active')) {
                    e.preventDefault();
                    const navGroup = this.closest('.nav-group');
                    const submenu = navGroup?.querySelector('.nav-submenu');
                    if (submenu) {
                        submenu.classList.toggle('expanded');
                        this.classList.toggle('expanded');
                    }
                }
                // Otherwise, the hash change will trigger route
            }
        });
    });

    // Submenu items
    document.querySelectorAll('.submenu-item').forEach(item => {
        item.addEventListener('click', function (e) {
            e.preventDefault();
            const moduleName = this.getAttribute('data-module');
            const subView = this.getAttribute('data-subview');
            if (moduleName) {
                ModuleLoader.navigate(moduleName, subView);
            }
        });
    });
}

/* ====================================================================
   Initialization
   ==================================================================== */

document.addEventListener('DOMContentLoaded', async () => {
    // Restore sidebar state
    const savedSidebar = localStorage.getItem('devbiztools.sidebar.collapsed');
    applySidebarState(savedSidebar === '1', false);

    // Initialize sidebar navigation
    initSidebarNavigation();

    // Initialize tooltips for static elements
    initializeTooltips();

    if (typeof loadAllData === 'function') {
        try {
            await loadAllData();
        } catch (err) {
            console.warn('[DataLoader] Initial data load failed:', err);
        }
    }

    // Hook hash change listener
    window.addEventListener('hashchange', onHashChange);

    // Handle initial load based on URL hash
    // (data-loader.js must have finished loading by now since it's loaded before common.js)
    const { module, subView } = parseHash();
    await ModuleLoader.loadModule(module, subView);

    if (window.require && !window.__devbiztoolsMonacoConfigured) {
        window.require.config({
            paths: {
                vs: 'https://cdnjs.cloudflare.com/ajax/libs/monaco-editor/0.52.2/min/vs'
            }
        });
        window.require(['vs/editor/editor.main'], () => {
            initializeMonacoEditors();
        });
        window.__devbiztoolsMonacoConfigured = true;
    } else {
        initializeMonacoEditors();
    }
});
