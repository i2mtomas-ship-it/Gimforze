$ErrorActionPreference = 'Stop'
$project = Split-Path -Parent $MyInvocation.MyCommand.Path
$target = Read-Host 'Ruta de tu proyecto EvolvAI (ej. C:\Users\i2mTo\EvolvAI-v0.5.0\EvolvAI-v0.5.0)'
if (-not (Test-Path (Join-Path $target 'pubspec.yaml'))) { throw 'No se encontró pubspec.yaml en la ruta indicada.' }
Copy-Item (Join-Path $project 'lib') (Join-Path $target 'lib') -Recurse -Force
Copy-Item (Join-Path $project 'test') (Join-Path $target 'test') -Recurse -Force
Copy-Item (Join-Path $project 'pubspec.yaml') (Join-Path $target 'pubspec.yaml') -Force
Write-Host 'Actualización v0.6.2 aplicada. La carpeta android existente no se modifica.'
