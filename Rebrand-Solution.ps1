<#
.SYNOPSIS
    Rebrands a C# .NET solution: replaces the old root namespace in file
    contents and renames matching files/folders. Cross-platform (PowerShell
    Core / pwsh on Windows, macOS, Linux).

.DESCRIPTION
    1. Recursively replaces every occurrence of $OldNamespace with
       $NewNamespace in supported text files (.cs, .razor, .csproj, .sln,
       .slnx, .sql, .sh, .json, .md, appsettings*.json, _Imports.razor).
    2. Renames files whose names contain $OldNamespace.
    3. Renames directories (bottom-up) whose names contain $OldNamespace.
    Excludes .git, bin, obj, node_modules, wwwroot/lib and binary artifacts
    (.dacpac, .mdf, .ldf, .bin, .dll, .pdb, .exe). Original byte-order marks
    and encodings are preserved. Supports -WhatIf / -Confirm.

.PARAMETER NewNamespace
    Required. The new root namespace, e.g. "CompanyX.ServiceHub".

.PARAMETER OldNamespace
    The namespace to replace. Default: "ServiceHubEnterprise".

.PARAMETER Path
    Root directory of the solution. Default: current directory.

.PARAMETER IncludeRoot
    Also rename the root folder itself if its name contains $OldNamespace.

.PARAMETER TextExtensions
    Extensions eligible for content replacement.

.EXAMPLE
    pwsh ./Rebrand-Solution.ps1 -NewNamespace "CompanyX.ServiceHub" -WhatIf

.EXAMPLE
    pwsh ./Rebrand-Solution.ps1 -NewNamespace "CompanyX.ServiceHub" -Verbose
