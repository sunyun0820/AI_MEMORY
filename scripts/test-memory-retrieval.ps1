param([string]$Root = (Split-Path $PSScriptRoot -Parent))
$ErrorActionPreference = 'Stop'
$Root = (Resolve-Path -LiteralPath $Root).Path
$search = Join-Path $Root 'scripts/search-memory.ps1'
$rebuild = Join-Path $Root 'scripts/rebuild-index.ps1'
$fixture = Join-Path ([IO.Path]::GetTempPath()) ('ai-memory-test-' + [guid]::NewGuid().ToString('N'))
$failures = New-Object 'System.Collections.Generic.List[string]'
$script:Passed = 0

function Check {
    param([string]$Name, [scriptblock]$Test)
    try {
        if (-not (& $Test)) { throw 'Assertion failed' }
        $script:Passed++
        Write-Output "PASS $Name"
    } catch { $failures.Add($Name + ': ' + $_.Exception.Message); Write-Output "FAIL $Name" }
}
function Add-Memory {
    param([string]$Path, [string]$Id, [string]$Project, [string]$Status, [string]$Body)
    $destination = Join-Path $fixture ('memory/' + $Path)
    $null = New-Item -ItemType Directory -Path (Split-Path $destination -Parent) -Force
    $content = "---`nid: $Id`ntype: lesson`nscope: global`nproject: `"$Project`"`nstatus: $Status`ndomain: retrieval`ntags: [rare-tag, literal]`n---`n# $Id`n$Body"
    [IO.File]::WriteAllText($destination, $content, (New-Object Text.UTF8Encoding($false)))
}
try {
    Add-Memory 'projects/target/both.md' 'TARGET-BOTH' 'target' 'active' 'alpha beta literal[0]'
    Add-Memory 'projects/target/one.md' 'TARGET-ONE' 'target' 'active' ('alpha' + "`nalpha" * 15)
    Add-Memory 'lessons/global.md' 'GLOBAL' '' 'active' 'alpha beta'
    Add-Memory 'projects/other/other.md' 'OTHER' 'other' 'active' 'alpha beta'
    Add-Memory 'archive/old.md' 'ARCHIVE-PATH' 'target' 'active' 'alpha beta'
    Add-Memory 'lessons/old.md' 'ARCHIVE-STATUS' 'target' 'archived' 'alpha beta'
    Check 'archived status and archive directory excluded' {
        $r = @(& $search -Root $fixture -Query alpha -AsObject -MaxFiles 50)
        $r.Count -eq 4 -and @($r | Where-Object { $_.Id -like 'ARCHIVE-*' }).Count -eq 0
    }
    Check 'archive opt-in' { @(& $search -Root $fixture -Query alpha -IncludeArchived -AsObject -MaxFiles 50).Count -eq 6 }
    Check 'project preference and distinct term coverage beat repetition' {
        $r = @(& $search -Root $fixture -Query alpha,beta -Project target -AsObject)
        $r[0].Id -eq 'TARGET-BOTH' -and $r[1].Id -eq 'TARGET-ONE'
    }
    Check 'cross-project and global lessons remain discoverable' {
        $r = @(& $search -Root $fixture -Query alpha,beta -Project target -AsObject -MaxFiles 50)
        'GLOBAL' -in $r.Id -and 'OTHER' -in $r.Id
    }
    Check 'literal regex characters' { @(& $search -Root $fixture -Query 'literal[0]' -AsObject)[0].Id -eq 'TARGET-BOTH' }
    Check 'query trimming and deduplication' {
        $r = @(& $search -Root $fixture -Query ' alpha ',alpha,ALPHA -AsObject)
        $r.Count -gt 0 -and @($r | Where-Object { $_.MatchedTerms -ne 1 }).Count -eq 0
    }
    Check 'exact ID wins over project preference' {
        @(& $search -Root $fixture -Query OTHER,alpha -Project target -AsObject)[0].Id -eq 'OTHER'
    }
    Check 'no match is empty' { @(& $search -Root $fixture -Query __absent_791__ -AsObject).Count -eq 0 }
    Check 'blank query rejected' {
        try { $null = & $search -Root $fixture -Query ' '; $false } catch { $true }
    }
    Check 'invalid result limit rejected' {
        try { $null = & $search -Root $fixture -Query alpha -MaxFiles 0; $false } catch { $true }
    }
    Check 'index has tags and excludes all archived entries' {
        & $rebuild -Root $fixture | Out-Null
        $index = [IO.File]::ReadAllText((Join-Path $fixture 'INDEX.md'))
        $index.Contains('rare-tag') -and $index.Contains('domain: retrieval') -and -not $index.Contains('ARCHIVE-')
    }
    Check 'index regeneration is repeatable' {
        $before = [IO.File]::ReadAllText((Join-Path $fixture 'INDEX.md'))
        & $rebuild -Root $fixture | Out-Null
        $before -ceq [IO.File]::ReadAllText((Join-Path $fixture 'INDEX.md'))
    }
    Check 'metadata does not fall through to body' {
        Add-Memory 'lessons/body.md' 'BODY-META' '' '' "status: archived`nproject: poisoned`nbody-only-tag"
        & $rebuild -Root $fixture | Out-Null
        $index = [IO.File]::ReadAllText((Join-Path $fixture 'INDEX.md'))
        $index.Contains('BODY-META') -and -not $index.Contains('project: poisoned')
    }
    Check 'all repository memory IDs searchable' {
        $misses = @(foreach ($file in Get-ChildItem (Join-Path $Root 'memory') -Filter '*.md' -Recurse -File) {
            if ($file.FullName -match '[\\/]archive[\\/]') { continue }
            $text = [IO.File]::ReadAllText($file.FullName)
            if ($text -match '(?m)^status:[ \t]*archived[ \t]*\r?$') { continue }
            $id = [regex]::Match($text, '(?m)^id:[ \t]*([^\r\n]+)').Groups[1].Value.Trim()
            $r = @(& $search -Root $Root -Query $id -AsObject)
            if ($id -notin $r.Id) { $id }
        })
        $misses.Count -eq 0
    }
    Check 'canonical search wrapper resolves root without environment' {
        $saved = $env:AI_MEMORY_HOME
        try {
            $env:AI_MEMORY_HOME = $null
            $r = @(& (Join-Path $Root 'skills/agent-memory/scripts/search.ps1') -Query RULE-GLOBAL-001 -AsObject)
            $r[0].Id -eq 'RULE-GLOBAL-001'
        } finally { $env:AI_MEMORY_HOME = $saved }
    }
    Write-Output "PASS=$script:Passed FAIL=$($failures.Count)"
    if ($failures.Count) { throw ($failures -join "`n") }
} finally {
    $resolved = [IO.Path]::GetFullPath($fixture)
    $prefix = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd([char[]]'\/') + [IO.Path]::DirectorySeparatorChar
    if ($resolved.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase) -and
        (Split-Path $resolved -Leaf) -match '^ai-memory-test-[a-f0-9]{32}$' -and (Test-Path -LiteralPath $resolved)) {
        Remove-Item -LiteralPath $resolved -Recurse -Force
    }
}
