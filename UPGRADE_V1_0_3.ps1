$ErrorActionPreference = "Stop"
$source = Split-Path -Parent $MyInvocation.MyCommand.Path
$target = (Get-Location).Path
if (-not (Test-Path (Join-Path $target 'pubspec.yaml'))) { throw "Ejecuta este script desde la raiz del proyecto Flutter que ya tiene android." }
if (-not (Test-Path (Join-Path $target 'android'))) { throw "No se encuentra la carpeta android en el proyecto destino. No se modifica nada." }
Write-Host "Actualizando EvolvAI a v1.0.3..."
Remove-Item (Join-Path $target 'lib') -Recurse -Force
Copy-Item (Join-Path $source 'lib') (Join-Path $target 'lib') -Recurse -Force
Remove-Item (Join-Path $target 'test') -Recurse -Force
Copy-Item (Join-Path $source 'test') (Join-Path $target 'test') -Recurse -Force
Copy-Item (Join-Path $source 'pubspec.yaml') (Join-Path $target 'pubspec.yaml') -Force
Copy-Item (Join-Path $source 'CHANGELOG_V1_0_3.md') (Join-Path $target 'CHANGELOG_V1_0_3.md') -Force
Write-Host "Actualizacion v1.0.3 completada. La carpeta android NO se ha modificado."
