param(
    [Parameter(Mandatory=$true, Position=0, ValueFromRemainingArguments=$true)][string[]]$Query,
    [string]$Root = $env:AI_MEMORY_HOME,
    [ValidateRange(1, 2147483647)][int]$MaxFiles = 5,
    [string]$Project = '',
    [switch]$IncludeArchived,
    [switch]$AsObject
)
$ErrorActionPreference = 'Stop'
$Root = & (Join-Path $PSScriptRoot 'resolve-root.ps1') -Root $Root
& (Join-Path $Root 'scripts/search-memory.ps1') -Query $Query -Root $Root -MaxFiles $MaxFiles -Project $Project -IncludeArchived:$IncludeArchived -AsObject:$AsObject
