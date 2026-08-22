$ErrorActionPreference = "Stop"
$project = "C:\Users\i2mTo\EvolvAI-v0.5.0\EvolvAI-v0.5.0"
$source = Split-Path -Parent $MyInvocation.MyCommand.Path
Write-Host "Actualizando EvolvAI en $project" -ForegroundColor Cyan
Copy-Item "$source\lib" "$project\lib" -Recurse -Force
Copy-Item "$source\test" "$project\test" -Recurse -Force
Copy-Item "$source\pubspec.yaml" "$project\pubspec.yaml" -Force
Write-Host "Android NO se modifica." -ForegroundColor Green
Set-Location $project
flutter pub get
flutter analyze
flutter test
Write-Host "Actualizacion completada. Para ejecutar: flutter run -d emulator-5554" -ForegroundColor Green
