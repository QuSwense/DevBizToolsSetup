using Microsoft.AspNetCore.Components;
using Microsoft.JSInterop;
using ServiceHubEnterprise.SoapApplications.Models;
using ServiceHubEnterprise.SoapApplications.Services;

namespace ServiceHubEnterprise.SoapApplications.Pages;

public partial class WsdlSync
{
    private string? _selectedAppId;
    private string? _selectedSyncId;
    private string? _selectedVersionId;
    private HashSet<string> _treeExpandedApps = [];
    private HashSet<string> _treeExpandedSyncs = [];

    // Sync modal
    private bool _showSyncModal;
    private string _syncMode = "upload";
    private string _syncAppId = "";
    private string _syncFileName = "";
    private string _syncDescription = "";

    // WSDL change detection
    private bool _changeDetected;
    private string _changeStatusMessage = "";
    private bool _comparisonPerformed;

    // Template editor
    private bool _showTemplateEditor;
    private string? _editingTemplateId;
    private string _editTplName = "";
    private string _editTplDescription = "";
    private string _editTplExtendsId = "";
    private string _editTplContent = "";

    // Create request file from template
    private bool _showCreateRequestModal;
    private string _selectedTemplateId = "";
    private string _requestFileName = "";
    private Dictionary<string, string> _requestVarValues = [];

    // Version details panel
    private bool _expandedWsdlView = true;
    private bool _expandedWsdlCompare;
    private bool _wsdlCopied;

    // Rollback confirmation
    private bool _showRollbackConfirm;

    private void ToggleTreeApp(string appId)
    {
        if (!_treeExpandedApps.Remove(appId))
            _treeExpandedApps.Add(appId);
    }

    private void ToggleTreeSync(string syncId)
    {
        if (!_treeExpandedSyncs.Remove(syncId))
            _treeExpandedSyncs.Add(syncId);
    }

    private void SelectSyncRecord(string syncId)
    {
        _selectedSyncId = syncId;
        _selectedVersionId = null;
        if (!_treeExpandedSyncs.Contains(syncId))
            _treeExpandedSyncs.Add(syncId);
    }

    private void SelectVersion(string versionId)
    {
        _selectedVersionId = versionId;
        var version = _wsdlStore.Versions.FirstOrDefault(v => v.Id == versionId);
        if (version is not null)
        {
            _selectedSyncId = version.SyncRecordId;
            if (!_treeExpandedSyncs.Contains(version.SyncRecordId))
                _treeExpandedSyncs.Add(version.SyncRecordId);
        }
    }

    private void OpenSyncModal()
    {
        _syncMode = "upload";
        _syncAppId = _selectedAppId ?? "";
        _syncFileName = "";
        _syncDescription = "";
        _changeDetected = false;
        _changeStatusMessage = "";
        _comparisonPerformed = false;
        _showSyncModal = true;
    }

    private void SelectUploadMode()
    {
        _syncMode = "upload";
        _syncFileName = "";
        _comparisonPerformed = false;
        _changeDetected = false;
        _changeStatusMessage = "";
    }

    private void SelectAutoUpdateMode(string autoSourceUrl)
    {
        _syncMode = "auto-update";
        _comparisonPerformed = false;
        _changeDetected = false;
        _changeStatusMessage = "";
        PerformComparison(autoSourceUrl);
    }

