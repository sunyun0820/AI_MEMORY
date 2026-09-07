# AI_MEMORY setup
# - 현재 저장소 경로를 AI_MEMORY_HOME 사용자 환경변수로 등록합니다.
# - 설치된 Agent만 감지하여 전역 Skill과 전역 지침을 구성합니다.
# - 존재하지 않는 Agent의 설정 폴더는 생성하지 않습니다.
# - skills 하위의 SKILL.md 보유 폴더를 전역 스킬로 자동 연결합니다.
# - instructions/GLOBAL_AGENT_INSTRUCTIONS.md를 각 Agent의 전역 지침에 관리 블록으로 반영합니다.
# - 기존 사용자 지침은 보존하며, AI_MEMORY가 관리하는 블록만 갱신합니다.
# - 여러 번 실행해도 안전하도록 설계되어 있습니다.

$ErrorActionPreference = "Stop"

$RepoRoot = (Resolve-Path $PSScriptRoot).Path
$SkillsRoot = Join-Path $RepoRoot "skills"
$InstructionsRoot = Join-Path $RepoRoot "instructions"
$GlobalInstructionSource = Join-Path $InstructionsRoot "GLOBAL_AGENT_INSTRUCTIONS.md"

$ManagedStart = "<!-- AI_MEMORY_MANAGED_START -->"
$ManagedEnd = "<!-- AI_MEMORY_MANAGED_END -->"

Write-Host ""
Write-Host "=== AI_MEMORY Setup ==="
Write-Host "Repository : $RepoRoot"
Write-Host ""

# 1) 저장소 기본 구조 확인
if (-not (Test-Path $SkillsRoot -PathType Container)) {
    Write-Error "필수 폴더를 찾을 수 없습니다: $SkillsRoot"
    exit 1
}

if (-not (Test-Path $GlobalInstructionSource -PathType Leaf)) {
    Write-Error "전역 지침 원본을 찾을 수 없습니다: $GlobalInstructionSource"
    exit 1
}

# 2) AI_MEMORY_HOME 등록/갱신
$currentHome = [Environment]::GetEnvironmentVariable("AI_MEMORY_HOME", "User")

if ($currentHome -eq $RepoRoot) {
    Write-Host "[OK] AI_MEMORY_HOME 이미 등록됨: $currentHome"
}
else {
    if ([string]::IsNullOrWhiteSpace($currentHome)) {
        Write-Host "[SET] AI_MEMORY_HOME 등록 중..."
    }
    else {
        Write-Host "[UPDATE] AI_MEMORY_HOME 경로 변경"
        Write-Host "         기존: $currentHome"
        Write-Host "         신규: $RepoRoot"
    }

    [Environment]::SetEnvironmentVariable("AI_MEMORY_HOME", $RepoRoot, "User")
    Write-Host "[OK] AI_MEMORY_HOME=$RepoRoot"
}

$env:AI_MEMORY_HOME = $RepoRoot

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

    $resolvedA = Get-ResolvedPathOrNull -Path $PathA
    $resolvedB = Get-ResolvedPathOrNull -Path $PathB

    if ($null -eq $resolvedA -or $null -eq $resolvedB) { return $false }
    return $resolvedA.TrimEnd('\') -ieq $resolvedB.TrimEnd('\')
}

