$ErrorActionPreference = "Stop"

$RootDir = Split-Path -Parent $PSScriptRoot
$PluginsDir = Join-Path $RootDir "config\bepinex\plugins"
$Version = if ($env:SERVERCHARACTERS_VERSION) { $env:SERVERCHARACTERS_VERSION } else { "1.4.16" }
$DownloadUrl = "https://thunderstore.io/package/download/Smoothbrain/ServerCharacters/$Version/"

New-Item -ItemType Directory -Force -Path $PluginsDir | Out-Null

$TempZip = Join-Path $env:TEMP "ServerCharacters-$Version.zip"
$TempDir = Join-Path $env:TEMP "ServerCharacters-$Version"

Write-Host "Downloading ServerCharacters $Version..."
Invoke-WebRequest -Uri $DownloadUrl -OutFile $TempZip -UseBasicParsing

if (Test-Path $TempDir) {
    Remove-Item -Recurse -Force $TempDir
}
New-Item -ItemType Directory -Force -Path $TempDir | Out-Null
Expand-Archive -Path $TempZip -DestinationPath $TempDir -Force

$SourceDll = Join-Path $TempDir "ServerCharacters.dll"
$TargetDll = Join-Path $PluginsDir "ServerCharacters.dll"
Copy-Item -Path $SourceDll -Destination $TargetDll -Force

Remove-Item -Force $TempZip
Remove-Item -Recurse -Force $TempDir

Write-Host "Installed: $TargetDll"
