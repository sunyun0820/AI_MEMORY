# AI_MEMORY Doctor
# - AI_MEMORY 설치/연결 상태를 진단합니다.
# - 설치되지 않은 Agent는 실패가 아니라 SKIP으로 처리합니다.
# - 영구 설정을 변경하지 않습니다.

$ErrorActionPreference = "Stop"

$RepoRoot = (Resolve-Path $PSScriptRoot).Path
$ManagedStart = "<!-- AI_MEMORY_MANAGED_START -->"
$ManagedEnd = "<!-- AI_MEMORY_MANAGED_END -->"

$script:OkCount = 0
$script:WarnCount = 0
$script:FailCount = 0
$script:SkipCount = 0

function Write-DoctorResult {
    param(
        [Parameter(Mandatory = $true)][ValidateSet("OK", "WARN", "FAIL", "SKIP")][string]$Status,
        [Parameter(Mandatory = $true)][string]$Message
    )

    switch ($Status) {
        "OK"   { $script:OkCount++; Write-Host "[OK]   $Message" }
        "WARN" { $script:WarnCount++; Write-Warning $Message }
        "FAIL" { $script:FailCount++; Write-Host "[FAIL] $Message" -ForegroundColor Red }
        "SKIP" { $script:SkipCount++; Write-Host "[SKIP] $Message" }
    }
}

function Test-CommandExists {
    param([Parameter(Mandatory = $true)][string]$Name)
    return $null -ne (Get-Command $Name -ErrorAction SilentlyContinue)
}

function Test-AnyPath {
    param([string[]]$Paths)
    foreach ($path in $Paths) {
        if (-not [string]::IsNullOrWhiteSpace($path) -and (Test-Path $path)) { return $true }
    }
    return $false
}

function Test-AgentInstalled {
    param(
        [string[]]$Commands,
        [string[]]$EvidencePaths
    )

    foreach ($command in $Commands) {
        if (Test-CommandExists -Name $command) { return $true }
    }
    return Test-AnyPath -Paths $EvidencePaths
}

function Get-ResolvedPathOrNull {
    param([Parameter(Mandatory = $true)][string]$Path)
    try { return (Resolve-Path $Path -ErrorAction Stop).Path }
    catch { return $null }
}

function Normalize-ComparablePath {
    param([Parameter(Mandatory = $true)][string]$Path)
    return $Path.TrimEnd([char[]]"\/")
}

function Test-SamePath {
    param(
        [Parameter(Mandatory = $true)][string]$PathA,
        [Parameter(Mandatory = $true)][string]$PathB
    )

    $a = Get-ResolvedPathOrNull -Path $PathA
    $b = Get-ResolvedPathOrNull -Path $PathB
    if ($null -eq $a -or $null -eq $b) { return $false }
    return (Normalize-ComparablePath -Path $a) -ieq (Normalize-ComparablePath -Path $b)
}

function Test-SkillLink {
    param(
        [Parameter(Mandatory = $true)][string]$AgentName,
        [Parameter(Mandatory = $true)][string]$LinkPath,
        [Parameter(Mandatory = $true)][string]$TargetPath
    )

    if (-not (Test-Path $LinkPath)) {
        Write-DoctorResult -Status "FAIL" -Message "$AgentName Skill 연결 없음: $LinkPath"
        return
    }

    $item = Get-Item $LinkPath -Force
    if ($item.LinkType -ne "Junction" -and $item.LinkType -ne "SymbolicLink") {
        Write-DoctorResult -Status "FAIL" -Message "$AgentName Skill 경로가 Link가 아님: $LinkPath"
        return
    }

    foreach ($target in @($item.Target)) {
        if (Test-SamePath -PathA $target -PathB $TargetPath) {
            Write-DoctorResult -Status "OK" -Message "$AgentName Skill 연결: $($item.Name)"
            return
        }
    }

    Write-DoctorResult -Status "FAIL" -Message "$AgentName Skill 대상 불일치: $LinkPath -> $($item.Target -join ', ')"
}

function Test-ManagedInstruction {
    param(
        [Parameter(Mandatory = $true)][string]$AgentName,
        [Parameter(Mandatory = $true)][string]$Path
    )

    if (-not (Test-Path $Path -PathType Leaf)) {
        Write-DoctorResult -Status "FAIL" -Message "$AgentName 전역 지침 없음: $Path"
        return
    }

    $content = Get-Content $Path -Raw -Encoding UTF8
    if ($content.Contains($ManagedStart) -and $content.Contains($ManagedEnd)) {
        Write-DoctorResult -Status "OK" -Message "$AgentName 전역 지침 연결"
    }
    else {
        Write-DoctorResult -Status "FAIL" -Message "$AgentName 전역 지침에 AI_MEMORY 관리 블록 없음: $Path"
    }
}