function Test-AgentInstalled {
    param(
        [string[]]$Commands = @(),
        [string[]]$EvidencePaths = @()
    )

    foreach ($command in $Commands) {
        if (Get-Command $command -ErrorAction SilentlyContinue) {
            return $true
        }
    }

    foreach ($path in $EvidencePaths) {
        if (-not [string]::IsNullOrWhiteSpace($path) -and (Test-Path $path)) {
            return $true
        }
    }

    return $false
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
                    Write-Host "[OK] $AgentName / $($item.Name) 이미 연결됨"
                    return
                }
            }

            Write-Warning "$AgentName 경로에 다른 Link가 존재하여 건너뜁니다."
            Write-Warning "Path   : $JunctionPath"
            Write-Warning "Target : $($item.Target -join ', ')"
            return
        }

        Write-Warning "$AgentName 경로에 실제 파일/폴더가 존재하여 건너뜁니다."
        Write-Warning "Path: $JunctionPath"
        return
    }

    New-Item -ItemType Junction -Path $JunctionPath -Target $TargetPath | Out-Null
    Write-Host "[OK] $AgentName / $(Split-Path $JunctionPath -Leaf) 연결 완료"
    Write-Host "     $JunctionPath -> $TargetPath"
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
            Write-Host "[CLEAN] 이전 설치 경로 정리: $Path"
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
        Write-Host "[UPDATE] $AgentName 전역 지침 갱신"
    }
    elseif ($startIndex -ge 0 -or $endIndex -ge 0) {
        Write-Warning "$AgentName 전역 지침에 불완전한 AI_MEMORY 관리 마커가 있어 건너뜁니다: $Path"
        return
    }
    elseif ([string]::IsNullOrWhiteSpace($existing)) {
        $newContent = $block + "`r`n"
        Write-Host "[SET] $AgentName 전역 지침 생성"
    }
    else {
        $newContent = $existing.TrimEnd() + "`r`n`r`n" + $block + "`r`n"
        Write-Host "[ADD] $AgentName 기존 전역 지침에 AI_MEMORY 블록 추가"
    }

    [IO.File]::WriteAllText($Path, $newContent, [Text.UTF8Encoding]::new($false))
    Write-Host "     $Path"
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
description: "Use AI_MEMORY shared engineering memory: automatic Recall before relevant non-trivial work, manual Learn only on explicit user request."
alwaysApply: true
---
$ManagedStart
$Content
$ManagedEnd
"@

    if (Test-Path $Path) {
        $existing = Get-Content $Path -Raw -Encoding UTF8
        if (-not $existing.Contains($ManagedStart) -or -not $existing.Contains($ManagedEnd)) {
            Write-Warning "Cursor 전역 Rule 파일이 존재하지만 AI_MEMORY 관리 파일이 아니어서 덮어쓰지 않습니다: $Path"
            return
        }
        Write-Host "[UPDATE] Cursor 전역 Rule 갱신"
    }
    else {
        Write-Host "[SET] Cursor 전역 Rule 생성"
    }

    [IO.File]::WriteAllText($Path, $generated.Trim() + "`r`n", [Text.UTF8Encoding]::new($false))
    Write-Host "     $Path"
}

# 3) 설치된 Agent 감지
$codexHome = if (-not [string]::IsNullOrWhiteSpace($env:CODEX_HOME)) { $env:CODEX_HOME } else { Join-Path $HOME ".codex" }
$claudeHome = if (-not [string]::IsNullOrWhiteSpace($env:CLAUDE_CONFIG_DIR)) { $env:CLAUDE_CONFIG_DIR } else { Join-Path $HOME ".claude" }
$cursorHome = Join-Path $HOME ".cursor"
$geminiHome = Join-Path $HOME ".gemini"
$antigravityConfigHome = Join-Path $geminiHome "config"

$cursorAppPaths = @($cursorHome)
$antigravityEvidence = @($antigravityConfigHome, (Join-Path $geminiHome "antigravity"))

if (-not [string]::IsNullOrWhiteSpace($env:LOCALAPPDATA)) {
    $cursorAppPaths += (Join-Path $env:LOCALAPPDATA "Programs\cursor\Cursor.exe")
    $antigravityEvidence += (Join-Path $env:LOCALAPPDATA "Programs\Antigravity\Antigravity.exe")
}

if (-not [string]::IsNullOrWhiteSpace($env:ProgramFiles)) {
    $cursorAppPaths += (Join-Path $env:ProgramFiles "Cursor\Cursor.exe")
    $antigravityEvidence += (Join-Path $env:ProgramFiles "Antigravity\Antigravity.exe")
}

$codexInstalled = Test-AgentInstalled -Commands @("codex") -EvidencePaths @($codexHome)
$cursorInstalled = Test-AgentInstalled -Commands @("cursor") -EvidencePaths $cursorAppPaths
$claudeInstalled = Test-AgentInstalled -Commands @("claude") -EvidencePaths @($claudeHome)
$antigravityInstalled = Test-AgentInstalled -Commands @("antigravity") -EvidencePaths $antigravityEvidence

Write-Host ""
Write-Host "=== Agent Detection ==="

$agentStatus = [ordered]@{
    "Codex"       = $codexInstalled
    "Cursor"      = $cursorInstalled
    "Claude Code" = $claudeInstalled
    "Antigravity" = $antigravityInstalled
}

