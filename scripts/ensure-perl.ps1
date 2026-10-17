$ErrorActionPreference = "Stop"

function Test-PerlRuntime {
    param([string]$Path)
    if (-not $Path -or -not (Test-Path -LiteralPath $Path -PathType Leaf)) { return $false }
    try {
        $result = & $Path '-MEncode' '-MCwd' '-MFile::Basename' '-e' 'print "portal-perl-ok"' 2>$null
        return ($LASTEXITCODE -eq 0 -and ($result -join '') -eq 'portal-perl-ok')
    } catch { return $false }
}

function Enable-InstalledPerl {
    param([string]$BinDirectory)
    $userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
    if ($BinDirectory -notin @($userPath -split ';')) {
        $updated = if ([string]::IsNullOrEmpty($userPath)) { $BinDirectory } else { "$($userPath.TrimEnd(';'));$BinDirectory" }
        [Environment]::SetEnvironmentVariable('Path', $updated, 'User')
    }
    if ($BinDirectory -notin @($env:Path -split ';')) { $env:Path = "$BinDirectory;$env:Path" }
}

function Get-PortalPerl {
    if (-not $env:LOCALAPPDATA) { throw 'LOCALAPPDATA is unavailable. Run this script on Windows.' }
    $installRoot = Join-Path $env:LOCALAPPDATA 'Programs/Perl'
    $installedPerl = Join-Path $installRoot 'perl/bin/perl.exe'
    if (Test-PerlRuntime $installedPerl) {
        Enable-InstalledPerl (Split-Path -Parent $installedPerl)
        return $installedPerl
    }
    foreach ($command in @(Get-Command perl -CommandType Application -All -ErrorAction SilentlyContinue)) {
        if (Test-PerlRuntime $command.Source) { return $command.Source }
    }
    $git = Get-Command git -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($git) {
        $gitDirectory = Split-Path -Parent $git.Source
        foreach ($relative in @('../usr/bin/perl.exe', '../../usr/bin/perl.exe')) {
            $candidate = Join-Path $gitDirectory $relative
            if (Test-PerlRuntime $candidate) { return (Resolve-Path -LiteralPath $candidate).Path }
        }
    }
    if (-not [Environment]::Is64BitOperatingSystem) { throw 'Automatic Perl installation requires 64-bit Windows.' }
    # Pin both the official archive and its SHA-256; never execute an unchecked download.
    $url = 'https://github.com/StrawberryPerl/Perl-Dist-Strawberry/releases/download/SP_54231_64bit/strawberry-perl-5.42.3.1-64bit-portable.zip'
    $expectedHash = '6a081a811781c30aca51dbc036afd93092af91e3297901f02c17043795a10690'
    $parent = Split-Path -Parent $installRoot
    New-Item -ItemType Directory -Path $parent -Force | Out-Null
    # Refuse to overwrite an existing, incomplete installation or unrelated files.
    if (Test-Path -LiteralPath $installRoot) { throw "An unusable installation exists at $installRoot. Rename or remove it before retrying." }
    $stage = Join-Path $parent ('Perl-download-' + [guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Path $stage | Out-Null
    try {
        $archive = Join-Path $stage 'perl.zip'
        $extracted = Join-Path $stage 'runtime'
        Write-Host "Downloading Strawberry Perl to $installRoot ..."
        [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
        Invoke-WebRequest -Uri $url -OutFile $archive -UseBasicParsing
        if ((Get-FileHash -LiteralPath $archive -Algorithm SHA256).Hash -ne $expectedHash) { throw 'Perl download SHA-256 verification failed.' }
        Expand-Archive -LiteralPath $archive -DestinationPath $extracted
        if (-not (Test-PerlRuntime (Join-Path $extracted 'perl/bin/perl.exe'))) { throw 'Downloaded Perl failed its runtime check.' }
        # Directory.Move fails if another process has already installed this location.
        [IO.Directory]::Move($extracted, $installRoot)
        if (-not (Test-PerlRuntime $installedPerl)) { throw "Perl failed verification after installation at $installRoot." }
        Enable-InstalledPerl (Split-Path -Parent $installedPerl)
        Write-Host "Perl installed: $installedPerl"
        return $installedPerl
    } finally {
        # Only remove the uniquely named staging directory created by this invocation.
        if (Test-Path -LiteralPath $stage) {
            $resolvedStage = [IO.Path]::GetFullPath($stage)
            $resolvedParent = [IO.Path]::GetFullPath($parent).TrimEnd('\') + '\'
            if ($resolvedStage.StartsWith($resolvedParent, [StringComparison]::OrdinalIgnoreCase) -and
                [IO.Path]::GetFileName($resolvedStage) -match '^Perl-download-[0-9a-f]{32}$') {
                Remove-Item -LiteralPath $resolvedStage -Recurse -Force
            }
        }
    }
}
