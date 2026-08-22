$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$source = Join-Path $root "lib"
if (-not (Test-Path $source)) { throw "No se encuentra la carpeta lib del paquete." }
Copy-Item (Join-Path $root "pubspec.yaml") (Join-Path (Get-Location) "pubspec.yaml") -Force
Copy-Item (Join-Path $root "lib") (Join-Path (Get-Location) "lib") -Recurse -Force
Write-Host "EvolvAI v0.8.1: interfaz actualizada. Android no se ha modificado." -ForegroundColor Green