foreach ($agent in $agentStatus.GetEnumerator()) {
    if ($agent.Value) {
        Write-Host "[OK]   $($agent.Key) 발견"
    }
    else {
        Write-Host "[SKIP] $($agent.Key) 설치 흔적 없음"
    }
}

# 4) 전역 스킬 자동 탐색
$skillDirectories = @(
    Get-ChildItem -Path $SkillsRoot -Directory |
        Where-Object { Test-Path (Join-Path $_.FullName "SKILL.md") } |
        Sort-Object Name
)

Write-Host ""
Write-Host "=== Global Skills ==="

if ($skillDirectories.Count -eq 0) {
    Write-Host "[INFO] skills 하위에서 SKILL.md를 가진 스킬을 찾지 못했습니다."
}
else {
    Write-Host "발견된 전역 스킬: $($skillDirectories.Count)개"
    foreach ($skill in $skillDirectories) { Write-Host " - $($skill.Name)" }
}

# Codex와 Cursor는 ~/.agents/skills 를 공용으로 사용합니다.
$agentSkillRoots = [ordered]@{}

if ($codexInstalled -or $cursorInstalled) {
    $agentSkillRoots["Codex + Cursor"] = Join-Path $HOME ".agents\skills"
}

if ($claudeInstalled) {
    $agentSkillRoots["Claude Code"] = Join-Path $claudeHome "skills"
}

if ($antigravityInstalled) {
    $agentSkillRoots["Antigravity"] = Join-Path $antigravityConfigHome "skills"
}

# 이전 초기 setup이 만든 agent-memory 전용 경로는 해당 Agent가 현재 설치된 경우에만 정리합니다.
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
    Write-Host "=== Creating Skill Junctions ==="

    foreach ($skill in $skillDirectories) {
        foreach ($agent in $agentSkillRoots.GetEnumerator()) {
            Ensure-Junction -AgentName $agent.Key -JunctionPath (Join-Path $agent.Value $skill.Name) -TargetPath $skill.FullName
        }
    }
}
elseif ($agentSkillRoots.Count -eq 0) {
    Write-Host "[SKIP] 구성할 Agent가 없어 Skill Junction 생성을 건너뜁니다."
}

# 5) 단일 원본 전역 지침을 설치된 Agent에만 배포
Write-Host ""
Write-Host "=== Global Instructions ==="
$globalInstruction = (Get-Content $GlobalInstructionSource -Raw -Encoding UTF8).Trim()

if ($codexInstalled) {
    Set-ManagedInstructionBlock -AgentName "Codex" -Path (Join-Path $codexHome "AGENTS.md") -Content $globalInstruction
}
else {
    Write-Host "[SKIP] Codex 전역 지침"
}

if ($cursorInstalled) {
    Set-CursorManagedRule -Path (Join-Path $cursorHome "rules\ai-memory.mdc") -Content $globalInstruction
}
else {
    Write-Host "[SKIP] Cursor 전역 지침"
}

if ($claudeInstalled) {
    Set-ManagedInstructionBlock -AgentName "Claude Code" -Path (Join-Path $claudeHome "CLAUDE.md") -Content $globalInstruction
}
else {
    Write-Host "[SKIP] Claude Code 전역 지침"
}

if ($antigravityInstalled) {
    Set-ManagedInstructionBlock -AgentName "Antigravity" -Path (Join-Path $geminiHome "GEMINI.md") -Content $globalInstruction
}
else {
    Write-Host "[SKIP] Antigravity 전역 지침"
}

$installedAgentCount = @($agentStatus.GetEnumerator() | Where-Object { $_.Value }).Count

Write-Host ""
Write-Host "=== Setup Complete ==="
Write-Host "AI_MEMORY_HOME       : $RepoRoot"
Write-Host "Detected Agents      : $installedAgentCount"
Write-Host "Global Skills        : $($skillDirectories.Count)"
Write-Host "Global Instructions  : $GlobalInstructionSource"
Write-Host ""
Write-Host "설치되지 않은 Agent는 변경하지 않았습니다."
Write-Host "실행 중이던 Agent가 변경사항을 즉시 반영하지 못하면 해당 Agent를 재시작하세요."