Write-Host ""
Write-Host "=== AI_MEMORY Doctor ==="
Write-Host "Repository : $RepoRoot"
Write-Host ""

Write-Host "=== Repository ==="
$requiredPaths = @(
    "README.md",
    "INDEX.md",
    "TOOL_INDEX.md",
    "MEMORY_POLICY.md",
    "setup.ps1",
    "instructions\GLOBAL_AGENT_INSTRUCTIONS.md",
    "skills",
    "memory",
    "tools",
    "templates\MEMORY_TEMPLATE.md",
    "templates\TOOL_TEMPLATE.md",
    "scripts\search-memory.ps1",
    "scripts\rebuild-index.ps1",
    "scripts\search-tools.ps1",
    "scripts\rebuild-tool-index.ps1"
)

foreach ($relative in $requiredPaths) {
    $path = Join-Path $RepoRoot $relative
    if (Test-Path $path) {
        Write-DoctorResult -Status "OK" -Message "필수 항목: $relative"
    }
    else {
        Write-DoctorResult -Status "FAIL" -Message "필수 항목 누락: $relative"
    }
}

if (Test-Path (Join-Path $RepoRoot ".git") -PathType Container) {
    Write-DoctorResult -Status "OK" -Message "Git Repository"
}
else {
    Write-DoctorResult -Status "WARN" -Message ".git 폴더를 찾지 못했습니다. Git clone이 아닌 복사본일 수 있습니다."
}

if (Test-CommandExists -Name "git") {
    Write-DoctorResult -Status "OK" -Message "git 명령 사용 가능"
}
else {
    Write-DoctorResult -Status "WARN" -Message "git 명령을 찾지 못했습니다. 동기화 기능은 사용할 수 없습니다."
}

$userMemoryHome = [Environment]::GetEnvironmentVariable("AI_MEMORY_HOME", "User")
if ([string]::IsNullOrWhiteSpace($userMemoryHome)) {
    Write-DoctorResult -Status "FAIL" -Message "사용자 환경변수 AI_MEMORY_HOME이 등록되지 않음"
}
elseif (Test-SamePath -PathA $userMemoryHome -PathB $RepoRoot) {
    Write-DoctorResult -Status "OK" -Message "AI_MEMORY_HOME=$userMemoryHome"
}
else {
    Write-DoctorResult -Status "FAIL" -Message "AI_MEMORY_HOME이 현재 Repository와 다름: $userMemoryHome"
}

if ([string]::IsNullOrWhiteSpace($env:AI_MEMORY_HOME)) {
    Write-DoctorResult -Status "WARN" -Message "현재 PowerShell 세션에는 AI_MEMORY_HOME이 없습니다. 새 셸을 열거나 setup.ps1을 다시 실행하세요."
}
elseif (Test-SamePath -PathA $env:AI_MEMORY_HOME -PathB $RepoRoot) {
    Write-DoctorResult -Status "OK" -Message "현재 세션 AI_MEMORY_HOME 정상"
}
else {
    Write-DoctorResult -Status "WARN" -Message "현재 세션 AI_MEMORY_HOME이 오래된 값일 수 있습니다: $env:AI_MEMORY_HOME"
}

$tempPath = Join-Path $RepoRoot (".doctor-write-test-" + [guid]::NewGuid().ToString("N") + ".tmp")
try {
    [IO.File]::WriteAllText($tempPath, "AI_MEMORY doctor write test", [Text.UTF8Encoding]::new($false))
    Remove-Item $tempPath -Force
    Write-DoctorResult -Status "OK" -Message "Repository 쓰기 권한"
}
catch {
    if (Test-Path $tempPath) { Remove-Item $tempPath -Force -ErrorAction SilentlyContinue }
    Write-DoctorResult -Status "FAIL" -Message "Repository 쓰기 권한 확인 실패: $($_.Exception.Message)"
}

Write-Host ""
Write-Host "=== Skills / Tools ==="
$skillsRoot = Join-Path $RepoRoot "skills"
$skillDirectories = @(
    Get-ChildItem -Path $skillsRoot -Directory -ErrorAction SilentlyContinue |
        Where-Object { Test-Path (Join-Path $_.FullName "SKILL.md") } |
        Sort-Object Name
)

