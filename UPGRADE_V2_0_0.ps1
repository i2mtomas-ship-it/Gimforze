$ErrorActionPreference = 'Stop'
$source = Split-Path -Parent $MyInvocation.MyCommand.Path
$target = "C:\Users\i2mTo\EvolvAI-v0.9.0"

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "       GIMFORZE v2.0.0 - ACTUALIZACION" -ForegroundColor Cyan
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

# Cambia solo el nombre visible de la aplicación. No modifica el applicationId para conservar los datos de la instalación anterior.
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

Set-Location $target
Write-Host "[OK] Código, assets y pubspec v2.0.0 copiados. Android conservado." -ForegroundColor Green
Write-Host "[INFO] applicationId NO se modifica para conservar los datos existentes." -ForegroundColor DarkYellow
Write-Host ""
Write-Host "Ejecuta:" -ForegroundColor Cyan
Write-Host "  flutter pub get"
Write-Host "  flutter test"
Write-Host "  flutter build apk --debug"
Write-Host ""