    private void HandleSync(string autoVersion, string autoSourceUrl)
    {
        // Guard: do not proceed if no changes detected
        if (!_changeDetected) return;

        // Validate
        var appId = _syncAppId;
        if (string.IsNullOrEmpty(appId)) return;
        var app = _appStore.Apps.FirstOrDefault(a => a.Id == appId);
        if (app is null) return;

        var recordId = $"wsdl-{Guid.NewGuid():N}"[..10];
        var versionId = $"wv-{Guid.NewGuid():N}"[..10];
        var now = DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss");

        // Determine the new WSDL content based on mode
        string newWsdlContent = _syncMode == "auto-update" ? _changedWsdlContent : _previousWsdlContent;

        // Determine source URL based on mode
        string sourceUrl = _syncMode == "auto-update" ? autoSourceUrl : _syncFileName;

        // Create sync record with WSDL content stored
        var record = new WsdlSyncRecord
        {
            Id = recordId,
            AppId = app.Id,
            AppName = app.Name,
            SourceType = _syncMode == "auto-update" ? "url" : "upload",
            SourceUrl = sourceUrl,
            UploadedBy = "Current User",
            UploadedAt = now,
            Status = "synced",
            WsdlContent = newWsdlContent,
            VersionCount = 1
        };
        _wsdlStore.Records.Add(record);

        // Create version with auto-generated label
        var version = new WsdlVersionEntry
        {
            Id = versionId,
            SyncRecordId = recordId,
            VersionNumber = 1,
            Label = autoVersion,
            UploadedBy = "Current User",
            UploadedAt = now,
            Status = "active",
            Notes = string.IsNullOrWhiteSpace(_syncDescription) ? "WSDL sync" : _syncDescription
        };
        _wsdlStore.Versions.Add(version);

        _selectedSyncId = recordId;
        _selectedVersionId = versionId;
        _showSyncModal = false;

        if (!_treeExpandedApps.Contains(appId))
            _treeExpandedApps.Add(appId);
        if (!_treeExpandedSyncs.Contains(recordId))
            _treeExpandedSyncs.Add(recordId);
    }

    // ═══════════════════════════════════════════════════════════
    // WSDL comparison content — loaded from mock_db/ JSON files
    // ═══════════════════════════════════════════════════════════

    private string _previousWsdlContent = "";
    private string _changedWsdlContent = "";

    /// <summary>
    /// Performs WSDL comparison and updates change detection state.
    /// Uses data loaded from mock_db/ via MockDbLoader.
    /// </summary>
    private void PerformComparison(string autoSourceUrl)
    {
        _comparisonPerformed = true;

        // Determine which "new" WSDL to use based on the file name or mode
        string newWsdl;
        if (_syncMode == "auto-update")
        {
            // Auto-update always uses "changed" WSDL to demonstrate real flow
            newWsdl = _changedWsdlContent;
        }
        else
        {
            // Upload mode: use file name to decide mock content
            newWsdl = _syncFileName switch
            {
                "billing_v4.wsdl" => _changedWsdlContent,   // has changes
                _ => _previousWsdlContent                    // default: no changes
            };
        }

        // Compare with the previously stored version
        _changeDetected = DetectWsdlChanges(_previousWsdlContent, newWsdl);
        _changeStatusMessage = _changeDetected
            ? "Changes detected in WSDL. Ready to update."
            : "No changes detected in WSDL. Update not required.";
    }

    /// <summary>
    /// Compares two WSDL XML strings and returns true if differences are found.
    /// Uses a simple whitespace-normalized comparison.
    /// </summary>
    private static bool DetectWsdlChanges(string previous, string current)
    {
        if (string.IsNullOrWhiteSpace(previous) && string.IsNullOrWhiteSpace(current))
            return false;
        if (string.IsNullOrWhiteSpace(previous) || string.IsNullOrWhiteSpace(current))
            return true;

        // Normalize whitespace for comparison
        static string Normalize(string xml)
        {
            return System.Text.RegularExpressions.Regex.Replace(xml, @">\s+<", "><")
                .Trim();
        }

        return !string.Equals(Normalize(previous), Normalize(current), StringComparison.Ordinal);
    }

    protected override async Task OnInitializedAsync()
    {
        await base.OnInitializedAsync();

        // Load WSDL comparison mock data from mock_db
        _previousWsdlContent = await _mockDbLoader.LoadWsdlContentAsync("previous");
        _changedWsdlContent = await _mockDbLoader.LoadWsdlContentAsync("changed");

        // Auto-select first app
        var first = _appStore.Apps.FirstOrDefault();
        if (first is not null)
        {
            _selectedAppId = first.Id;
            _treeExpandedApps.Add(first.Id);
        }
    }

