$ErrorActionPreference = 'Stop'
$source = Split-Path -Parent $MyInvocation.MyCommand.Path
$target = Get-Location
Write-Host "Actualizando EvolvAI a v0.8.2 desde $source"
Copy-Item "$source\lib" "$target\" -Recurse -Force
Copy-Item "$source\test" "$target\" -Recurse -Force -ErrorAction SilentlyContinue
Copy-Item "$source\pubspec.yaml" "$target\" -Force
Copy-Item "$source\CHANGELOG_V0_8_2.md" "$target\" -Force
Write-Host "Actualización completada. La carpeta android no se modifica."
