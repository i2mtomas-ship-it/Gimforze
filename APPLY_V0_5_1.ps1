$ErrorActionPreference = 'Stop'
Write-Host 'Aplicando correccion EvolvAI v0.5.1...'
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$target = Join-Path (Get-Location) 'lib\features\progress\progress_page.dart'
if (-not (Test-Path $target)) { throw "No encuentro $target. Ejecuta este script desde la raiz de tu proyecto EvolvAI v0.5.0." }
Copy-Item $target "$target.bak-v0.5.0" -Force
$s = Get-Content $target -Raw
$s = $s.Replace('canvas.drawLine(0, size.height - 24, size.width, size.height - 24, line..strokeWidth = 1);', 'final axisPaint = Paint()..style = PaintingStyle.stroke..strokeWidth = 1;`r`n    canvas.drawLine(Offset(0, size.height - 24), Offset(size.width, size.height - 24), axisPaint);')
$s = $s.Replace('canvas.drawPath(path, line..strokeWidth = 3);', 'final pathPaint = Paint()..style = PaintingStyle.stroke..strokeWidth = 3;`r`n    canvas.drawPath(path, pathPaint);')
Set-Content $target $s -Encoding UTF8
$sampleTest = Join-Path (Get-Location) 'test\widget_test.dart'
if (Test-Path $sampleTest) { Remove-Item $sampleTest -Force }
Write-Host 'Correccion aplicada.'
Write-Host 'Ahora ejecuta: flutter pub get ; flutter analyze ; flutter test ; flutter run -d emulator-5554'
