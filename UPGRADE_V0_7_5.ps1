$ErrorActionPreference = "Stop"
$project = Get-Location
if (-not (Test-Path (Join-Path $project 'pubspec.yaml'))) { throw "Ejecuta este script desde la raíz del proyecto Flutter EvolvAI." }
$source = Split-Path -Parent $MyInvocation.MyCommand.Path
Copy-Item (Join-Path $source 'lib') (Join-Path $project 'lib') -Recurse -Force
Copy-Item (Join-Path $source 'test') (Join-Path $project 'test') -Recurse -Force
Copy-Item (Join-Path $source 'pubspec.yaml') (Join-Path $project 'pubspec.yaml') -Force
Write-Host "EvolvAI v0.7.5 actualizado. La carpeta android existente NO se modifica." -ForegroundColor Green
