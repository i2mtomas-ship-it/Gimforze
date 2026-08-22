$ErrorActionPreference = 'Stop'
$source = Split-Path -Parent $MyInvocation.MyCommand.Path
$target = (Get-Location).Path
if (-not (Test-Path (Join-Path $target 'pubspec.yaml'))) { throw 'Ejecuta este script desde la raíz de tu proyecto EvolvAI.' }
Write-Host 'Actualizando EvolvAI a v1.0.0...' -ForegroundColor Cyan
$targetLib = Join-Path $target 'lib'
$targetTest = Join-Path $target 'test'
if (Test-Path $targetLib) { Remove-Item $targetLib -Recurse -Force }
if (Test-Path $targetTest) { Remove-Item $targetTest -Recurse -Force }
Copy-Item (Join-Path $source 'lib') $targetLib -Recurse -Force
Copy-Item (Join-Path $source 'test') $targetTest -Recurse -Force
Copy-Item (Join-Path $source 'pubspec.yaml') (Join-Path $target 'pubspec.yaml') -Force
Copy-Item (Join-Path $source 'CHANGELOG_V1_0_0.md') (Join-Path $target 'CHANGELOG_V1_0_0.md') -Force
Write-Host 'Actualización terminada. La carpeta android NO se modifica.' -ForegroundColor Green
