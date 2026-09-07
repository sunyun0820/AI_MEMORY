param(
    [string]$Root = $env:AI_MEMORY_HOME
)

if ([string]::IsNullOrWhiteSpace($Root)) { $Root = "E:\AI_MEMORY" }
if (!(Test-Path $Root)) { throw "AI memory root not found: $Root" }

$memoryRoot = Join-Path $Root 'memory'
$indexPath = Join-Path $Root 'INDEX.md'

function Get-MetaValue([string]$text, [string]$key) {
    $m = [regex]::Match($text, "(?m)^$([regex]::Escape($key)):\s*(.+)$")
    if ($m.Success) { return $m.Groups[1].Value.Trim().Trim('"') }
    return ''
}

$rows = @()
Get-ChildItem -Path $memoryRoot -Recurse -File -Filter '*.md' | ForEach-Object {
    $text = Get-Content $_.FullName -Raw
    $titleMatch = [regex]::Match($text, '(?m)^#\s+(.+)$')
    $title = if ($titleMatch.Success) { $titleMatch.Groups[1].Value.Trim() } else { $_.BaseName }
    $type = Get-MetaValue $text 'type'
    $status = Get-MetaValue $text 'status'
    $project = Get-MetaValue $text 'project'
    $id = Get-MetaValue $text 'id'
    $rel = [IO.Path]::GetRelativePath($Root, $_.FullName).Replace('\','/')
    $rows += [PSCustomObject]@{ Type=$type; Status=$status; Project=$project; Id=$id; Title=$title; Path=$rel }
}

$sb = [System.Text.StringBuilder]::new()
[void]$sb.AppendLine('# Agent Memory Index')
[void]$sb.AppendLine()
[void]$sb.AppendLine('> 자동 생성 파일. 직접 편집하기보다 `scripts/rebuild-index.ps1`을 실행하십시오.')
[void]$sb.AppendLine()

foreach ($section in @('rule','project','lesson','incident')) {
    $heading = switch ($section) { 'rule' {'Rules'} 'project' {'Projects'} 'lesson' {'Lessons'} 'incident' {'Incidents'} }
    [void]$sb.AppendLine("## $heading")
    [void]$sb.AppendLine()
    $items = $rows | Where-Object { $_.Type -eq $section -and $_.Status -ne 'archived' } | Sort-Object Project, Title
    if (!$items) {
        [void]$sb.AppendLine('- 없음')
    } else {
        foreach ($item in $items) {
            $extra = if ($item.Project) { " | project: $($item.Project)" } else { '' }
            [void]$sb.AppendLine("- [$($item.Id)] $($item.Title) — `$($item.Path)`$extra")
        }
    }
    [void]$sb.AppendLine()
}

[IO.File]::WriteAllText($indexPath, $sb.ToString(), [Text.UTF8Encoding]::new($false))
Write-Host "Rebuilt: $indexPath"