#>
[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [ValidateNotNullOrEmpty()]
    [string]$NewNamespace,

    [Parameter(Position = 1)]
    [string]$OldNamespace = 'ServiceHubEnterprise',

    [Parameter()]
    [string]$Path = (Get-Location).Path,

    [Parameter()]
    [switch]$IncludeRoot,

    [Parameter()]
    [string[]]$TextExtensions = @('.cs', '.razor', '.cshtml', '.csproj', '.sln', '.slnx', '.sql', '.sh', '.json', '.md', '.css', '.js')
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# ---- Validation -----------------------------------------------------------
if ($OldNamespace -eq $NewNamespace) {
    throw 'OldNamespace and NewNamespace must be different.'
}
if ($OldNamespace -match '\s' -or $NewNamespace -match '\s') {
    throw 'Namespaces must not contain whitespace.'
}
if ($NewNamespace.Contains($OldNamespace)) {
    Write-Warning "NewNamespace '$NewNamespace' contains OldNamespace '$OldNamespace'. Replacement is single-pass; verify the final result."
}
if (-not (Test-Path -LiteralPath $Path -PathType Container)) {
    throw "Path '$Path' is not an accessible directory."
}

$Root = [System.IO.Path]::GetFullPath($Path)

# ---- Excluded names (case-insensitive) ------------------------------------
$ExcludedDirNames = [System.Collections.Generic.HashSet[string]]::new(
    [string[]]@('.git', 'bin', 'obj', 'node_modules'),
    [System.StringComparer]::OrdinalIgnoreCase)

$ExcludedFileExtensions = [System.Collections.Generic.HashSet[string]]::new(
    [string[]]@('.dacpac', '.mdf', '.ldf', '.bin', '.dll', '.pdb', '.exe'),
    [System.StringComparer]::OrdinalIgnoreCase)

$TextExtensionSet = [System.Collections.Generic.HashSet[string]]::new(
    [string[]]$TextExtensions,
    [System.StringComparer]::OrdinalIgnoreCase)

# ---- Helpers ---------------------------------------------------------------
function Test-ExcludedDirectory {
    param([string]$DirectoryPath)
    $relative = [System.IO.Path]::GetRelativePath($Root, $DirectoryPath)
    if ($relative -eq '.' -or $relative -eq '') { return $false }
    $segments = $relative -split '[\\/]'
    for ($i = 0; $i -lt $segments.Length; $i++) {
        if ($ExcludedDirNames.Contains($segments[$i])) { return $true }
        # Skip wwwroot/lib but allow other wwwroot subfolders.
        if ($segments[$i] -ieq 'lib' -and $i -gt 0 -and $segments[$i - 1] -ieq 'wwwroot') { return $true }
    }
    return $false
}

function Test-TextFile {
    param([System.IO.FileInfo]$File)
    if ($ExcludedFileExtensions.Contains($File.Extension)) { return $false }
    if ($TextExtensionSet.Contains($File.Extension)) { return $true }
    if ($File.Name -like 'appsettings*.json') { return $true }
    if ($File.Name -eq '_Imports.razor') { return $true }
    return $false
}

# Enumerate files, never descending into excluded directories (prunes bin/obj).
# NOTE: emits each FileInfo on the pipeline (recursively). Do NOT accumulate into a
# List and `return` it -- PowerShell unrolls the list, so a recursive call that finds a
# single file yields a bare FileInfo and List.AddRange() throws.
function Get-IncludedFiles {
    param([string]$DirectoryPath)
    foreach ($entry in [System.IO.Directory]::EnumerateFileSystemEntries($DirectoryPath)) {
        if ([System.IO.Directory]::Exists($entry)) {
            if (-not (Test-ExcludedDirectory -DirectoryPath $entry)) {
                Get-IncludedFiles -DirectoryPath $entry
            }
        }
        else {
            [System.IO.FileInfo]::new($entry)
        }
    }
}

# Enumerate directories, pruning excluded ones.
# Same pipeline-based recursion as Get-IncludedFiles; see note above.
function Get-IncludedDirectories {
    param([string]$DirectoryPath)
    foreach ($entry in [System.IO.Directory]::EnumerateFileSystemEntries($DirectoryPath)) {
        if ([System.IO.Directory]::Exists($entry)) {
            if (-not (Test-ExcludedDirectory -DirectoryPath $entry)) {
                $entry
                Get-IncludedDirectories -DirectoryPath $entry
            }
        }
    }
}

# Detect BOM and return the exact encoding so round-tripping is lossless.
function Get-FileEncoding {
    param([byte[]]$Bytes)
    if ($Bytes.Length -ge 4 -and $Bytes[0] -eq 0xFF -and $Bytes[1] -eq 0xFE -and $Bytes[2] -eq 0x00 -and $Bytes[3] -eq 0x00) {
        return [System.Text.UTF32Encoding]::new($false, $true)      # UTF-32 LE + BOM
    }
    if ($Bytes.Length -ge 3 -and $Bytes[0] -eq 0xEF -and $Bytes[1] -eq 0xBB -and $Bytes[2] -eq 0xBF) {
        return [System.Text.UTF8Encoding]::new($true)               # UTF-8 + BOM
    }
    if ($Bytes.Length -ge 2 -and $Bytes[0] -eq 0xFE -and $Bytes[1] -eq 0xFF) {
        return [System.Text.Encoding]::BigEndianUnicode             # UTF-16 BE + BOM
    }
    if ($Bytes.Length -ge 2 -and $Bytes[0] -eq 0xFF -and $Bytes[1] -eq 0xFE) {
        return [System.Text.Encoding]::Unicode                      # UTF-16 LE + BOM
    }
    return [System.Text.UTF8Encoding]::new($false)                  # UTF-8, no BOM
}

# ---- 1. Enumerate ----------------------------------------------------------
$allFiles = @(Get-IncludedFiles -DirectoryPath $Root)
Write-Verbose "Enumerated $($allFiles.Count) included files under '$Root'."

# ---- 2. Content replacement ------------------------------------------------
$contentChanged = 0
foreach ($file in $allFiles) {
    if (-not (Test-TextFile -File $file)) { continue }

    $bytes = [System.IO.File]::ReadAllBytes($file.FullName)
    $encoding = Get-FileEncoding -Bytes $bytes
    $text = $encoding.GetString($bytes)
    if ($text.IndexOf($OldNamespace, [System.StringComparison]::Ordinal) -lt 0) { continue }

    $newText = $text.Replace($OldNamespace, $NewNamespace)
    if ($PSCmdlet.ShouldProcess($file.FullName, "Replace '$OldNamespace' with '$NewNamespace' in file content")) {
        [System.IO.File]::WriteAllText($file.FullName, $newText, $encoding)
        $contentChanged++
        Write-Verbose "Updated content: $($file.FullName)"
    }
}

# ---- 3. Rename files -------------------------------------------------------
$filesRenamed = 0
$fileConflicts = 0
foreach ($file in $allFiles) {
    if ($ExcludedFileExtensions.Contains($file.Extension)) { continue }
    $name = $file.Name
    if ($name.IndexOf($OldNamespace, [System.StringComparison]::Ordinal) -lt 0) { continue }

    $newName = $name.Replace($OldNamespace, $NewNamespace)
    $newPath = [System.IO.Path]::Combine($file.DirectoryName, $newName)
    if ([System.IO.File]::Exists($newPath)) {
        Write-Warning "Rename skipped (target exists): '$newPath'"
        $fileConflicts++
        continue
    }
    if ($PSCmdlet.ShouldProcess($file.FullName, "Rename file to '$newName'")) {
        [System.IO.File]::Move($file.FullName, $newPath)
        $filesRenamed++
        Write-Verbose "Renamed file: $($file.FullName) -> $newPath"
    }
}

# ---- 4. Rename directories (bottom-up) -------------------------------------
$dirsRenamed = 0
$dirConflicts = 0
$candidates = [System.Collections.Generic.List[string]]::new()
foreach ($dir in (Get-IncludedDirectories -DirectoryPath $Root)) {
    if (([System.IO.Path]::GetFileName($dir)).IndexOf($OldNamespace, [System.StringComparison]::Ordinal) -ge 0) {
        $candidates.Add($dir)
    }
}
if ($IncludeRoot) {
    if (([System.IO.Path]::GetFileName($Root)).IndexOf($OldNamespace, [System.StringComparison]::Ordinal) -ge 0) {
        $candidates.Add($Root)
    }
}

# Longest path first => deepest folder renamed before its ancestors.
foreach ($dir in ($candidates | Sort-Object { $_.Length } -Descending)) {
    $name = [System.IO.Path]::GetFileName($dir)
    $newName = $name.Replace($OldNamespace, $NewNamespace)
    $parent = [System.IO.Path]::GetDirectoryName($dir)
    $newPath = [System.IO.Path]::Combine($parent, $newName)
    if ([System.IO.Directory]::Exists($newPath)) {
        Write-Warning "Rename skipped (target exists): '$newPath'"
        $dirConflicts++
        continue
    }
    if ($PSCmdlet.ShouldProcess($dir, "Rename directory to '$newName'")) {
        [System.IO.Directory]::Move($dir, $newPath)
        $dirsRenamed++
        Write-Verbose "Renamed directory: $dir -> $newPath"
    }
}

# ---- 5. Summary ------------------------------------------------------------
Write-Host ''
Write-Host '=== Rebrand summary ===' -ForegroundColor Cyan
Write-Host "  Old namespace     : $OldNamespace"
Write-Host "  New namespace     : $NewNamespace"
Write-Host "  Files content     : $contentChanged"
Write-Host "  Files renamed     : $filesRenamed"
Write-Host "  Folders renamed   : $dirsRenamed"
if ($fileConflicts -gt 0) { Write-Host "  File conflicts    : $fileConflicts (target already exists)" -ForegroundColor Yellow }
if ($dirConflicts -gt 0) { Write-Host "  Folder conflicts  : $dirConflicts (target already exists)" -ForegroundColor Yellow }
if ($WhatIfPreference) { Write-Host '  Mode              : WhatIf (no changes written)' -ForegroundColor Yellow }