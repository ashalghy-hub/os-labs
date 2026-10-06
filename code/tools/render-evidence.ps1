# Render only original lab logs; capture the resulting static HTML with Edge.
$ErrorActionPreference = 'Stop'
$root = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$edge = 'C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe'
if (-not (Test-Path -LiteralPath $edge)) { throw 'Microsoft Edge is required to render evidence images.' }
$utf8 = New-Object Text.UTF8Encoding($false)
$trace = [IO.File]::ReadAllText((Join-Path $root 'report/logs/gdb.txt'))
$split = $trace.IndexOf('=== Kernel entry and privilege state ===')
if ($split -lt 0) { throw 'Completed GDB trace is required.' }
$items = @(
    @('reset', $trace.Substring(0, $split), 1650),
    @('kernel', $trace.Substring($split), 1900),
    @('qemu', [IO.File]::ReadAllText((Join-Path $root 'report/logs/qemu-debug.txt')), 2200)
)
foreach ($item in $items) {
    $name = $item[0]
    $source = if ($name -eq 'qemu') { 'qemu-debug.txt' } else { 'gdb.txt' }
    $html = '<!doctype html><meta charset="utf-8"><style>body{margin:32px;background:#101820;color:#e8edf1;font:19px/1.45 Consolas,monospace}h1{font:26px sans-serif}p{font:17px sans-serif;color:#b7c3cc}pre{white-space:pre-wrap}</style><h1>Lab1 — ' + $name + '</h1><p>2026-10-06 · Screenshot of rendered original test log · Source: report/logs/' + $source + '</p><pre>' + [System.Net.WebUtility]::HtmlEncode($item[1]) + '</pre>'
    $htmlPath = Join-Path $root ('report/images/' + $name + '.html')
    $pngPath = Join-Path $root ('report/images/' + $name + '.png')
    [IO.File]::WriteAllText($htmlPath, $html, $utf8)
    $profile = Join-Path $root ('.edge-lab1/' + $name)
    $uri = (New-Object Uri($htmlPath)).AbsoluteUri
    $args = @('--headless', '--disable-gpu', '--no-first-run',
        ('--user-data-dir="' + $profile + '"'), ('--screenshot="' + $pngPath + '"'),
        ('--window-size=1400,' + $item[2]), $uri)
    Start-Process -FilePath $edge -ArgumentList $args -WindowStyle Hidden -Wait
    if (-not (Test-Path -LiteralPath $pngPath)) { throw "Missing screenshot: $pngPath" }
    Write-Output $pngPath
}
