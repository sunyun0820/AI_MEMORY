param([string]$Root = $env:AI_MEMORY_HOME)
$ErrorActionPreference = 'Stop'
if ([string]::IsNullOrWhiteSpace($Root)) {
    $skill = Get-Item -LiteralPath (Split-Path $PSScriptRoot -Parent) -Force
    $skillRoot = $skill.FullName
    if ($skill.LinkType -in @('Junction', 'SymbolicLink')) {
        $skillRoot = @($skill.Target)[0]
        if (-not [IO.Path]::IsPathRooted($skillRoot)) { $skillRoot = Join-Path $skill.Parent.FullName $skillRoot }
    }
    $Root = [IO.Path]::GetFullPath((Join-Path $skillRoot '../..'))
}
if (-not (Test-Path -LiteralPath (Join-Path $Root 'scripts/search-memory.ps1') -PathType Leaf) -or
    -not (Test-Path -LiteralPath (Join-Path $Root 'memory') -PathType Container)) {
    throw 'AI_MEMORY repository not found. Set AI_MEMORY_HOME or pass -Root to the repository path.'
}
(Resolve-Path -LiteralPath $Root).Path
