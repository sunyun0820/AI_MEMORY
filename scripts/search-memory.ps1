param(
    [Parameter(Mandatory = $true, Position = 0)][string[]]$Query,
    [string]$Root = $env:AI_MEMORY_HOME,
    [ValidateRange(1, 2147483647)][int]$MaxFiles = 5,
    [string]$Project = '',
    [switch]$IncludeArchived,
    [switch]$AsObject
)
$ErrorActionPreference = 'Stop'
if ([string]::IsNullOrWhiteSpace($Root)) { $Root = Join-Path $PSScriptRoot '..' }
$Root = (Resolve-Path -LiteralPath $Root).Path
$memoryRoot = Join-Path $Root 'memory'
if (-not (Test-Path -LiteralPath $memoryRoot -PathType Container)) { throw "Memory directory not found: $memoryRoot" }
$terms = @($Query | ForEach-Object { if ($_ -and $_.Trim()) { $_.Trim() } } | Sort-Object -Unique)
if ($terms.Count -eq 0) { throw 'At least one query term is required.' }
$pattern = ($terms | ForEach-Object { [regex]::Escape($_) }) -join '|'
$matcher = New-Object regex($pattern, [Text.RegularExpressions.RegexOptions]::IgnoreCase)
$termMatchers = @($terms | ForEach-Object { New-Object regex([regex]::Escape($_), [Text.RegularExpressions.RegexOptions]::IgnoreCase) })
$results = @(foreach ($file in Get-ChildItem -LiteralPath $memoryRoot -Recurse -File -Filter '*.md') {
    $relative = $file.FullName.Substring($Root.Length).TrimStart([char[]]'\/').Replace('\', '/')
    if (-not $IncludeArchived -and $relative -like 'memory/archive/*') { continue }
    $text = [IO.File]::ReadAllText($file.FullName)
    if (-not $matcher.IsMatch($text)) { continue }
    $metadata = [regex]::Match($text, '\A---\r?\n(.*?)\r?\n---(?:\r?\n|\z)', 'Singleline').Groups[1].Value
    $meta = @{}
    foreach ($entry in [regex]::Matches($metadata, '(?m)^(id|project|scope|status):[ \t]*([^\r\n]*)')) {
        $meta[$entry.Groups[1].Value] = $entry.Groups[2].Value.Trim().Trim('"').Trim("'")
    }
    $status = $meta.status
    if (-not $IncludeArchived -and $status -eq 'archived') { continue }
    $id = $meta.id
    $fileProject = $meta.project
    $scope = $meta.scope
    $title = [regex]::Match($text, '(?m)^#[ \t]+([^\r\n]+)').Groups[1].Value
    $metadataTerms = 0; $matchedTerms = 0
    foreach ($termMatcher in $termMatchers) {
        if ($termMatcher.IsMatch($text)) { $matchedTerms++ }
        if ($termMatcher.IsMatch($metadata + "`n" + $title)) { $metadataTerms++ }
    }
    $hits = 0; $samples = New-Object 'System.Collections.Generic.List[string]'
    $lines = $text -split '\r?\n'
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($matcher.IsMatch($lines[$i])) {
            $hits++
            if ($samples.Count -lt 3) { $samples.Add(('L{0}: {1}' -f ($i + 1), $lines[$i].Trim())) }
        }
    }
    $projectRank = 0
    if ($Project) {
        if ($fileProject -eq $Project) { $projectRank = 2 }
        elseif ($scope -eq 'global' -and -not $fileProject) { $projectRank = 1 }
    }
    [pscustomobject]@{
        Id = $id; Project = $fileProject; Status = $status; Title = $title
        Path = $file.FullName; RelativePath = $relative
        ExactId = [int]($id -and $id -in $terms); ProjectRank = $projectRank
        MatchedTerms = $matchedTerms; MetadataTerms = $metadataTerms
        Hits = $hits; Samples = $samples -join ' | '
    }
})
$selected = @($results | Sort-Object @{Expression='ExactId';Descending=$true},
    @{Expression='ProjectRank';Descending=$true}, @{Expression='MatchedTerms';Descending=$true},
    @{Expression='MetadataTerms';Descending=$true}, @{Expression={ [math]::Min($_.Hits, 5) };Descending=$true},
    RelativePath | Select-Object -First $MaxFiles)
if ($AsObject) { $selected; return }
foreach ($result in $selected) {
    '[{0}/{1}] {2}' -f $result.MatchedTerms, $terms.Count, $result.RelativePath
    $preview = $result.Samples
    if ($preview.Length -gt 360) { $preview = $preview.Substring(0, 360) + ' ...' }
    '  ' + $preview
}
