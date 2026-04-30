$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$DotfilesDir = Resolve-Path (Join-Path $ScriptDir "..")
$TargetDir = Join-Path $DotfilesDir "zed"
$ZedConfigDir = if ($env:ZED_CONFIG_DIR) { $env:ZED_CONFIG_DIR } else { Join-Path $env:APPDATA "Zed" }
$ZedDataDir = if ($env:ZED_DATA_DIR) { $env:ZED_DATA_DIR } else { Join-Path $env:LOCALAPPDATA "Zed" }

New-Item -ItemType Directory -Force -Path $TargetDir | Out-Null

function Copy-ZedFile {
  param([string]$Name)

  $Source = Join-Path $ZedConfigDir $Name
  $Target = Join-Path $TargetDir $Name

  if (Test-Path -LiteralPath $Source -PathType Leaf) {
    Copy-Item -LiteralPath $Source -Destination $Target -Force
    Write-Host "Exported $Name"
  } else {
    Write-Host "Skipping $Name; not found at $Source"
  }
}

function Copy-ZedDirectory {
  param([string]$Name)

  $Source = Join-Path $ZedConfigDir $Name
  $Target = Join-Path $TargetDir $Name

  if (Test-Path -LiteralPath $Source -PathType Container) {
    if (Test-Path -LiteralPath $Target) {
      Remove-Item -LiteralPath $Target -Recurse -Force
    }

    Copy-Item -LiteralPath $Source -Destination $Target -Recurse -Force
    Write-Host "Exported $Name/"
  } else {
    Write-Host "Skipping $Name/; not found at $Source"
  }
}

Copy-ZedFile "settings.json"
Copy-ZedFile "keymap.json"
Copy-ZedFile "tasks.json"
Copy-ZedFile "debug.json"
Copy-ZedDirectory "snippets"
Copy-ZedDirectory "themes"

$ExtensionCandidates = @(
  (Join-Path $ZedDataDir "extensions\installed"),
  (Join-Path $ZedConfigDir "extensions\installed")
)
$ExtensionsDir = $ExtensionCandidates | Where-Object { Test-Path -LiteralPath $_ -PathType Container } | Select-Object -First 1
$ExtensionsTarget = Join-Path $TargetDir "auto-install-extensions.json"

if ($ExtensionsDir) {
  $ExtensionMap = [ordered]@{}
  Get-ChildItem -LiteralPath $ExtensionsDir -Directory |
    Sort-Object Name |
    ForEach-Object { $ExtensionMap[$_.Name] = $true }

  $Payload = [ordered]@{
    auto_install_extensions = $ExtensionMap
  }

  $Payload | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $ExtensionsTarget -Encoding utf8
  Write-Host "Exported extension names to auto-install-extensions.json"
  Write-Host "Merge that object into zed/settings.json so Zed installs them on new machines."
} else {
  Write-Host "Skipping extensions; not found in:"
  $ExtensionCandidates | ForEach-Object { Write-Host "  $_" }
}
