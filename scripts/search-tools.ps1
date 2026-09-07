param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string[]]$Query,
    [int]$Top = 10
)

$ErrorActionPreference = "Stop"

$RepoRoot = if (-not [string]::IsNullOrWhiteSpace($env:AI_MEMORY_HOME) -and (Test-Path $env:AI_MEMORY_HOME)) {
    (Resolve-Path $env:AI_MEMORY_HOME).Path
}
else {
    (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
}

$ToolsRoot = Join-Path $RepoRoot "tools"

function Get-ScalarMetadata {
    param(
        [Parameter(Mandatory = $true)][string[]]$Lines,
        [Parameter(Mandatory = $true)][string]$Key
    )

    foreach ($line in $Lines) {
        if ($line -match "^$([regex]::Escape($Key)):\s*(.*?)\s*$") {
            return $Matches[1].Trim().Trim('"').Trim("'")
        }
    }
    return ""
}

if (-not (Test-Path $ToolsRoot -PathType Container)) {
    Write-Error "Tools directory not found: $ToolsRoot"
    exit 3
}

$terms = @($Query | ForEach-Object { $_.Trim() } | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
if ($terms.Count -eq 0) {
    Write-Error "At least one search term is required."
    exit 2
}

if ($Top -lt 1) { $Top = 1 }

$results = @()
$toolDocs = @(Get-ChildItem -Path $ToolsRoot -Filter "TOOL.md" -File -Recurse)

foreach ($toolDoc in $toolDocs) {
    $raw = Get-Content $toolDoc.FullName -Raw -Encoding UTF8
    $lines = $raw -split "`r?`n"
    $score = 0

    foreach ($term in $terms) {
        $matches = [regex]::Matches(
            $raw,
            [regex]::Escape($term),
            [System.Text.RegularExpressions.RegexOptions]::IgnoreCase
        ).Count
        if ($matches -gt 0) { $score += [Math]::Min($matches, 5) }
    }

    if ($score -le 0) { continue }

    $relativePath = $toolDoc.FullName.Substring($RepoRoot.Length).TrimStart([char[]]"\/").Replace("\", "/")

    $results += [PSCustomObject]@{
        Score = $score
        Name = Get-ScalarMetadata -Lines $lines -Key "name"
        Category = Get-ScalarMetadata -Lines $lines -Key "category"
        Safety = Get-ScalarMetadata -Lines $lines -Key "safety"
        Description = Get-ScalarMetadata -Lines $lines -Key "description"
        Path = $relativePath
    }
}

$results = @(
    $results |
        Sort-Object @{ Expression = "Score"; Descending = $true }, Category, Name |
        Select-Object -First $Top
)

if ($results.Count -eq 0) {
    Write-Host "STATUS=NO_MATCH"
    Write-Host "QUERY=$($terms -join ', ')"
    exit 1
}

Write-Host "STATUS=SUCCESS"
Write-Host "MATCHES=$($results.Count)"
Write-Host ""

foreach ($result in $results) {
    Write-Host "[$($result.Score)] $($result.Name)"
    Write-Host "  CATEGORY=$($result.Category)"
    Write-Host "  SAFETY=$($result.Safety)"
    Write-Host "  PURPOSE=$($result.Description)"
    Write-Host "  TOOL_MD=$($result.Path)"
    Write-Host ""
}
