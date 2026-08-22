$ErrorActionPreference = 'Stop'
$source = Split-Path -Parent $MyInvocation.MyCommand.Path
$target = (Get-Location).Path
if (-not (Test-Path (Join-Path $target 'pubspec.yaml'))) {
  throw 'Ejecuta este script desde la raíz de tu proyecto EvolvAI.'
}
Write-Host 'Actualizando EvolvAI a v0.9.1...' -ForegroundColor Cyan
Copy-Item (Join-Path $source 'lib') (Join-Path $target 'lib') -Recurse -Force
Copy-Item (Join-Path $source 'test') (Join-Path $target 'test') -Recurse -Force
Copy-Item (Join-Path $source 'pubspec.yaml') (Join-Path $target 'pubspec.yaml') -Force
Copy-Item (Join-Path $source 'CHANGELOG_V0_9_1.md') (Join-Path $target 'CHANGELOG_V0_9_1.md') -Force
$widgetTest = Join-Path $target 'test\widget_test.dart'
if (Test-Path $widgetTest) { Remove-Item $widgetTest -Force }
Write-Host 'Actualización terminada. La carpeta android no se modifica.' -ForegroundColor Green