if ($skillDirectories.Count -gt 0) {
    Write-DoctorResult -Status "OK" -Message "전역 Skill 발견: $($skillDirectories.Count)개"
}
else {
    Write-DoctorResult -Status "FAIL" -Message "SKILL.md를 가진 전역 Skill이 없음"
}

if (Test-Path (Join-Path $skillsRoot "agent-memory\SKILL.md") -PathType Leaf) {
    Write-DoctorResult -Status "OK" -Message "agent-memory Skill"
}
else {
    Write-DoctorResult -Status "FAIL" -Message "agent-memory Skill 누락"
}

$toolDocs = @(Get-ChildItem -Path (Join-Path $RepoRoot "tools") -Filter "TOOL.md" -File -Recurse -ErrorAction SilentlyContinue)
Write-DoctorResult -Status "OK" -Message "등록된 Tool: $($toolDocs.Count)개"

Write-Host ""
Write-Host "=== Agent Detection ==="
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

$agentStatus = [ordered]@{
    "Codex"       = $codexInstalled
    "Cursor"      = $cursorInstalled
    "Claude Code" = $claudeInstalled
    "Antigravity" = $antigravityInstalled
}

foreach ($agent in $agentStatus.GetEnumerator()) {
    if ($agent.Value) { Write-DoctorResult -Status "OK" -Message "$($agent.Key) 발견" }
    else { Write-DoctorResult -Status "SKIP" -Message "$($agent.Key) 설치 흔적 없음" }
}

Write-Host ""
Write-Host "=== Skill Links ==="
if ($codexInstalled -or $cursorInstalled) {
    foreach ($skill in $skillDirectories) {
        Test-SkillLink -AgentName "Codex + Cursor" -LinkPath (Join-Path $HOME ".agents\skills\$($skill.Name)") -TargetPath $skill.FullName
    }
}
else {
    Write-DoctorResult -Status "SKIP" -Message "Codex + Cursor Skill 검사"
}

if ($claudeInstalled) {
    foreach ($skill in $skillDirectories) {
        Test-SkillLink -AgentName "Claude Code" -LinkPath (Join-Path $claudeHome "skills\$($skill.Name)") -TargetPath $skill.FullName
    }
}
else {
    Write-DoctorResult -Status "SKIP" -Message "Claude Code Skill 검사"
}

if ($antigravityInstalled) {
    foreach ($skill in $skillDirectories) {
        Test-SkillLink -AgentName "Antigravity" -LinkPath (Join-Path $antigravityConfigHome "skills\$($skill.Name)") -TargetPath $skill.FullName
    }
}
else {
    Write-DoctorResult -Status "SKIP" -Message "Antigravity Skill 검사"
}

Write-Host ""
Write-Host "=== Global Instructions ==="
if ($codexInstalled) { Test-ManagedInstruction -AgentName "Codex" -Path (Join-Path $codexHome "AGENTS.md") }
else { Write-DoctorResult -Status "SKIP" -Message "Codex 전역 지침 검사" }

if ($cursorInstalled) { Test-ManagedInstruction -AgentName "Cursor" -Path (Join-Path $cursorHome "rules\ai-memory.mdc") }
else { Write-DoctorResult -Status "SKIP" -Message "Cursor 전역 지침 검사" }

if ($claudeInstalled) { Test-ManagedInstruction -AgentName "Claude Code" -Path (Join-Path $claudeHome "CLAUDE.md") }
else { Write-DoctorResult -Status "SKIP" -Message "Claude Code 전역 지침 검사" }

if ($antigravityInstalled) { Test-ManagedInstruction -AgentName "Antigravity" -Path (Join-Path $geminiHome "GEMINI.md") }
else { Write-DoctorResult -Status "SKIP" -Message "Antigravity 전역 지침 검사" }

Write-Host ""
Write-Host "=== Doctor Summary ==="
Write-Host "OK   : $script:OkCount"
Write-Host "WARN : $script:WarnCount"
Write-Host "FAIL : $script:FailCount"
Write-Host "SKIP : $script:SkipCount"
Write-Host ""

if ($script:FailCount -gt 0) {
    Write-Host "RESULT=FAIL" -ForegroundColor Red
    Write-Host "setup.ps1을 다시 실행한 뒤 doctor.ps1로 재검사하세요."
    exit 1
}

if ($script:WarnCount -gt 0) {
    Write-Host "RESULT=PASS_WITH_WARNINGS"
    exit 0
}

Write-Host "RESULT=PASS"
exit 0
