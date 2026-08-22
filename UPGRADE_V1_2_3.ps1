$ErrorActionPreference = 'Stop'

$source = Split-Path -Parent $MyInvocation.MyCommand.Path
$target = 'C:\Users\i2mTo\EvolvAI-v0.9.0'

Write-Host ''
Write-Host '========================================' -ForegroundColor Cyan
Write-Host '   EVOLVAI v1.2.3 - ESPANOL' -ForegroundColor Cyan
Write-Host '========================================' -ForegroundColor Cyan
Write-Host ''

if (-not (Test-Path (Join-Path $source 'pubspec.yaml'))) { throw "No encuentro pubspec.yaml en $source" }
if (-not (Test-Path (Join-Path $target 'pubspec.yaml'))) { throw "No encuentro el proyecto base en $target" }
if (-not (Test-Path (Join-Path $target 'android'))) { throw "No encuentro la carpeta android en $target. No se sustituye la plataforma Android." }

foreach ($name in @('lib','test')) {
    $src = Join-Path $source $name
    $dst = Join-Path $target $name
    if (Test-Path $dst) { Remove-Item $dst -Recurse -Force }
    Copy-Item $src $dst -Recurse -Force
}
Copy-Item (Join-Path $source 'pubspec.yaml') (Join-Path $target 'pubspec.yaml') -Force

Write-Host '[OK] Codigo v1.2.3 copiado. android se conserva.' -ForegroundColor Green
Write-Host ''
Write-Host 'Ahora ejecuta en el proyecto base:' -ForegroundColor Yellow
Write-Host '  cd "C:\Users\i2mTo\EvolvAI-v0.9.0"'
Write-Host '  flutter pub get'
Write-Host '  flutter test'
Write-Host '  flutter build apk --debug'
Write-Host ''
