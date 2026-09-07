# AI_MEMORY setup
# Windows PowerShell 5.1 compatible and ASCII-only by design.
# - Registers AI_MEMORY_HOME.
# - Detects installed agents only.
# - Links shared skills only for installed agents.
# - Deploys the shared global instruction without overwriting user content.

$ErrorActionPreference = "Stop"

$RepoRoot = (Resolve-Path $PSScriptRoot).Path
$SkillsRoot = Join-Path $RepoRoot "skills"
$GlobalInstructionSource = Join-Path $RepoRoot "instructions\GLOBAL_AGENT_INSTRUCTIONS.md"
$ManagedStart = "<!-- AI_MEMORY_MANAGED_START -->"
$ManagedEnd = "<!-- AI_MEMORY_MANAGED_END -->"

function Normalize-ComparablePath {
    param([Parameter(Mandatory = $true)][string]$Path)
    return $Path.TrimEnd([char[]]"\/")
}

function Get-ResolvedPathOrNull {
    param([Parameter(Mandatory = $true)][string]$Path)
    try { return (Resolve-Path $Path -ErrorAction Stop).Path }
    catch { return $null }
}

function Test-SamePath {
    param(
        [Parameter(Mandatory = $true)][string]$PathA,
        [Parameter(Mandatory = $true)][string]$PathB
    )

    $a = Get-ResolvedPathOrNull -Path $PathA
    $b = Get-ResolvedPathOrNull -Path $PathB
    if ($null -eq $a -or $null -eq $b) { return $false }
    return (Normalize-ComparablePath $a) -ieq (Normalize-ComparablePath $b)
}

function Test-CommandExists {
    param([Parameter(Mandatory = $true)][string]$Name)
    return $null -ne (Get-Command $Name -ErrorAction SilentlyContinue)
}

function Test-AnyPath {
    param([string[]]$Paths = @())
    foreach ($path in $Paths) {
        if (-not [string]::IsNullOrWhiteSpace($path) -and (Test-Path $path)) {
            return $true
        }
    }
    return $false
}

function Test-AgentInstalled {
    param(
        [string[]]$Commands = @(),
        [string[]]$EvidencePaths = @()
    )

    foreach ($command in $Commands) {
        if (Test-CommandExists $command) { return $true }
    }
    return Test-AnyPath $EvidencePaths
}

function Ensure-Junction {
    param(
        [Parameter(Mandatory = $true)][string]$AgentName,
        [Parameter(Mandatory = $true)][string]$JunctionPath,
        [Parameter(Mandatory = $true)][string]$TargetPath
    )

    $parent = Split-Path $JunctionPath -Parent
    if (-not (Test-Path $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }

    if (Test-Path $JunctionPath) {
        $item = Get-Item $JunctionPath -Force
        if ($item.LinkType -eq "Junction" -or $item.LinkType -eq "SymbolicLink") {
            foreach ($target in @($item.Target)) {
                if (Test-SamePath -PathA $target -PathB $TargetPath) {
                    Write-Host "[OK]   $AgentName skill already linked: $($item.Name)"
                    return
                }
            }
            Write-Warning "$AgentName has a different link at: $JunctionPath"
            return
        }

        Write-Warning "$AgentName has a real file/directory at: $JunctionPath"
        return
    }

    New-Item -ItemType Junction -Path $JunctionPath -Target $TargetPath | Out-Null
    Write-Host "[OK]   $AgentName skill linked: $(Split-Path $JunctionPath -Leaf)"
}

function Remove-LegacyJunctionIfOwned {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$ExpectedTarget
    )

    if (-not (Test-Path $Path)) { return }
    $item = Get-Item $Path -Force
    if ($item.LinkType -ne "Junction" -and $item.LinkType -ne "SymbolicLink") { return }

    foreach ($target in @($item.Target)) {
        if (Test-SamePath -PathA $target -PathB $ExpectedTarget) {
            Remove-Item $Path -Force
            Write-Host "[CLEAN] Removed legacy AI_MEMORY junction: $Path"
            return
        }
    }
}

