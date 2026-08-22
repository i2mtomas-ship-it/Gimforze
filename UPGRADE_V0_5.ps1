$ErrorActionPreference = 'Stop'
$target = Read-Host 'Ruta de tu proyecto EvolvAI actual (ej. C:\Users\i2mTo\EvolvAI-v0.1.1\EvolvAI)'
if (-not (Test-Path (Join-Path $target 'pubspec.yaml'))) { throw "No encuentro pubspec.yaml en $target" }
$source = Split-Path -Parent $MyInvocation.MyCommand.Path
Copy-Item "$source\lib" $target -Recurse -Force
Copy-Item "$source\test" $target -Recurse -Force
Copy-Item "$source\pubspec.yaml" $target -Force
Copy-Item "$source\README.md" $target -Force
Write-Host "Codigo v0.5.0 copiado. La carpeta android existente NO se ha tocado." -ForegroundColor Green
Set-Location $target
flutter pub get
flutter analyze
flutter test
Write-Host "Si analyze y test estan limpios, genera/ejecuta Android desde esta misma carpeta." -ForegroundColor Cyan