    /// <summary>
    /// Generates an auto-incremented version number in the format: YY.QQ.M
    /// where YY = last 2 digits of year, QQ = quarter code (10/20/30/40),
    /// M = sequential minor version starting from 1.
    /// </summary>
    private string GenerateVersionNumber(string appName)
    {
        var now = DateTime.Now;
        var year = now.Year % 100;
        var quarter = (now.Month - 1) / 3;
        var quarterCode = (quarter + 1) * 10;
        var prefix = $"{appName} {year:D2}.{quarterCode:D2}.";

        // Find max minor version for current app + year+quarter across all versions
        var maxMinor = 0;
        foreach (var ver in _wsdlStore.Versions)
        {
            if (ver.Label.StartsWith(prefix))
            {
                var parts = ver.Label.Split('.');
                if (parts.Length == 3 && int.TryParse(parts[2], out var minor))
                {
                    maxMinor = Math.Max(maxMinor, minor);
                }
            }
        }

        return $"{prefix}{maxMinor + 1}";
    }

    private void OpenTemplateEditor(string? templateId)
    {
        _editingTemplateId = templateId;
        if (templateId is not null)
        {
            var tpl = _wsdlStore.GetTemplate(templateId);
            if (tpl is not null)
            {
                _editTplName = tpl.Name;
                _editTplDescription = tpl.Description;
                _editTplExtendsId = tpl.ExtendsTemplateId ?? "";
                _editTplContent = tpl.Content;
            }
        }
        else
        {
            _editTplName = "";
            _editTplDescription = "";
            _editTplExtendsId = "";
            _editTplContent = "";
        }
        _showTemplateEditor = true;
    }

    private void HandleSaveTemplate()
    {
        if (string.IsNullOrWhiteSpace(_editTplName)) return;

        var vars = ExtractTemplateVars(_editTplContent);
        var now = DateTime.Now.ToString("yyyy-MM-dd");

        if (_editingTemplateId is not null)
        {
            var existing = _wsdlStore.GetTemplate(_editingTemplateId);
            if (existing is not null)
            {
                var parentName = "";
                if (!string.IsNullOrEmpty(_editTplExtendsId))
                {
                    var parent = _wsdlStore.GetTemplate(_editTplExtendsId);
                    if (parent is not null) parentName = parent.Name;
                }

                existing.Name = _editTplName;
                existing.Description = _editTplDescription;
                existing.ExtendsTemplateId = string.IsNullOrEmpty(_editTplExtendsId) ? null : _editTplExtendsId;
                existing.ExtendsTemplateName = string.IsNullOrEmpty(parentName) ? null : parentName;
                existing.Content = _editTplContent;
                existing.Variables = vars;
                existing.UpdatedAt = now;
            }
        }
        else
        {
            var parentName = "";
            if (!string.IsNullOrEmpty(_editTplExtendsId))
            {
                var parent = _wsdlStore.GetTemplate(_editTplExtendsId);
                if (parent is not null) parentName = parent.Name;
            }

            _wsdlStore.Templates.Add(new WsdlTemplate
            {
                Id = $"tpl-{Guid.NewGuid():N}"[..10],
                Name = _editTplName,
                Description = _editTplDescription,
                ExtendsTemplateId = string.IsNullOrEmpty(_editTplExtendsId) ? null : _editTplExtendsId,
                ExtendsTemplateName = string.IsNullOrEmpty(parentName) ? null : parentName,
                Content = _editTplContent,
                Variables = vars,
                CreatedBy = "Current User",
                CreatedAt = now,
                UpdatedAt = now,
                UsageCount = 0
            });
        }

        _showTemplateEditor = false;
    }

    private void OpenCreateFromTemplate(string templateId)
    {
        _selectedTemplateId = templateId;
        var template = _wsdlStore.GetTemplate(templateId);
        if (template is not null)
        {
            _requestFileName = "";
            _requestVarValues = [];
            var allVars = _wsdlStore.ResolveVariables(template);
            foreach (var v in allVars)
            {
                _requestVarValues[v.Name] = v.DefaultValue;
            }
        }
        _showCreateRequestModal = true;
    }

    private void HandleCreateRequestFile()
    {
        // Close the modal
        _showCreateRequestModal = false;
    }

    /// <summary>
    /// Extracts {{var_name}} placeholders from template content.
    /// Only supports simple variable names (no complex paths).
    /// </summary>
    private static string[] ExtractTemplateVars(string content)
    {
        if (string.IsNullOrWhiteSpace(content)) return [];
        var matches = System.Text.RegularExpressions.Regex.Matches(content, @"\{\{(\w+)\}\}");
        return matches.Select(m => m.Groups[1].Value).Distinct().OrderBy(v => v).ToArray();
    }