function Set-ManagedInstructionBlock {
    param(
        [Parameter(Mandatory = $true)][string]$AgentName,
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Content
    )

    $parent = Split-Path $Path -Parent
    if (-not (Test-Path $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }

    $block = "$ManagedStart`r`n$Content`r`n$ManagedEnd"
    $existing = if (Test-Path $Path) { Get-Content $Path -Raw -Encoding UTF8 } else { "" }
    $startIndex = $existing.IndexOf($ManagedStart)
    $endIndex = $existing.IndexOf($ManagedEnd)

    if ($startIndex -ge 0 -and $endIndex -gt $startIndex) {
        $endIndex += $ManagedEnd.Length
        $newContent = $existing.Substring(0, $startIndex) + $block + $existing.Substring($endIndex)
        Write-Host "[UPDATE] $AgentName global instruction"
    }
    elseif ($startIndex -ge 0 -or $endIndex -ge 0) {
        Write-Warning "$AgentName instruction has an incomplete AI_MEMORY marker. Skipped: $Path"
        return
    }
    elseif ([string]::IsNullOrWhiteSpace($existing)) {
        $newContent = $block + "`r`n"
        Write-Host "[SET]  $AgentName global instruction"
    }
    else {
        $newContent = $existing.TrimEnd() + "`r`n`r`n" + $block + "`r`n"
        Write-Host "[ADD]  $AgentName AI_MEMORY instruction block"
    }

    [IO.File]::WriteAllText($Path, $newContent, (New-Object Text.UTF8Encoding($false)))
}

function Set-CursorManagedRule {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Content
    )

    $parent = Split-Path $Path -Parent
    if (-not (Test-Path $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }

    $generated = @"
---
description: "Use AI_MEMORY shared engineering memory and tools. Recall automatically for relevant work; learn only on explicit user request."
alwaysApply: true
---
$ManagedStart
$Content
$ManagedEnd
"@

    if (Test-Path $Path) {
        $existing = Get-Content $Path -Raw -Encoding UTF8
        if (-not $existing.Contains($ManagedStart) -or -not $existing.Contains($ManagedEnd)) {
            Write-Warning "Cursor rule exists but is not managed by AI_MEMORY. Skipped: $Path"
            return
        }
        Write-Host "[UPDATE] Cursor global rule"
    }
    else {
        Write-Host "[SET]  Cursor global rule"
    }

    [IO.File]::WriteAllText($Path, $generated.Trim() + "`r`n", (New-Object Text.UTF8Encoding($false)))
}

Write-Host ""
Write-Host "=== AI_MEMORY Setup ==="
Write-Host "Repository: $RepoRoot"
Write-Host ""

if (-not (Test-Path $SkillsRoot -PathType Container)) {
    Write-Error "Required directory not found: $SkillsRoot"
    exit 1
}
if (-not (Test-Path $GlobalInstructionSource -PathType Leaf)) {
    Write-Error "Global instruction source not found: $GlobalInstructionSource"
    exit 1
}

$currentHome = [Environment]::GetEnvironmentVariable("AI_MEMORY_HOME", "User")
if ([string]::IsNullOrWhiteSpace($currentHome) -or -not (Test-SamePath -PathA $currentHome -PathB $RepoRoot)) {
    [Environment]::SetEnvironmentVariable("AI_MEMORY_HOME", $RepoRoot, "User")
    Write-Host "[SET]  AI_MEMORY_HOME=$RepoRoot"
}
else {
    Write-Host "[OK]   AI_MEMORY_HOME=$currentHome"
}
$env:AI_MEMORY_HOME = $RepoRoot

$codexHome = if (-not [string]::IsNullOrWhiteSpace($env:CODEX_HOME)) { $env:CODEX_HOME } else { Join-Path $HOME ".codex" }
$claudeHome = if (-not [string]::IsNullOrWhiteSpace($env:CLAUDE_CONFIG_DIR)) { $env:CLAUDE_CONFIG_DIR } else { Join-Path $HOME ".claude" }
$cursorHome = Join-Path $HOME ".cursor"
$geminiHome = Join-Path $HOME ".gemini"
$antigravityConfigHome = Join-Path $geminiHome "config"

$codexEvidence = @((Join-Path $codexHome "config.toml"))
$claudeEvidence = @((Join-Path $claudeHome "settings.json"))
$cursorEvidence = @()
$antigravityEvidence = @((Join-Path $geminiHome "antigravity"), (Join-Path $geminiHome "antigravity-cli\settings.json"))

if (-not [string]::IsNullOrWhiteSpace($env:LOCALAPPDATA)) {
    $cursorEvidence += (Join-Path $env:LOCALAPPDATA "Programs\cursor\Cursor.exe")
    $antigravityEvidence += (Join-Path $env:LOCALAPPDATA "agy\bin\agy.exe")
    $antigravityEvidence += (Join-Path $env:LOCALAPPDATA "Programs\Antigravity\Antigravity.exe")
}
if (-not [string]::IsNullOrWhiteSpace($env:ProgramFiles)) {
    $cursorEvidence += (Join-Path $env:ProgramFiles "Cursor\Cursor.exe")
    $antigravityEvidence += (Join-Path $env:ProgramFiles "Google\antigravity-cli\agy.exe")
    $antigravityEvidence += (Join-Path $env:ProgramFiles "Antigravity\Antigravity.exe")
}

$codexInstalled = Test-AgentInstalled -Commands @("codex") -EvidencePaths $codexEvidence
$cursorInstalled = Test-AgentInstalled -Commands @("agent") -EvidencePaths $cursorEvidence
$claudeInstalled = Test-AgentInstalled -Commands @("claude") -EvidencePaths $claudeEvidence
$antigravityInstalled = Test-AgentInstalled -Commands @("agy") -EvidencePaths $antigravityEvidence

Write-Host "=== Agent Detection ==="
$agentStatus = [ordered]@{
    "Codex" = $codexInstalled
    "Cursor" = $cursorInstalled
    "Claude Code" = $claudeInstalled
    "Antigravity" = $antigravityInstalled
}
foreach ($agent in $agentStatus.GetEnumerator()) {
    if ($agent.Value) { Write-Host "[OK]   $($agent.Key) detected" }
    else { Write-Host "[SKIP] $($agent.Key) not detected" }
}

$skillDirectories = @(
    Get-ChildItem -Path $SkillsRoot -Directory |
        Where-Object { Test-Path (Join-Path $_.FullName "SKILL.md") } |
        Sort-Object Name
)

Write-Host ""
Write-Host "=== Global Skills ==="
Write-Host "Detected skills: $($skillDirectories.Count)"
foreach ($skill in $skillDirectories) { Write-Host " - $($skill.Name)" }

$agentSkillRoots = [ordered]@{}
if ($codexInstalled -or $cursorInstalled) { $agentSkillRoots["Codex + Cursor"] = Join-Path $HOME ".agents\skills" }
if ($claudeInstalled) { $agentSkillRoots["Claude Code"] = Join-Path $claudeHome "skills" }
if ($antigravityInstalled) { $agentSkillRoots["Antigravity"] = Join-Path $antigravityConfigHome "skills" }

$agentMemorySource = Join-Path $SkillsRoot "agent-memory"
if (Test-Path $agentMemorySource) {
    if ($codexInstalled) {
        Remove-LegacyJunctionIfOwned -Path (Join-Path $codexHome "skills\agent-memory") -ExpectedTarget $agentMemorySource
    }
    if ($cursorInstalled) {
        Remove-LegacyJunctionIfOwned -Path (Join-Path $cursorHome "skills\agent-memory") -ExpectedTarget $agentMemorySource
    }
}

if ($skillDirectories.Count -gt 0 -and $agentSkillRoots.Count -gt 0) {
    Write-Host ""
    Write-Host "=== Skill Junctions ==="
    foreach ($skill in $skillDirectories) {
        foreach ($agent in $agentSkillRoots.GetEnumerator()) {
            Ensure-Junction -AgentName $agent.Key -JunctionPath (Join-Path $agent.Value $skill.Name) -TargetPath $skill.FullName
        }
    }
}
else {
    Write-Host "[SKIP] No skill junction work required."
}

Write-Host ""
Write-Host "=== Global Instructions ==="
$globalInstruction = (Get-Content $GlobalInstructionSource -Raw -Encoding UTF8).Trim()

if ($codexInstalled) {
    Set-ManagedInstructionBlock -AgentName "Codex" -Path (Join-Path $codexHome "AGENTS.md") -Content $globalInstruction
} else { Write-Host "[SKIP] Codex global instruction" }

if ($cursorInstalled) {
    Set-CursorManagedRule -Path (Join-Path $cursorHome "rules\ai-memory.mdc") -Content $globalInstruction
} else { Write-Host "[SKIP] Cursor global instruction" }

if ($claudeInstalled) {
    Set-ManagedInstructionBlock -AgentName "Claude Code" -Path (Join-Path $claudeHome "CLAUDE.md") -Content $globalInstruction
} else { Write-Host "[SKIP] Claude Code global instruction" }

if ($antigravityInstalled) {
    Set-ManagedInstructionBlock -AgentName "Antigravity" -Path (Join-Path $geminiHome "GEMINI.md") -Content $globalInstruction
} else { Write-Host "[SKIP] Antigravity global instruction" }

Write-Host ""
Write-Host "=== Setup Complete ==="
Write-Host "AI_MEMORY_HOME: $RepoRoot"
Write-Host "Global skills: $($skillDirectories.Count)"
Write-Host "Restart running agents if they do not detect the changes immediately."
