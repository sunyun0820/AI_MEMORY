$ErrorActionPreference = "Stop"

$RepoRoot = if (-not [string]::IsNullOrWhiteSpace($env:AI_MEMORY_HOME) -and (Test-Path $env:AI_MEMORY_HOME)) {
    (Resolve-Path $env:AI_MEMORY_HOME).Path
}
else {
    (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
}

$ToolsRoot = Join-Path $RepoRoot "tools"
$IndexPath = Join-Path $RepoRoot "TOOL_INDEX.md"

function Get-ToolMetadata {
    param([Parameter(Mandatory = $true)][string]$Path)

    $lines = Get-Content $Path -Encoding UTF8
    if ($lines.Count -lt 3 -or $lines[0].Trim() -ne "---") { return $null }

    $metadata = [ordered]@{}
    $currentListKey = $null
    $closed = $false

    for ($i = 1; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]
        if ($line.Trim() -eq "---") {
            $closed = $true
            break
        }

        if ($null -ne $currentListKey -and $line -match '^\s*-\s+(.+?)\s*$') {
            $metadata[$currentListKey] += @($Matches[1].Trim().Trim('"').Trim("'"))
            continue
        }

        $currentListKey = $null

        if ($line -match '^([A-Za-z0-9_-]+):\s*(.*?)\s*$') {
            $key = $Matches[1]
            $value = $Matches[2].Trim()

            if ([string]::IsNullOrWhiteSpace($value)) {
                $metadata[$key] = @()
                $currentListKey = $key
            }
            else {
                $metadata[$key] = $value.Trim('"').Trim("'")
            }
        }
    }

    if (-not $closed) { return $null }
    return $metadata
}

function Join-MetadataValue {
    param($Value)
    if ($null -eq $Value) { return "" }
    if ($Value -is [System.Array]) { return ($Value -join ", ") }
    return [string]$Value
}

function Escape-MarkdownCell {
    param([string]$Value)
    if ($null -eq $Value) { return "" }
    return $Value.Replace("|", "\|").Replace("`r", " ").Replace("`n", " ")
}

if (-not (Test-Path $ToolsRoot -PathType Container)) {
    Write-Error "tools 폴더를 찾을 수 없습니다: $ToolsRoot"
    exit 3
}

$toolDocs = @(Get-ChildItem -Path $ToolsRoot -Filter "TOOL.md" -File -Recurse | Sort-Object FullName)
$rows = @()
$validSafety = @("read-only", "write-local", "destructive", "external")

foreach ($toolDoc in $toolDocs) {
    $meta = Get-ToolMetadata -Path $toolDoc.FullName
    if ($null -eq $meta) {
        Write-Warning "정상적인 YAML Front Matter를 읽을 수 없어 제외합니다: $($toolDoc.FullName)"
        continue
    }

    $required = @("name", "category", "description", "platforms", "runtime", "safety", "idempotent", "tags")
    $missing = @($required | Where-Object { -not $meta.Contains($_) -or [string]::IsNullOrWhiteSpace((Join-MetadataValue $meta[$_])) })

    if ($missing.Count -gt 0) {
        Write-Warning "필수 metadata 누락으로 제외합니다: $($toolDoc.FullName) / $($missing -join ', ')"
        continue
    }

    $safety = (Join-MetadataValue $meta["safety"]).ToLowerInvariant()
    if ($safety -notin $validSafety) {
        Write-Warning "잘못된 safety 값으로 제외합니다: $($toolDoc.FullName) / $safety"
        continue
    }

    $idempotent = (Join-MetadataValue $meta["idempotent"]).ToLowerInvariant()
    if ($idempotent -notin @("true", "false")) {
        Write-Warning "idempotent는 true 또는 false여야 합니다: $($toolDoc.FullName)"
        continue
    }

    $relativePath = $toolDoc.FullName.Substring($RepoRoot.Length).TrimStart([char[]]"\/") -replace '\\', '/'

    $rows += [PSCustomObject]@{
        Name        = Join-MetadataValue $meta["name"]
        Category    = Join-MetadataValue $meta["category"]
        Description = Join-MetadataValue $meta["description"]
        Platforms   = Join-MetadataValue $meta["platforms"]
        Runtime     = Join-MetadataValue $meta["runtime"]
        Safety      = $safety
        Idempotent  = $idempotent
        Tags        = Join-MetadataValue $meta["tags"]
        Path        = $relativePath
    }
}

$rows = @($rows | Sort-Object Category, Name)

$builder = [System.Text.StringBuilder]::new()
[void]$builder.AppendLine("# Tool Index")
[void]$builder.AppendLine("")
[void]$builder.AppendLine("> 이 파일은 `scripts/rebuild-tool-index.ps1`로 재생성합니다. 직접 편집하지 않는 것을 권장합니다.")
[void]$builder.AppendLine("")

if ($rows.Count -eq 0) {
    [void]$builder.AppendLine("현재 등록된 Tool이 없습니다.")
}
else {
    [void]$builder.AppendLine("등록된 Tool: **$($rows.Count)개**")
    [void]$builder.AppendLine("")
    [void]$builder.AppendLine("| Tool | Category | Purpose | Platform | Runtime | Safety | Idempotent | Tags | TOOL.md |")
    [void]$builder.AppendLine("|---|---|---|---|---|---|---|---|---|")

    foreach ($row in $rows) {
        $name = Escape-MarkdownCell $row.Name
        $category = Escape-MarkdownCell $row.Category
        $description = Escape-MarkdownCell $row.Description
        $platforms = Escape-MarkdownCell $row.Platforms
        $runtime = Escape-MarkdownCell $row.Runtime
        $safetyCell = Escape-MarkdownCell $row.Safety
        $idempotentCell = Escape-MarkdownCell $row.Idempotent
        $tags = Escape-MarkdownCell $row.Tags
        $path = Escape-MarkdownCell $row.Path
        [void]$builder.AppendLine("| $name | $category | $description | $platforms | $runtime | $safetyCell | $idempotentCell | $tags | `$path` |")
    }
}

[IO.File]::WriteAllText($IndexPath, $builder.ToString(), [Text.UTF8Encoding]::new($false))

Write-Host "[OK] TOOL_INDEX.md 재생성 완료"
Write-Host "     Tool: $($rows.Count)개"
Write-Host "     Path: $IndexPath"
