param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string[]]$Query,
    [string]$Root = $env:AI_MEMORY_HOME,
    [int]$MaxFiles = 20
)

$ErrorActionPreference = "Stop"

# Use the repository root relative to this script when AI_MEMORY_HOME is unavailable.
if ([string]::IsNullOrWhiteSpace($Root)) {
    $Root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
}

if (-not (Test-Path $Root)) { throw "AI memory root not found: $Root" }

$memoryRoot = Join-Path $Root "memory"
if (-not (Test-Path $memoryRoot)) { throw "Memory directory not found: $memoryRoot" }

$patterns = @(
    $Query |
        Where-Object { $_ -and $_.Trim() } |
        ForEach-Object { [regex]::Escape($_) }
)

if ($patterns.Count -eq 0) { throw "At least one query term is required." }
$regex = ($patterns -join "|")

Get-ChildItem -Path $memoryRoot -Recurse -File -Filter "*.md" |
    Select-String -Pattern $regex -CaseSensitive:$false |
    Group-Object Path |
    Sort-Object Count -Descending |
    Select-Object -First $MaxFiles |
    ForEach-Object {
        [PSCustomObject]@{
            Hits = $_.Count
            Path = $_.Name
            Samples = (($_.Group | Select-Object -First 3 | ForEach-Object { "L$($_.LineNumber): $($_.Line.Trim())" }) -join " | ")
        }
    } | Format-Table -AutoSize -Wrap