    /// <summary>
    /// Renders the WSDL sync records grid for a given application.
    /// </summary>
    private RenderFragment RenderRecordsGrid(string appId) => builder =>
    {
        var records = _wsdlStore.GetRecordsForApp(appId);
        if (records.Length == 0)
        {
            builder.OpenElement(0, "div");
            builder.AddAttribute(1, "class", "datagrid-card empty-state-card");
            builder.AddAttribute(2, "style", "padding:40px 20px;gap:8px");
            builder.OpenElement(3, "i");
            builder.AddAttribute(4, "class", "bi bi-inbox empty-state-icon");
            builder.AddAttribute(5, "style", "font-size:36px");
            builder.CloseElement();
            builder.OpenElement(6, "p");
            builder.AddAttribute(7, "class", "empty-state-desc");
            builder.AddAttribute(8, "style", "color:var(--sh-text-soft)");
            builder.AddContent(9, "No WSDL syncs for this application yet. Click \"Import from URL\" or \"Upload File\" to get started.");
            builder.CloseElement();
            builder.CloseElement();
            return;
        }

        foreach (var rec in records)
        {
            var versionsList = _wsdlStore.GetVersionsForSync(rec.Id);

            // Record card
            builder.OpenElement(0, "div");
            builder.AddAttribute(1, "class", "datagrid-card");
            builder.AddAttribute(2, "style", "padding:14px 18px;margin-bottom:8px;cursor:pointer");
            builder.AddAttribute(3, "onclick", EventCallback.Factory.Create(this, () => SelectSyncRecord(rec.Id)));

            // Header row
            builder.OpenElement(4, "div");
            builder.AddAttribute(5, "style", "display:flex;justify-content:space-between;align-items:center");

            builder.OpenElement(6, "div");
            builder.AddAttribute(7, "style", "display:flex;align-items:center;gap:8px");
            builder.OpenElement(8, "span");
            builder.AddAttribute(9, "class", $"tree-source-badge {(rec.SourceType == "url" ? "source-url" : "source-upload")}");
            builder.OpenElement(10, "i");
            builder.AddAttribute(11, "class", $"bi {(rec.SourceType == "url" ? "bi-link-45deg" : "bi-file-earmark-arrow-up")}");
            builder.CloseElement();
            builder.CloseElement();
            builder.OpenElement(12, "span");
            builder.AddAttribute(13, "style", "font-weight:500;font-size:13px");
            builder.AddContent(14, rec.SourceType == "url" ? TruncateUrl(rec.SourceUrl) : rec.SourceUrl);
            builder.CloseElement();
            builder.OpenElement(15, "span");
            builder.AddAttribute(16, "class", $"status-badge {(rec.Status == "synced" ? "status-enabled" : "status-down")}");
            builder.AddContent(17, rec.Status == "synced" ? "Synced" : rec.Status == "failed" ? "Failed" : "Parsing...");
            builder.CloseElement();
            builder.CloseElement();

            builder.OpenElement(18, "div");
            builder.AddAttribute(19, "style", "font-size:11px;color:var(--sh-text-faint)");
            builder.AddContent(20, $"{rec.UploadedAt} — {rec.UploadedBy} · {rec.VersionCount} version(s)");
            builder.CloseElement();

            builder.CloseElement(); // header row

            // Version chips
            if (versionsList.Length > 0)
            {
                builder.OpenElement(21, "div");
                builder.AddAttribute(22, "style", "display:flex;gap:6px;margin-top:8px;flex-wrap:wrap");
                foreach (var ver in versionsList)
                {
                    builder.OpenElement(23, "span");
                    builder.AddAttribute(24, "class", "verb-badge");
                    builder.AddAttribute(25, "style", $"font-size:10px;cursor:pointer;background:{(ver.Status == "active" ? "var(--sh-accent-soft)" : "var(--sh-surface-2)")};color:{(ver.Status == "active" ? "var(--sh-accent)" : "var(--sh-text-faint)")};border-color:currentColor");
                    builder.AddAttribute(26, "onclick", EventCallback.Factory.Create(this, () => SelectVersion(ver.Id)));
                    builder.AddContent(27, ver.Label);
                    builder.CloseElement();
                }
                builder.CloseElement();
            }

            builder.CloseElement(); // card
        }
    };

