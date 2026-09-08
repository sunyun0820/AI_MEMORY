# AI_MEMORY reusable global skill importer
# Windows PowerShell 5.1 compatible and ASCII-only by design.

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [string[]]$SourceRoot,
    [switch]$KeepAgentsSource
)

$ErrorActionPreference = "Stop"

$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$SkillsRoot = Join-Path $RepoRoot "skills"
$AgentsSkillsRoot = Join-Path $HOME ".agents\skills"

if (-not (Test-Path $SkillsRoot -PathType Container)) {
    throw "AI_MEMORY skills directory not found: $SkillsRoot"
}

function Normalize-PathString {
    param([Parameter(Mandatory = $true)][string]$Path)
    $full = [IO.Path]::GetFullPath($Path)
    return $full.TrimEnd([char[]]"\/")
}

function Test-SamePathString {
    param(
        [Parameter(Mandatory = $true)][string]$PathA,
        [Parameter(Mandatory = $true)][string]$PathB
    )
    return (Normalize-PathString $PathA) -ieq (Normalize-PathString $PathB)
}

function Test-LinkTargetsPath {
    param(
        [Parameter(Mandatory = $true)][string]$LinkPath,
        [Parameter(Mandatory = $true)][string]$ExpectedTarget
    )

    if (-not (Test-Path $LinkPath)) { return $false }
    $item = Get-Item $LinkPath -Force
    if ($item.LinkType -ne "Junction" -and $item.LinkType -ne "SymbolicLink") { return $false }

    foreach ($target in @($item.Target)) {
        if ([string]::IsNullOrWhiteSpace([string]$target)) { continue }
        $candidate = [string]$target
        if (-not [IO.Path]::IsPathRooted($candidate)) {
            $candidate = Join-Path (Split-Path $LinkPath -Parent) $candidate
        }
        if (Test-SamePathString -PathA $candidate -PathB $ExpectedTarget) { return $true }
    }
    return $false
}

function Test-PathUnder {
    param(
        [Parameter(Mandatory = $true)][string]$Child,
        [Parameter(Mandatory = $true)][string]$Parent
    )
    $childPath = Normalize-PathString $Child
    $parentPath = (Normalize-PathString $Parent) + [IO.Path]::DirectorySeparatorChar
    return $childPath.StartsWith($parentPath, [StringComparison]::OrdinalIgnoreCase)
}

function Get-SkillNameFromFile {
    param([Parameter(Mandatory = $true)][string]$SkillFile)
    $text = [string](Get-Content $SkillFile -Raw -Encoding UTF8)
    $match = [regex]::Match($text, '(?m)^name:\s*["'']?([^"''\r\n]+?)["'']?\s*$')
    if (-not $match.Success) { return $null }
    return $match.Groups[1].Value.Trim()
}

function Get-DirectoryFingerprint {
    param([Parameter(Mandatory = $true)][string]$Root)
    $rootResolved = (Resolve-Path $Root).Path
    $items = @()
    foreach ($file in @(Get-ChildItem -Path $rootResolved -File -Recurse -Force | Sort-Object FullName)) {
        $relative = $file.FullName.Substring($rootResolved.Length).TrimStart([char[]]"\/") -replace '\\', '/'
        $hash = (Get-FileHash -Path $file.FullName -Algorithm SHA256).Hash
        $items += ("{0}|{1}|{2}" -f $relative, $file.Length, $hash)
    }
    return ($items -join "`n")
}

function Copy-SkillVerified {
    param(
        [Parameter(Mandatory = $true)][string]$Source,
        [Parameter(Mandatory = $true)][string]$Destination,
        [Parameter(Mandatory = $true)][string]$SkillName
    )

    if (Test-Path $Destination) { throw "Destination already exists: $Destination" }
    $staging = Join-Path $SkillsRoot (".importing-{0}-{1}" -f $SkillName, ([Guid]::NewGuid().ToString("N")))
    try {
        New-Item -ItemType Directory -Path $staging -Force | Out-Null
        Get-ChildItem -Path $Source -Force | Copy-Item -Destination $staging -Recurse -Force
        if ((Get-DirectoryFingerprint $Source) -ne (Get-DirectoryFingerprint $staging)) {
            throw "Verification failed after copying skill: $SkillName"
        }
        Move-Item -Path $staging -Destination $Destination
    }
    finally {
        if (Test-Path $staging) { Remove-Item $staging -Recurse -Force }
    }
}

