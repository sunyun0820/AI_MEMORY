$root = $env:AI_MEMORY_HOME
if ([string]::IsNullOrWhiteSpace($root)) { $root = 'E:\AI_MEMORY' }
& (Join-Path $root 'scripts\rebuild-index.ps1') -Root $root
