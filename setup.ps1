# AI_MEMORY setup
# - Registers AI_MEMORY_HOME to this repository root.
# - Creates Junctions so supported coding agents share one agent-memory skill.
# - Safe to run repeatedly.

$ErrorActionPreference = "Stop"

$RepoRoot = (Resolve-Path $PSScriptRoot).Path
$SkillSource = Join-Path $RepoRoot "skills\agent-memory"

Write-Host ""
Write-Host "=== AI_MEMORY Setup ==="
Write-Host "Repository : $RepoRoot"
Write-Host ""

# 1) Validate repository
$requiredPaths = @(
    (Join-Path $RepoRoot "skills"),
    $SkillSource,
    (Join-Path $SkillSource "SKILL.md")
)

foreach ($requiredPath in $requiredPaths) {
    if (-not (Test-Path $requiredPath)) {
        Write-Error "Required path not found: $requiredPath"
        exit 1
    }
}

# 2) Register/update AI_MEMORY_HOME
$currentHome = [Environment]::GetEnvironmentVariable("AI_MEMORY_HOME", "User")

if ($currentHome -eq $RepoRoot) {
    Write-Host "[OK] AI_MEMORY_HOME already registered: $currentHome"
}
else {
    if ([string]::IsNullOrWhiteSpace($currentHome)) {
        Write-Host "[SET] Registering AI_MEMORY_HOME..."
    }
    else {
        Write-Host "[UPDATE] AI_MEMORY_HOME"
        Write-Host "         Old: $currentHome"
        Write-Host "         New: $RepoRoot"
    }

    [Environment]::SetEnvironmentVariable(
        "AI_MEMORY_HOME",
        $RepoRoot,
        "User"
    )

    Write-Host "[OK] AI_MEMORY_HOME=$RepoRoot"
}

# Make it available immediately in this PowerShell session too.
$env:AI_MEMORY_HOME = $RepoRoot

# 3) Global skill locations
# Codex and Cursor both discover user-level skills from ~/.agents/skills.
$junctions = [ordered]@{
    "Codex + Cursor" = Join-Path $HOME ".agents\skills\agent-memory"
    "Claude Code"    = Join-Path $HOME ".claude\skills\agent-memory"
    "Antigravity"    = Join-Path $HOME ".gemini\config\skills\agent-memory"
}

function Ensure-Junction {
    param(
        [Parameter(Mandatory = $true)]
        [string]$AgentName,

        [Parameter(Mandatory = $true)]
        [string]$JunctionPath,

        [Parameter(Mandatory = $true)]
        [string]$TargetPath
    )

    $parent = Split-Path $JunctionPath -Parent

    if (-not (Test-Path $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }

    if (Test-Path $JunctionPath) {
        $item = Get-Item $JunctionPath -Force

        if ($item.LinkType -eq "Junction" -or $item.LinkType -eq "SymbolicLink") {
            $targets = @($item.Target)
            $resolvedTarget = $null

            foreach ($target in $targets) {
                try {
                    $resolvedTarget = (Resolve-Path $target -ErrorAction Stop).Path
                    break
                }
                catch {
                    # Continue checking target entries.
                }
            }

            if ($resolvedTarget -eq $TargetPath) {
                Write-Host "[OK] $AgentName already linked"
                Write-Host "     $JunctionPath -> $TargetPath"
                return
            }

            Write-Warning "$AgentName skill path is already a link to another target. Skipped."
            Write-Warning "Path   : $JunctionPath"
            Write-Warning "Target : $($item.Target -join ', ')"
            return
        }

        Write-Warning "$AgentName skill path already exists as a real file/folder. Skipped to avoid deleting data."
        Write-Warning "Path: $JunctionPath"
        return
    }

    New-Item `
        -ItemType Junction `
        -Path $JunctionPath `
        -Target $TargetPath | Out-Null

    Write-Host "[OK] $AgentName linked"
    Write-Host "     $JunctionPath -> $TargetPath"
}

Write-Host ""
Write-Host "=== Creating Agent Skill Junctions ==="

foreach ($entry in $junctions.GetEnumerator()) {
    Ensure-Junction `
        -AgentName $entry.Key `
        -JunctionPath $entry.Value `
        -TargetPath $SkillSource
}

Write-Host ""
Write-Host "=== Setup Complete ==="
Write-Host "AI_MEMORY_HOME : $RepoRoot"
Write-Host "Shared skill   : $SkillSource"
Write-Host ""
Write-Host "Restart agents if the skill is not discovered immediately."