function Remove-DirectoryLinkOnly {
    param([Parameter(Mandatory = $true)][string]$Path)
    if (-not (Test-Path $Path)) { return }
    $item = Get-Item $Path -Force
    if ($item.LinkType -ne "Junction" -and $item.LinkType -ne "SymbolicLink") {
        throw "Refusing to remove non-link path: $Path"
    }
    $comspec = if ([string]::IsNullOrWhiteSpace($env:ComSpec)) { "cmd.exe" } else { $env:ComSpec }
    $p = Start-Process -FilePath $comspec -ArgumentList @("/d", "/c", "rmdir `"$Path`"") -NoNewWindow -Wait -PassThru
    if ($p.ExitCode -ne 0 -or (Test-Path $Path)) { throw "Failed to remove directory link: $Path" }
}

function Convert-AgentsSourceToJunction {
    param(
        [Parameter(Mandatory = $true)][string]$SourcePath,
        [Parameter(Mandatory = $true)][string]$TargetPath,
        [Parameter(Mandatory = $true)][string]$SkillName
    )

    if ($KeepAgentsSource) {
        Write-Host "[KEEP] Agents source left as real directory: $SourcePath"
        return
    }

    if (Test-LinkTargetsPath -LinkPath $SourcePath -ExpectedTarget $TargetPath) {
        Write-Host "[OK]   Agents source already linked: $SkillName"
        return
    }

    $item = Get-Item $SourcePath -Force
    if ($item.LinkType -eq "Junction" -or $item.LinkType -eq "SymbolicLink") {
        throw "Agents source is linked somewhere else: $SourcePath"
    }

    if ((Get-DirectoryFingerprint $SourcePath) -ne (Get-DirectoryFingerprint $TargetPath)) {
        throw "Refusing to replace source because imported copy differs: $SkillName"
    }

    $backupRoot = Join-Path ([IO.Path]::GetTempPath()) "AI_MEMORY-skill-import-backup"
    if (-not (Test-Path $backupRoot)) { New-Item -ItemType Directory -Path $backupRoot -Force | Out-Null }
    $backup = Join-Path $backupRoot ("{0}-{1}" -f $SkillName, ([Guid]::NewGuid().ToString("N")))

    Move-Item -Path $SourcePath -Destination $backup
    try {
        New-Item -ItemType Junction -Path $SourcePath -Target $TargetPath | Out-Null
        if (-not (Test-LinkTargetsPath -LinkPath $SourcePath -ExpectedTarget $TargetPath)) {
            throw "Created junction target does not match canonical skill: $SkillName"
        }
        Remove-Item $backup -Recurse -Force
        Write-Host "[LINK] $SourcePath -> $TargetPath"
    }
    catch {
        if (Test-Path $SourcePath) {
            $created = Get-Item $SourcePath -Force
            if ($created.LinkType -eq "Junction" -or $created.LinkType -eq "SymbolicLink") {
                Remove-DirectoryLinkOnly -Path $SourcePath
            }
        }
        if (-not (Test-Path $SourcePath) -and (Test-Path $backup)) {
            Move-Item -Path $backup -Destination $SourcePath
        }
        throw
    }
}

if ($null -eq $SourceRoot -or $SourceRoot.Count -eq 0) {
    $SourceRoot = @(
        $AgentsSkillsRoot,
        (Join-Path $HOME ".gemini\config\skills"),
        (Join-Path $HOME ".gemini\skills"),
        (Join-Path $HOME ".claude\skills"),
        (Join-Path $HOME ".cursor\skills")
    )
}

$existingRoots = @()
foreach ($root in $SourceRoot) {
    if ([string]::IsNullOrWhiteSpace($root)) { continue }
    if (Test-Path $root -PathType Container) {
        $resolved = (Resolve-Path $root).Path
        if ($existingRoots -notcontains $resolved) { $existingRoots += $resolved }
    }
}

Write-Host ""
Write-Host "=== AI_MEMORY Global Skill Import ==="
Write-Host "Repository : $RepoRoot"
Write-Host "Canonical  : $SkillsRoot"
Write-Host "Source roots:"
foreach ($root in $existingRoots) { Write-Host " - $root" }
Write-Host ""

$imported = 0
$alreadyManaged = 0
$duplicates = 0
$skipped = 0
$failed = 0
$seenNames = @{}

foreach ($root in $existingRoots) {
    $isAgentsRoot = Test-SamePathString -PathA $root -PathB $AgentsSkillsRoot

    foreach ($skillDir in @(Get-ChildItem -Path $root -Directory -Force | Sort-Object Name)) {
        $skillFile = Join-Path $skillDir.FullName "SKILL.md"
        if (-not (Test-Path $skillFile -PathType Leaf)) {
            Write-Host "[SKIP] No SKILL.md: $($skillDir.FullName)"
            $skipped++
            continue
        }

        $skillName = Get-SkillNameFromFile -SkillFile $skillFile
        if ([string]::IsNullOrWhiteSpace($skillName)) {
            Write-Warning "Could not read skill name from: $skillFile"
            $skipped++
            continue
        }
        if ($skillName -ne $skillDir.Name) {
            Write-Warning "Folder/name mismatch. Folder='$($skillDir.Name)' SKILL.name='$skillName'. Skipped."
            $skipped++
            continue
        }

        $canonical = Join-Path $SkillsRoot $skillName

        if (Test-Path $canonical -PathType Container) {
            $alreadyManaged++
            if ($isAgentsRoot -and -not $KeepAgentsSource) {
                try {
                    if (Test-LinkTargetsPath -LinkPath $skillDir.FullName -ExpectedTarget $canonical) {
                        Write-Host "[OK]   Already managed: $skillName"
                    }
                    else {
                        $sourceItem = Get-Item $skillDir.FullName -Force
                        if ($sourceItem.LinkType -eq "Junction" -or $sourceItem.LinkType -eq "SymbolicLink") {
                            Write-Warning "Managed skill source links somewhere else; not changed: $skillName"
                        }
                        elseif ((Get-DirectoryFingerprint $skillDir.FullName) -eq (Get-DirectoryFingerprint $canonical)) {
                            if ($PSCmdlet.ShouldProcess($skillDir.FullName, "Replace duplicate real directory with junction to $canonical")) {
                                Convert-AgentsSourceToJunction -SourcePath $skillDir.FullName -TargetPath $canonical -SkillName $skillName
                            }
                        }
                        else {
                            Write-Warning "Managed skill differs from active Agents copy; not replacing either side: $skillName"
                        }
                    }
                }
                catch {
                    Write-Warning $_.Exception.Message
                    $failed++
                }
            }
            else {
                Write-Host "[OK]   Already managed: $skillName"
            }
            continue
        }

        if ($seenNames.ContainsKey($skillName)) {
            Write-Warning "Skill '$skillName' was already discovered at '$($seenNames[$skillName])'. Additional copy skipped: $($skillDir.FullName)"
            $duplicates++
            continue
        }
        $seenNames[$skillName] = $skillDir.FullName

        $sourceItem = Get-Item $skillDir.FullName -Force
        if ($sourceItem.LinkType -eq "Junction" -or $sourceItem.LinkType -eq "SymbolicLink") {
            $pointsIntoRepo = $false
            foreach ($target in @($sourceItem.Target)) {
                if (-not [string]::IsNullOrWhiteSpace([string]$target) -and (Test-PathUnder -Child ([string]$target) -Parent $SkillsRoot)) {
                    $pointsIntoRepo = $true
                    break
                }
            }
            if ($pointsIntoRepo) {
                Write-Warning "Link points into AI_MEMORY but canonical directory was not found as expected. Skipped: $($skillDir.FullName)"
            }
            else {
                Write-Warning "External linked skill is not imported automatically for safety: $($skillDir.FullName)"
            }
            $skipped++
            continue
        }

        try {
            if ($PSCmdlet.ShouldProcess($skillDir.FullName, "Import skill '$skillName' into AI_MEMORY")) {
                Copy-SkillVerified -Source $skillDir.FullName -Destination $canonical -SkillName $skillName
                Write-Host "[IMPORT] $skillName <- $($skillDir.FullName)"
                $imported++
                if ($isAgentsRoot) {
                    Convert-AgentsSourceToJunction -SourcePath $skillDir.FullName -TargetPath $canonical -SkillName $skillName
                }
            }
        }
        catch {
            Write-Warning ("Failed to import {0}: {1}" -f $skillName, $_.Exception.Message)
            $failed++
        }
    }
}

Write-Host ""
Write-Host "=== Import Summary ==="
Write-Host "Imported        : $imported"
Write-Host "Already managed : $alreadyManaged"
Write-Host "Duplicate names : $duplicates"
Write-Host "Skipped         : $skipped"
Write-Host "Failed          : $failed"
Write-Host ""

if ($failed -gt 0) {
    Write-Host "RESULT=FAIL" -ForegroundColor Red
    exit 1
}

Write-Host "RESULT=PASS"
Write-Host "Next: review 'git status', commit the newly imported skills, then run setup.ps1 and doctor.ps1."
exit 0
