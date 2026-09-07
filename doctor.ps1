# AI_MEMORY Doctor
# Windows PowerShell 5.1 compatible and ASCII-only by design.
# Read-only diagnostics except for a temporary write test file that is deleted immediately.

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
    param([string[]]$Paths = @())
    foreach ($path in $Paths) {
        if (-not [string]::IsNullOrWhiteSpace($path) -and (Test-Path $path)) { return $true }
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
    $a = Get-ResolvedPathOrNull $PathA
    $b = Get-ResolvedPathOrNull $PathB
    if ($null -eq $a -or $null -eq $b) { return $false }
    return (Normalize-ComparablePath $a) -ieq (Normalize-ComparablePath $b)
}

function Test-SkillLink {
    param(
        [Parameter(Mandatory = $true)][string]$AgentName,
        [Parameter(Mandatory = $true)][string]$LinkPath,
        [Parameter(Mandatory = $true)][string]$TargetPath
    )

    if (-not (Test-Path $LinkPath)) {
        Write-DoctorResult FAIL "$AgentName skill link missing: $LinkPath"
        return
    }

    $item = Get-Item $LinkPath -Force
    if ($item.LinkType -ne "Junction" -and $item.LinkType -ne "SymbolicLink") {
        Write-DoctorResult FAIL "$AgentName skill path is not a link: $LinkPath"
        return
    }

    foreach ($target in @($item.Target)) {
        if (Test-SamePath -PathA $target -PathB $TargetPath) {
            Write-DoctorResult OK "$AgentName skill linked: $($item.Name)"
            return
        }
    }

    Write-DoctorResult FAIL "$AgentName skill target mismatch: $LinkPath"
}

function Test-ManagedInstruction {
    param(
        [Parameter(Mandatory = $true)][string]$AgentName,
        [Parameter(Mandatory = $true)][string]$Path
    )

    if (-not (Test-Path $Path -PathType Leaf)) {
        Write-DoctorResult FAIL "$AgentName global instruction missing: $Path"
        return
    }

    $content = ""
    $readContent = Get-Content $Path -Raw -Encoding UTF8
    if ($null -ne $readContent) { $content = [string]$readContent }

    if ([string]::IsNullOrWhiteSpace($content)) {
        Write-DoctorResult FAIL "$AgentName global instruction is empty: $Path"
        return
    }

    if ($content.Contains($ManagedStart) -and $content.Contains($ManagedEnd)) {
        Write-DoctorResult OK "$AgentName global instruction managed by AI_MEMORY"
    }
    else {
        Write-DoctorResult FAIL "$AgentName global instruction has no AI_MEMORY managed block: $Path"
    }
}

Write-Host ""
Write-Host "=== AI_MEMORY Doctor ==="
Write-Host "Repository: $RepoRoot"
Write-Host ""

Write-Host "=== Repository ==="
$requiredPaths = @(
    "README.md",
    "INDEX.md",
    "TOOL_INDEX.md",
    "MEMORY_POLICY.md",
    "setup.ps1",
    "doctor.ps1",
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
    if (Test-Path (Join-Path $RepoRoot $relative)) {
        Write-DoctorResult OK "Required item: $relative"
    }
    else {
        Write-DoctorResult FAIL "Missing required item: $relative"
    }
}

if (Test-Path (Join-Path $RepoRoot ".git") -PathType Container) {
    Write-DoctorResult OK "Git repository"
}
else {
    Write-DoctorResult WARN ".git directory not found; this may be a copied repository."
}

if (Test-CommandExists "git") {
    Write-DoctorResult OK "git command available"
}
else {
    Write-DoctorResult WARN "git command not found; synchronization will be unavailable."
}

$userMemoryHome = [Environment]::GetEnvironmentVariable("AI_MEMORY_HOME", "User")
if ([string]::IsNullOrWhiteSpace($userMemoryHome)) {
    Write-DoctorResult FAIL "User AI_MEMORY_HOME is not registered"
}
elseif (Test-SamePath -PathA $userMemoryHome -PathB $RepoRoot) {
    Write-DoctorResult OK "User AI_MEMORY_HOME=$userMemoryHome"
}
else {
    Write-DoctorResult FAIL "User AI_MEMORY_HOME points elsewhere: $userMemoryHome"
}

if ([string]::IsNullOrWhiteSpace($env:AI_MEMORY_HOME)) {
    Write-DoctorResult WARN "Current shell has no AI_MEMORY_HOME; open a new shell or rerun setup.ps1."
}
elseif (Test-SamePath -PathA $env:AI_MEMORY_HOME -PathB $RepoRoot) {
    Write-DoctorResult OK "Current shell AI_MEMORY_HOME is correct"
}
else {
    Write-DoctorResult WARN "Current shell AI_MEMORY_HOME differs: $env:AI_MEMORY_HOME"
}

