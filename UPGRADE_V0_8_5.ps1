$ErrorActionPreference = 'Stop'
$source = Split-Path -Parent $MyInvocation.MyCommand.Path
$target = Get-Location
Write-Host 'Actualizando EvolvAI a v0.8.5...' -ForegroundColor Cyan
Copy-Item "$source\lib\*" "$target\lib" -Recurse -Force
Copy-Item "$source\test\*" "$target\test" -Recurse -Force
Copy-Item "$source\pubspec.yaml" "$target\pubspec.yaml" -Force
Copy-Item "$source\CHANGELOG_V0_8_5.md" "$target\CHANGELOG_V0_8_5.md" -Force
Write-Host 'Actualización completada. La carpeta android no se modifica.' -ForegroundColor Green
