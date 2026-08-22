$ErrorActionPreference = 'Stop'
$source = Split-Path -Parent $MyInvocation.MyCommand.Path
$target = Read-Host 'Ruta de tu proyecto EvolvAI (la carpeta que contiene android y pubspec.yaml)'
if (-not (Test-Path (Join-Path $target 'pubspec.yaml'))) { throw 'No se encontró pubspec.yaml en la ruta indicada.' }
Copy-Item (Join-Path $source 'lib') (Join-Path $target 'lib') -Recurse -Force
Copy-Item (Join-Path $source 'test') (Join-Path $target 'test') -Recurse -Force
Copy-Item (Join-Path $source 'pubspec.yaml') (Join-Path $target 'pubspec.yaml') -Force
Copy-Item (Join-Path $source 'CHANGELOG_V0_8_0.md') (Join-Path $target 'CHANGELOG_V0_8_0.md') -Force
Write-Host 'EvolvAI v0.8.0 actualizada. La carpeta android no se ha modificado.'
