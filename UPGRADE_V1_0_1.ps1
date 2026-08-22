$ErrorActionPreference = 'Stop'
$source = Split-Path -Parent $MyInvocation.MyCommand.Path
$target = (Get-Location).Path

if ((Resolve-Path $source).Path -eq (Resolve-Path $target).Path) {
  throw 'No ejecutes este actualizador desde la carpeta de v1.0.1. Ejecutalo desde tu proyecto EvolvAI existente, el que contiene la carpeta android.'
}
if (-not (Test-Path (Join-Path $target 'pubspec.yaml'))) {
  throw 'Ejecuta este script desde la raiz de tu proyecto EvolvAI existente.'
}
if (-not (Test-Path (Join-Path $target 'android'))) {
  throw 'No se encuentra la carpeta android en el proyecto destino. Para esta actualizacion necesito conservar la plataforma Android existente.'
}

Write-Host 'Actualizando EvolvAI a v1.0.1...' -ForegroundColor Cyan
Write-Host 'Destino: ' $target -ForegroundColor DarkGray
Write-Host 'La carpeta android NO se modifica.' -ForegroundColor DarkGray

$targetLib = Join-Path $target 'lib'
$targetTest = Join-Path $target 'test'
if (Test-Path $targetLib) { Remove-Item $targetLib -Recurse -Force }
if (Test-Path $targetTest) { Remove-Item $targetTest -Recurse -Force }
Copy-Item (Join-Path $source 'lib') $targetLib -Recurse -Force
Copy-Item (Join-Path $source 'test') $targetTest -Recurse -Force
Copy-Item (Join-Path $source 'pubspec.yaml') (Join-Path $target 'pubspec.yaml') -Force
Copy-Item (Join-Path $source 'CHANGELOG_V1_0_1.md') (Join-Path $target 'CHANGELOG_V1_0_1.md') -Force

Write-Host 'Actualizacion terminada correctamente.' -ForegroundColor Green
Write-Host 'Siguiente: flutter pub get / flutter analyze / flutter test' -ForegroundColor Yellow
