$ErrorActionPreference = "Stop"

$RootDir = Split-Path -Parent $PSScriptRoot
Set-Location $RootDir

$EnvFile = Join-Path $RootDir ".env"
$EnvExample = Join-Path $RootDir ".env.example"

if (-not (Test-Path $EnvFile)) {
    Copy-Item $EnvExample $EnvFile
    Write-Host "Created .env — edit PLAYIT_SECRET_KEY and SERVER_PASS before playing."
}

$PluginsDir = Join-Path $RootDir "config\bepinex\plugins"
New-Item -ItemType Directory -Force -Path $PluginsDir | Out-Null

& (Join-Path $PSScriptRoot "install-servercharacters.ps1")

Write-Host ""
Write-Host "Starting server..."
docker compose up -d
if ($LASTEXITCODE -ne 0) {
    throw "docker compose failed. Is Docker Desktop running?"
}

Write-Host ""
Write-Host "Done. Logs: docker compose logs -f valheim"
