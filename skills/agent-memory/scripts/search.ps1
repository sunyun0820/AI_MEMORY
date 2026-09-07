param([Parameter(ValueFromRemainingArguments=$true)][string[]]$Query)
$root = $env:AI_MEMORY_HOME
if ([string]::IsNullOrWhiteSpace($root)) { $root = 'E:\AI_MEMORY' }
& (Join-Path $root 'scripts\search-memory.ps1') -Query $Query -Root $root
