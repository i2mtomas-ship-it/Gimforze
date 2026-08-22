$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$src = Join-Path $root "lib"
if (!(Test-Path $src)) { throw "No se encuentra lib" }
Write-Host "Actualizando EvolvAI a v0.8.6..."
Write-Host "Esta actualización reemplaza lib y test. No modifica android."
Remove-Item (Join-Path $root "lib") -Recurse -Force
Copy-Item (Join-Path $root "lib_new") (Join-Path $root "lib") -Recurse
Remove-Item (Join-Path $root "lib_new") -Recurse -Force
Write-Host "Actualización completada."
