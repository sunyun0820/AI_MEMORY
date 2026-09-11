param([string]$Root = $env:AI_MEMORY_HOME)
$ErrorActionPreference = 'Stop'
$Root = & (Join-Path $PSScriptRoot 'resolve-root.ps1') -Root $Root
& (Join-Path $Root 'scripts/rebuild-index.ps1') -Root $Root
