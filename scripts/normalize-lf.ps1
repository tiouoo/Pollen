$ErrorActionPreference = "Stop"

$git = Get-Command git -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $git) { throw "Git is required." }
. (Join-Path $PSScriptRoot 'ensure-perl.ps1')
$perlPath = Get-PortalPerl
& $perlPath (Join-Path $PSScriptRoot "normalize-lf.pl")
if ($LASTEXITCODE -ne 0) { throw "LF normalization failed (exit code $LASTEXITCODE)." }
