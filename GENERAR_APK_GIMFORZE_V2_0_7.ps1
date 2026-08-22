$ErrorActionPreference = 'Stop'
$source = Split-Path -Parent $MyInvocation.MyCommand.Path
$target = "C:\Users\i2mTo\EvolvAI-v0.9.0"

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "   GIMFORZE v2.0.7 - ICONO Y CORRECCIONES" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

if (-not (Test-Path (Join-Path $source 'pubspec.yaml'))) { throw "No encuentro pubspec.yaml en $source." }
if (-not (Test-Path (Join-Path $target 'pubspec.yaml'))) { throw "No encuentro el proyecto base en $target." }
if (-not (Test-Path (Join-Path $target 'android'))) { throw "No encuentro la carpeta android en $target." }

foreach ($name in @('lib','test','assets')) {
  $src = Join-Path $source $name
  $dst = Join-Path $target $name
  if (Test-Path $src) {
    if (Test-Path $dst) { Remove-Item $dst -Recurse -Force }
    Copy-Item $src $dst -Recurse -Force
  }
}
Copy-Item (Join-Path $source 'pubspec.yaml') (Join-Path $target 'pubspec.yaml') -Force
Copy-Item (Join-Path $source 'README_V2_0_6.md') (Join-Path $target 'README_V2_0_6.md') -Force
Copy-Item (Join-Path $source 'CHANGELOG_V2_0_6.md') (Join-Path $target 'CHANGELOG_V2_0_6.md') -Force

$manifest = Join-Path $target 'android\app\src\main\AndroidManifest.xml'
if (Test-Path $manifest) {
  $text = Get-Content $manifest -Raw
  $text = $text -replace 'EvolvAI','Gimforze'
  Set-Content $manifest $text -Encoding UTF8
}
$strings = Join-Path $target 'android\app\src\main\res\values\strings.xml'
if (Test-Path $strings) {
  $text = Get-Content $strings -Raw
  $text = $text -replace 'EvolvAI','Gimforze'
  Set-Content $strings $text -Encoding UTF8
}

$iconSource = Join-Path $source 'android_icon_resources'
$iconTarget = Join-Path $target 'android\app\src\main\res'
if (Test-Path $iconSource) {
  foreach ($d in Get-ChildItem $iconSource -Directory) {
    $dstDir = Join-Path $iconTarget $d.Name
    if (-not (Test-Path $dstDir)) { New-Item -ItemType Directory -Path $dstDir -Force | Out-Null }
    Copy-Item (Join-Path $d.FullName '*') $dstDir -Recurse -Force
  }
  Write-Host '[OK] Icono Android Gimforze instalado.' -ForegroundColor Green
}

Set-Location $target
Write-Host "[OK] Código v2.0.7 copiado. Icono Gimforze instalado. Android/applicationId conservados." -ForegroundColor Green
Write-Host "[1/4] flutter clean" -ForegroundColor Yellow
flutter clean
Write-Host "[2/4] flutter pub get" -ForegroundColor Yellow
flutter pub get
Write-Host "[3/4] flutter test" -ForegroundColor Yellow
flutter test
Write-Host "[4/4] flutter build apk --debug" -ForegroundColor Yellow
flutter build apk --debug

$apk = Join-Path $target 'build\app\outputs\flutter-apk\app-debug.apk'
if (-not (Test-Path $apk)) { throw "Flutter terminó pero no encuentro la APK en $apk" }
$desktop = Join-Path $env:USERPROFILE 'Desktop\Gimforze-v2.0.7.apk'
Copy-Item $apk $desktop -Force
Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host " APK GENERADA CORRECTAMENTE" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host "APK: $desktop" -ForegroundColor Green
Write-Host ""