$tempPath = Join-Path $RepoRoot (".doctor-write-test-" + [guid]::NewGuid().ToString("N") + ".tmp")
try {
    [IO.File]::WriteAllText($tempPath, "AI_MEMORY doctor write test", (New-Object Text.UTF8Encoding($false)))
    Remove-Item $tempPath -Force
    Write-DoctorResult OK "Repository write permission"
}
catch {
    if (Test-Path $tempPath) { Remove-Item $tempPath -Force -ErrorAction SilentlyContinue }
    Write-DoctorResult FAIL "Repository write test failed: $($_.Exception.Message)"
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
    Write-DoctorResult OK "Global skills found: $($skillDirectories.Count)"
}
else {
    Write-DoctorResult FAIL "No global skill with SKILL.md found"
}

if (Test-Path (Join-Path $skillsRoot "agent-memory\SKILL.md") -PathType Leaf) {
    Write-DoctorResult OK "agent-memory skill"
}
else {
    Write-DoctorResult FAIL "agent-memory skill missing"
}

$toolDocs = @(Get-ChildItem -Path (Join-Path $RepoRoot "tools") -Filter "TOOL.md" -File -Recurse -ErrorAction SilentlyContinue)
Write-DoctorResult OK "Registered tools: $($toolDocs.Count)"

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
    "Codex" = $codexInstalled
    "Cursor" = $cursorInstalled
    "Claude Code" = $claudeInstalled
    "Antigravity" = $antigravityInstalled
}
foreach ($agent in $agentStatus.GetEnumerator()) {
    if ($agent.Value) { Write-DoctorResult OK "$($agent.Key) detected" }
    else { Write-DoctorResult SKIP "$($agent.Key) not detected" }
}

Write-Host ""
Write-Host "=== Skill Links ==="
if ($codexInstalled -or $cursorInstalled) {
    foreach ($skill in $skillDirectories) {
        Test-SkillLink -AgentName "Codex + Cursor" -LinkPath (Join-Path $HOME ".agents\skills\$($skill.Name)") -TargetPath $skill.FullName
    }
}
else { Write-DoctorResult SKIP "Codex + Cursor skill checks" }

if ($claudeInstalled) {
    foreach ($skill in $skillDirectories) {
        Test-SkillLink -AgentName "Claude Code" -LinkPath (Join-Path $claudeHome "skills\$($skill.Name)") -TargetPath $skill.FullName
    }
}
else { Write-DoctorResult SKIP "Claude Code skill checks" }

if ($antigravityInstalled) {
    foreach ($skill in $skillDirectories) {
        Test-SkillLink -AgentName "Antigravity" -LinkPath (Join-Path $antigravityConfigHome "skills\$($skill.Name)") -TargetPath $skill.FullName
    }
}
else { Write-DoctorResult SKIP "Antigravity skill checks" }

Write-Host ""
Write-Host "=== Global Instructions ==="
if ($codexInstalled) { Test-ManagedInstruction -AgentName "Codex" -Path (Join-Path $codexHome "AGENTS.md") }
else { Write-DoctorResult SKIP "Codex global instruction" }

if ($cursorInstalled) { Test-ManagedInstruction -AgentName "Cursor" -Path (Join-Path $cursorHome "rules\ai-memory.mdc") }
else { Write-DoctorResult SKIP "Cursor global instruction" }

if ($claudeInstalled) { Test-ManagedInstruction -AgentName "Claude Code" -Path (Join-Path $claudeHome "CLAUDE.md") }
else { Write-DoctorResult SKIP "Claude Code global instruction" }

if ($antigravityInstalled) { Test-ManagedInstruction -AgentName "Antigravity" -Path (Join-Path $geminiHome "GEMINI.md") }
else { Write-DoctorResult SKIP "Antigravity global instruction" }

Write-Host ""
Write-Host "=== Doctor Summary ==="
Write-Host "OK   : $script:OkCount"
Write-Host "WARN : $script:WarnCount"
Write-Host "FAIL : $script:FailCount"
Write-Host "SKIP : $script:SkipCount"
Write-Host ""

if ($script:FailCount -gt 0) {
    Write-Host "RESULT=FAIL" -ForegroundColor Red
    Write-Host "Run setup.ps1 again, then rerun doctor.ps1."
    exit 1
}
if ($script:WarnCount -gt 0) {
    Write-Host "RESULT=PASS_WITH_WARNINGS"
    exit 0
}

Write-Host "RESULT=PASS"
exit 0
