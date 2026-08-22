$ErrorActionPreference = 'Stop'
$source = Split-Path -Parent $MyInvocation.MyCommand.Path
$target = Get-Location
Write-Host 'Actualizando EvolvAI a v1.0.6...'
if (-not (Test-Path (Join-Path $target 'pubspec.yaml'))) { throw "La carpeta destino no parece un proyecto Flutter: $target" }
foreach ($name in @('lib','test')) {
  $src = Join-Path $source $name
  $dst = Join-Path $target $name
  if (Test-Path $src) {
    if (Test-Path $dst) { Remove-Item $dst -Recurse -Force }
    Copy-Item $src $dst -Recurse -Force
  }
}
Copy-Item (Join-Path $source 'pubspec.yaml') (Join-Path $target 'pubspec.yaml') -Force
Copy-Item (Join-Path $source 'CHANGELOG_V1_0_6.md') (Join-Path $target 'CHANGELOG_V1_0_6.md') -Force
Copy-Item (Join-Path $source 'README_V1_0_6.md') (Join-Path $target 'README_V1_0_6.md') -Force
Write-Host 'Actualización terminada. La carpeta android NO se modifica.'