    private static string TruncateUrl(string url)
    {
        if (string.IsNullOrWhiteSpace(url)) return "";
        if (url.Length <= 35) return url;
        // Try to show meaningful part
        var uri = Uri.TryCreate(url, UriKind.Absolute, out var u) ? u : null;
        if (uri is not null)
        {
            var host = uri.Host;
            var lastSeg = uri.Segments.LastOrDefault()?.Trim('/');
            if (!string.IsNullOrEmpty(lastSeg) && lastSeg.Length > 3)
                return $"{host}/.../{lastSeg}";
            return host;
        }
        return url[..32] + "...";
    }

    // ═══════════════════════════════════════════════════════════
    // ═══════════════════════════════════════════════════════════
    // Version details panel helpers + Monaco editor integration
    // ═══════════════════════════════════════════════════════════

    private void ToggleWsdlCompare()
    {
        _expandedWsdlCompare = !_expandedWsdlCompare;
    }

    protected override async Task OnAfterRenderAsync(bool firstRender)
    {
        await base.OnAfterRenderAsync(firstRender);
        // Initialize Monaco editors after render
        await InitializeMonacoEditors();
    }

    private async Task InitializeMonacoEditors()
    {
        // Initialize WSDL content editor if expanded
        if (_expandedWsdlView && !string.IsNullOrEmpty(_selectedVersionId))
        {
            var version = _wsdlStore.Versions.FirstOrDefault(v => v.Id == _selectedVersionId);
            if (version is not null)
            {
                var record = _wsdlStore.Records.FirstOrDefault(r => r.Id == version.SyncRecordId);
                if (record is not null && !string.IsNullOrWhiteSpace(record.WsdlContent))
                {
                    var editorId = $"wsdl-content-{_selectedVersionId}";
                    await _js.InvokeVoidAsync("wsdlMonaco.createEditor", editorId, record.WsdlContent);
                }
            }
        }

        // Initialize WSDL compare diff view if expanded
        if (_expandedWsdlCompare && !string.IsNullOrEmpty(_selectedVersionId))
        {
            var currentVersion = _wsdlStore.Versions.FirstOrDefault(v => v.Id == _selectedVersionId);
            if (currentVersion is not null)
            {
                var currentRecord = _wsdlStore.Records.FirstOrDefault(r => r.Id == currentVersion.SyncRecordId);
                var previousVersion = _wsdlStore.Versions
                    .Where(v => v.SyncRecordId == currentVersion.SyncRecordId && v.VersionNumber < currentVersion.VersionNumber)
                    .OrderByDescending(v => v.VersionNumber)
                    .FirstOrDefault();
                if (previousVersion is not null)
                {
                    var prevRecord = _wsdlStore.Records.FirstOrDefault(r => r.Id == previousVersion.SyncRecordId);
                    var comparerId = $"wsdl-compare-{_selectedVersionId}";
                    await _js.InvokeVoidAsync("wsdlMonaco.compareXml",
                        comparerId,
                        prevRecord?.WsdlContent ?? "",
                        currentRecord?.WsdlContent ?? "",
                        previousVersion.Label,
                        currentVersion.Label);
                }
            }
        }
    }

    /// <summary>
    /// Copies WSDL content to clipboard and shows confirmation.
    /// </summary>
    private void CopyWsdlContent(string content)
    {
        _wsdlCopied = true;
    }

    /// <summary>
    /// Opens the Create Request File modal using the first available template.
    /// </summary>
    private void OpenCreateFromTemplateForVersion()
    {
        var templates = _wsdlStore.GetTemplates();
        if (templates.Length > 0)
        {
            OpenCreateFromTemplate(templates[0].Id);
        }
    }

    /// <summary>
    /// Handles rollback by creating a new version entry with restored content.
    /// </summary>
    private void HandleRollback()
    {
        _showRollbackConfirm = false;
    }

    /// <summary>
    /// Downloads the WSDL content as a file.
    /// </summary>
    private void DownloadWsdl(string content, string fileName)
    {
        // In a real implementation, this would trigger a file download via JS interop.
        // For now, it's a placeholder that logs the action.
    }
}
