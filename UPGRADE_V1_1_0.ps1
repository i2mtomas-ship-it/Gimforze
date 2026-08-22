$ErrorActionPreference = 'Stop'
$source = Split-Path -Parent $MyInvocation.MyCommand.Path
$target = (Get-Location).Path
Write-Host 'Actualizando EvolvAI a v1.1.0...'
if (-not (Test-Path (Join-Path $target 'pubspec.yaml'))) { throw "La carpeta destino no parece un proyecto Flutter: $target" }
if (-not (Test-Path (Join-Path $target 'android'))) { Write-Warning 'No se ha encontrado la carpeta android. Si quieres conservar la plataforma Android existente, ejecuta este script desde tu proyecto Flutter que ya la contiene.' }
foreach ($name in @('lib','test')) {
  $src = Join-Path $source $name
  $dst = Join-Path $target $name
  if (Test-Path $src) {
    if (Test-Path $dst) { Remove-Item $dst -Recurse -Force }
    Copy-Item $src $dst -Recurse -Force
  }
}
Copy-Item (Join-Path $source 'pubspec.yaml') (Join-Path $target 'pubspec.yaml') -Force
foreach ($name in @('CHANGELOG_V1_1_0.md','README_V1_1_0.md')) {
  $src = Join-Path $source $name
  if (Test-Path $src) { Copy-Item $src (Join-Path $target $name) -Force }
}
Write-Host 'Actualización terminada. La carpeta android NO se modifica.'
