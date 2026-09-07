[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$Repository = 'The-CodeCave/shipd-cli'
$Version = if ($env:SHIPD_VERSION) { $env:SHIPD_VERSION } else { 'latest' }
if ($Version.StartsWith('v')) {
    $Version = $Version.Substring(1)
}
if ($Version -ne 'latest' -and $Version -notmatch '^[0-9]+\.[0-9]+\.[0-9]+$') {
    throw 'SHIPD_VERSION must be latest or have the form X.Y.Z'
}
if ($env:PROCESSOR_ARCHITECTURE -ne 'AMD64') {
    throw "unsupported Windows architecture: $env:PROCESSOR_ARCHITECTURE"
}

$InstallDirectory = if ($env:SHIPD_INSTALL_DIR) {
    $env:SHIPD_INSTALL_DIR
} else {
    Join-Path ([Environment]::GetFolderPath('LocalApplicationData')) 'Shipd\bin'
}
if (-not [IO.Path]::IsPathRooted($InstallDirectory)) {
    throw 'SHIPD_INSTALL_DIR must be an absolute path'
}
$InstallDirectory = [IO.Path]::GetFullPath($InstallDirectory)

$Archive = 'shipd-x86_64-pc-windows-msvc.zip'
$DownloadBase = if ($Version -eq 'latest') {
    "https://github.com/$Repository/releases/latest/download"
} else {
    "https://github.com/$Repository/releases/download/v$Version"
}
$TemporaryDirectory = Join-Path ([IO.Path]::GetTempPath()) ("shipd-install-" + [Guid]::NewGuid())
$StagedBinary = $null

try {
    New-Item -ItemType Directory -Path $TemporaryDirectory | Out-Null
    $ArchivePath = Join-Path $TemporaryDirectory $Archive
    $ChecksumPath = Join-Path $TemporaryDirectory 'SHA256SUMS'
    Invoke-WebRequest -UseBasicParsing -Uri "$DownloadBase/$Archive" -OutFile $ArchivePath
    Invoke-WebRequest -UseBasicParsing -Uri "$DownloadBase/SHA256SUMS" -OutFile $ChecksumPath

    $ChecksumPattern = '^([A-Fa-f0-9]{64})\s{1,2}\*?' + [Regex]::Escape($Archive) + '$'
    $ExpectedChecksum = $null
    foreach ($Line in Get-Content -LiteralPath $ChecksumPath) {
        $Match = [Regex]::Match($Line, $ChecksumPattern)
        if ($Match.Success) {
            if ($null -ne $ExpectedChecksum) {
                throw "release checksum list contains duplicate entries for $Archive"
            }
            $ExpectedChecksum = $Match.Groups[1].Value.ToLowerInvariant()
        }
    }
    if ($null -eq $ExpectedChecksum) {
        throw "release checksum list does not contain $Archive"
    }
    $ActualChecksum = (Get-FileHash -LiteralPath $ArchivePath -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($ActualChecksum -ne $ExpectedChecksum) {
        throw "checksum verification failed for $Archive"
    }

    $UnpackedDirectory = Join-Path $TemporaryDirectory 'unpacked'
    Expand-Archive -LiteralPath $ArchivePath -DestinationPath $UnpackedDirectory
    $UnpackedBinary = Join-Path $UnpackedDirectory 'shipd.exe'
    if (-not (Test-Path -LiteralPath $UnpackedBinary -PathType Leaf)) {
        throw 'verified archive does not contain shipd.exe'
    }

    New-Item -ItemType Directory -Path $InstallDirectory -Force | Out-Null
    $Destination = Join-Path $InstallDirectory 'shipd.exe'
    $StagedBinary = Join-Path $InstallDirectory ('.shipd.' + [Guid]::NewGuid() + '.exe')
    [IO.File]::Copy($UnpackedBinary, $StagedBinary, $true)
    if ([IO.File]::Exists($Destination)) {
        # [NullString]::Value, not $null: PowerShell binds $null to a .NET string
        # parameter as the empty string, and File.Replace rejects that. Passing
        # $null here made every upgrade fail while first installs succeeded.
        [IO.File]::Replace($StagedBinary, $Destination, [NullString]::Value)
    } else {
        [IO.File]::Move($StagedBinary, $Destination)
    }

    $NormalizedInstallDirectory = $InstallDirectory.TrimEnd('\')
    $UserPath = [Environment]::GetEnvironmentVariable('Path', 'User')
    $UserPathParts = @($UserPath -split ';' | Where-Object { $_ })
    $NormalizedUserPathParts = @($UserPathParts | ForEach-Object { $_.TrimEnd('\') })
    if ($NormalizedUserPathParts -notcontains $NormalizedInstallDirectory) {
        $NewUserPath = (@($UserPathParts) + $InstallDirectory) -join ';'
        [Environment]::SetEnvironmentVariable('Path', $NewUserPath, 'User')
    }
    $ProcessPathParts = @($env:Path -split ';' | Where-Object { $_ })
    if (@($ProcessPathParts | ForEach-Object { $_.TrimEnd('\') }) -notcontains $NormalizedInstallDirectory) {
        $env:Path = "$InstallDirectory;$env:Path"
    }

    Write-Output "Installed shipd to $Destination"
} finally {
    if ($null -ne $StagedBinary) {
        Remove-Item -LiteralPath $StagedBinary -Force -ErrorAction SilentlyContinue
    }
    Remove-Item -LiteralPath $TemporaryDirectory -Recurse -Force -ErrorAction SilentlyContinue
}
