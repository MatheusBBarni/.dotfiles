<#
.SYNOPSIS
    Installs the small Windows gaming setup used by this dotfiles repo.

.DESCRIPTION
    Installs Steam, Brave, and Battle.net through WinGet, then downloads and
    launches the RubinOT client installer from RubinOT's official download
    endpoint. Win11Debloat is optional because its changes require elevation
    and can alter Windows settings.

.PARAMETER RunDebloat
    Runs Win11Debloat with its recommended settings without removing apps.

.PARAMETER RemoveBloatApps
    With -RunDebloat, also removes Win11Debloat's default selection of
    pre-installed apps. Review Win11Debloat's choices before using this.

.PARAMETER WhatIf
    Prints the actions without installing anything.

.EXAMPLE
    Set-ExecutionPolicy -Scope Process Bypass
    .\windows-setup.ps1 -RunDebloat

.EXAMPLE
    .\windows-setup.ps1 -RunDebloat -RemoveBloatApps
#>
[CmdletBinding()]
param(
    [switch]$RunDebloat,
    [switch]$RemoveBloatApps,
    [switch]$WhatIf
)

$ErrorActionPreference = "Stop"

$RubinotDownloadUrl = "https://cdn-rubinot-com.emac.ac/download"
$Win11DebloatUrl = "https://debloat.raphi.re/"

$WingetPackages = @(
    @{ Name = "Steam"; Id = "Valve.Steam" },
    @{ Name = "Brave"; Id = "Brave.Brave" },
    @{ Name = "Battle.net"; Id = "Blizzard.BattleNet" }
)

function Write-Action {
    param([string]$Message)

    if ($WhatIf) {
        Write-Host "WHATIF: $Message"
    } else {
        Write-Host $Message
    }
}

function Assert-WindowsGamingHost {
    if ($env:OS -ne "Windows_NT") {
        throw "windows-setup.ps1 must run on Windows."
    }

    if (-not [Environment]::Is64BitOperatingSystem) {
        throw "RubinOT requires 64-bit Windows."
    }
}

function Assert-Winget {
    if (-not (Get-Command winget.exe -ErrorAction SilentlyContinue)) {
        throw "WinGet is required. Install or update App Installer from https://apps.microsoft.com/detail/9NBLGGH4NNS1, then run this script again."
    }
}

function Install-WingetPackage {
    param(
        [string]$Name,
        [string]$Id
    )

    Write-Action "Installing $Name ($Id)"
    if ($WhatIf) {
        return
    }

    & winget.exe install `
        --id $Id `
        --exact `
        --source winget `
        --accept-source-agreements `
        --accept-package-agreements `
        --silent `
        --disable-interactivity

    if ($LASTEXITCODE -ne 0) {
        throw "WinGet failed to install $Name ($Id), exit code $LASTEXITCODE."
    }
}

function Install-Rubinot {
    $installerPath = Join-Path ([IO.Path]::GetTempPath()) "rubinot-setup-$([Guid]::NewGuid()).exe"

    Write-Action "Downloading RubinOT from $RubinotDownloadUrl"
    if ($WhatIf) {
        return
    }

    try {
        Invoke-WebRequest `
            -Uri $RubinotDownloadUrl `
            -OutFile $installerPath `
            -UseBasicParsing

        if (-not (Test-Path -LiteralPath $installerPath -PathType Leaf)) {
            throw "RubinOT installer was not downloaded."
        }

        Write-Host "Launching RubinOT installer; complete its interactive setup."
        $process = Start-Process -FilePath $installerPath -Wait -PassThru
        if ($process.ExitCode -ne 0) {
            throw "RubinOT installer failed, exit code $($process.ExitCode)."
        }
    } finally {
        Remove-Item -LiteralPath $installerPath -Force -ErrorAction SilentlyContinue
    }
}

function Invoke-Win11Debloat {
    Write-Action "Running Win11Debloat recommended settings"
    if ($WhatIf) {
        if ($RemoveBloatApps) {
            Write-Host "WHATIF: also remove Win11Debloat's default pre-installed apps"
        }
        return
    }

    $arguments = @("-RunDefaultsLite", "-DisableBraveBloat", "-CreateRestorePoint")
    if ($RemoveBloatApps) {
        $arguments = @("-RunDefaults", "-DisableBraveBloat", "-CreateRestorePoint")
    }

    $launcherPath = Join-Path ([IO.Path]::GetTempPath()) "win11debloat-$([Guid]::NewGuid()).ps1"
    try {
        Write-Host "Win11Debloat will request administrator access."
        Invoke-WebRequest `
            -Uri $Win11DebloatUrl `
            -OutFile $launcherPath `
            -UseBasicParsing
        $argumentList = @(
            "-NoProfile",
            "-ExecutionPolicy",
            "Bypass",
            "-File",
            ('"{0}"' -f $launcherPath)
        ) + $arguments
        $process = Start-Process `
            -FilePath "powershell.exe" `
            -ArgumentList $argumentList `
            -Wait `
            -PassThru

        if ($process.ExitCode -ne 0) {
            throw "Win11Debloat failed, exit code $($process.ExitCode)."
        }
    } finally {
        Remove-Item -LiteralPath $launcherPath -Force -ErrorAction SilentlyContinue
    }
}

if ($RemoveBloatApps -and -not $RunDebloat) {
    throw "-RemoveBloatApps requires -RunDebloat."
}

Assert-WindowsGamingHost

if (-not $WhatIf) {
    Assert-Winget
}

foreach ($Package in $WingetPackages) {
    Install-WingetPackage -Name $Package.Name -Id $Package.Id
}

Install-Rubinot

if ($RunDebloat) {
    Invoke-Win11Debloat
} else {
    Write-Host "Skipping Win11Debloat. Use -RunDebloat to apply its recommended settings."
}

Write-Host "Windows gaming setup complete."
