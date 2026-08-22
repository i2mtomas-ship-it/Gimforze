$ErrorActionPreference = 'Stop'
$source = Split-Path -Parent $MyInvocation.MyCommand.Path
$target = Get-Location
Write-Host 'Actualizando EvolvAI a v1.0.5...'
if (-not (Test-Path (Join-Path $target 'pubspec.yaml'))) { throw "La carpeta destino no parece un proyecto Flutter: $target" }
if (-not (Test-Path (Join-Path $target 'android'))) { Write-Warning 'No se encuentra android en el destino. Se conservará el proyecto actual sin generarlo.' }
foreach ($name in @('lib','test')) {
  $src = Join-Path $source $name
  $dst = Join-Path $target $name
  if (Test-Path $src) {
    if (Test-Path $dst) { Remove-Item $dst -Recurse -Force }
    Copy-Item $src $dst -Recurse -Force
  }
}
Copy-Item (Join-Path $source 'pubspec.yaml') (Join-Path $target 'pubspec.yaml') -Force
foreach ($file in @('CHANGELOG_V1_0_5.md','README_V1_0_5.md')) { Copy-Item (Join-Path $source $file) (Join-Path $target $file) -Force }
Write-Host 'Actualización terminada. La carpeta android NO se modifica.'
