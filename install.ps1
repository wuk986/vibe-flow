# Links vibe-flow into ~/.claude (Windows): the repo as ~/.claude/vibe-flow, each skill as ~/.claude/skills/<name>.
# Directory junctions need neither admin rights nor developer mode.
$ErrorActionPreference = 'Stop'

$src = $PSScriptRoot
$claude = Join-Path $HOME '.claude'
New-Item -ItemType Directory -Force (Join-Path $claude 'skills') | Out-Null

function Link($target, $path) {
    $item = Get-Item $path -Force -ErrorAction SilentlyContinue
    if ($item) {
        if (-not $item.LinkType) { Write-Warning "skipped: $path exists and is not a link"; return }
        [System.IO.Directory]::Delete($path)  # removes only the junction, not the target
    }
    New-Item -ItemType Junction -Path $path -Target $target | Out-Null
    "linked $path -> $target"
}

$home_link = Join-Path $claude 'vibe-flow'
if ($src -ne $home_link) { Link $src $home_link }
Get-ChildItem (Join-Path $src 'skills') -Directory | ForEach-Object {
    Link $_.FullName (Join-Path $claude "skills\$($_.Name)")
}
