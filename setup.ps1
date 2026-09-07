# AI_MEMORY setup
# - 현재 저장소 경로를 AI_MEMORY_HOME 사용자 환경변수로 등록합니다.
# - skills 하위의 SKILL.md 보유 폴더를 전역 스킬로 자동 탐색합니다.
# - Codex/Cursor, Claude Code, Antigravity의 전역 스킬 경로에 Junction을 생성합니다.
# - 여러 번 실행해도 안전하도록 설계되어 있습니다.

$ErrorActionPreference = "Stop"

$RepoRoot = (Resolve-Path $PSScriptRoot).Path
$SkillsRoot = Join-Path $RepoRoot "skills"

Write-Host ""
Write-Host "=== AI_MEMORY Setup ==="
Write-Host "Repository : $RepoRoot"
Write-Host ""

# 1) 저장소 기본 구조 확인
if (-not (Test-Path $SkillsRoot -PathType Container)) {
    Write-Error "필수 폴더를 찾을 수 없습니다: $SkillsRoot"
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

    [Environment]::SetEnvironmentVariable(
        "AI_MEMORY_HOME",
        $RepoRoot,
        "User"
    )

    Write-Host "[OK] AI_MEMORY_HOME=$RepoRoot"
}

# 현재 PowerShell 세션에도 즉시 반영
$env:AI_MEMORY_HOME = $RepoRoot

function Get-ResolvedPathOrNull {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    try {
        return (Resolve-Path $Path -ErrorAction Stop).Path
    }
    catch {
        return $null
    }
}

function Test-SamePath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$PathA,

        [Parameter(Mandatory = $true)]
        [string]$PathB
    )

    $resolvedA = Get-ResolvedPathOrNull -Path $PathA
    $resolvedB = Get-ResolvedPathOrNull -Path $PathB

    if ($null -eq $resolvedA -or $null -eq $resolvedB) {
        return $false
    }

    return $resolvedA.TrimEnd('\') -ieq $resolvedB.TrimEnd('\')
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

            foreach ($target in $targets) {
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

    New-Item `
        -ItemType Junction `
        -Path $JunctionPath `
        -Target $TargetPath | Out-Null

    Write-Host "[OK] $AgentName / $(Split-Path $JunctionPath -Leaf) 연결 완료"
    Write-Host "     $JunctionPath -> $TargetPath"
}

function Remove-LegacyJunctionIfOwned {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [string]$ExpectedTarget
    )

    if (-not (Test-Path $Path)) {
        return
    }

    $item = Get-Item $Path -Force

    if ($item.LinkType -ne "Junction" -and $item.LinkType -ne "SymbolicLink") {
        return
    }

    foreach ($target in @($item.Target)) {
        if (Test-SamePath -PathA $target -PathB $ExpectedTarget) {
            Remove-Item $Path -Force
            Write-Host "[CLEAN] 이전 설치 경로 정리: $Path"
            return
        }
    }
}

# 3) 전역 스킬 자동 탐색
$skillDirectories = @(
    Get-ChildItem -Path $SkillsRoot -Directory |
        Where-Object { Test-Path (Join-Path $_.FullName "SKILL.md") } |
        Sort-Object Name
)

Write-Host ""
Write-Host "=== Global Skills ==="

if ($skillDirectories.Count -eq 0) {
    Write-Host "[INFO] skills 하위에서 SKILL.md를 가진 스킬을 찾지 못했습니다."
    Write-Host "       스킬이 추가된 뒤 setup.ps1을 다시 실행하면 자동 연결됩니다."
}
else {
    Write-Host "발견된 전역 스킬: $($skillDirectories.Count)개"
    foreach ($skill in $skillDirectories) {
        Write-Host " - $($skill.Name)"
    }
}

# 4) Agent별 전역 스킬 Root
# Codex와 Cursor는 ~/.agents/skills 를 함께 사용합니다.
$agentSkillRoots = [ordered]@{
    "Codex + Cursor" = Join-Path $HOME ".agents\skills"
    "Claude Code"    = Join-Path $HOME ".claude\skills"
    "Antigravity"    = Join-Path $HOME ".gemini\config\skills"
}

# 이전 setup.ps1에서 생성했던 agent-memory 전용 경로 정리
$agentMemorySource = Join-Path $SkillsRoot "agent-memory"
if (Test-Path $agentMemorySource) {
    Remove-LegacyJunctionIfOwned `
        -Path (Join-Path $HOME ".codex\skills\agent-memory") `
        -ExpectedTarget $agentMemorySource

    Remove-LegacyJunctionIfOwned `
        -Path (Join-Path $HOME ".cursor\skills\agent-memory") `
        -ExpectedTarget $agentMemorySource
}

# 5) 모든 전역 스킬 Junction 생성
if ($skillDirectories.Count -gt 0) {
    Write-Host ""
    Write-Host "=== Creating Skill Junctions ==="

    foreach ($skill in $skillDirectories) {
        foreach ($agent in $agentSkillRoots.GetEnumerator()) {
            $junctionPath = Join-Path $agent.Value $skill.Name

            Ensure-Junction `
                -AgentName $agent.Key `
                -JunctionPath $junctionPath `
                -TargetPath $skill.FullName
        }
    }
}

Write-Host ""
Write-Host "=== Setup Complete ==="
Write-Host "AI_MEMORY_HOME : $RepoRoot"
Write-Host "Skills Root    : $SkillsRoot"
Write-Host "Global Skills  : $($skillDirectories.Count)"
Write-Host ""
Write-Host "실행 중이던 Agent가 스킬을 즉시 찾지 못하면 해당 Agent를 재시작하세요."
