param(
  [string]$Target = "C:\Users\i2mTo\EvolvAI-v0.5.0\EvolvAI-v0.5.0"
)
$Source = Split-Path -Parent $MyInvocation.MyCommand.Path
Write-Host "Actualizando EvolvAI en: $Target"
if (-not (Test-Path (Join-Path $Target 'pubspec.yaml'))) { throw "No se encontró pubspec.yaml en $Target" }
Copy-Item (Join-Path $Source 'lib') $Target -Recurse -Force
Copy-Item (Join-Path $Source 'test') $Target -Recurse -Force
Copy-Item (Join-Path $Source 'pubspec.yaml') $Target -Force
Write-Host "Actualización aplicada. Se conserva la carpeta android existente."
