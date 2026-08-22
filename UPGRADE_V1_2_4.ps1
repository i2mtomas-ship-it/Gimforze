$ErrorActionPreference = 'Stop'
$source = Split-Path -Parent $MyInvocation.MyCommand.Path
$target = "C:\Users\i2mTo\EvolvAI-v0.9.0"
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "   EVOLVAI v1.2.4 - NOMBRES ES/EN" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
if (-not (Test-Path (Join-Path $target 'pubspec.yaml'))) { throw "No encuentro el proyecto base en $target" }
if (-not (Test-Path (Join-Path $target 'android'))) { throw "No encuentro la carpeta android en $target" }
foreach ($name in @('lib','test')) {
  $src=Join-Path $source $name; $dst=Join-Path $target $name
  if (Test-Path $dst) { Remove-Item $dst -Recurse -Force }
  Copy-Item $src $dst -Recurse -Force
}
Copy-Item (Join-Path $source 'pubspec.yaml') (Join-Path $target 'pubspec.yaml') -Force
Write-Host '[OK] Código v1.2.4 copiado. android se conserva.' -ForegroundColor Green
Write-Host 'Ahora entra en el proyecto base y genera el APK:'
Write-Host '  cd "C:\Users\i2mTo\EvolvAI-v0.9.0"'
Write-Host '  flutter pub get'
Write-Host '  flutter test'
Write-Host '  flutter build apk --debug'
