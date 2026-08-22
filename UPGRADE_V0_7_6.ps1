$ErrorActionPreference = 'Stop'
$source = Split-Path -Parent $MyInvocation.MyCommand.Path
$target = Get-Location
Write-Host "Actualizando EvolvAI a v0.7.6..."
Copy-Item "$source\lib\*" "$target\lib" -Recurse -Force
Copy-Item "$source\test\*" "$target\test" -Recurse -Force
Copy-Item "$source\pubspec.yaml" "$target\pubspec.yaml" -Force
Write-Host "Actualización completada. La carpeta android no se modifica."
