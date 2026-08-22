$ErrorActionPreference = 'Stop'
$Project = 'C:\Users\i2mTo\EvolvAI-v0.5.0\EvolvAI-v0.5.0'
$PackageRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
Write-Host 'EvolvAI v0.7.3 - actualización segura' -ForegroundColor Cyan
Write-Host "Proyecto: $Project"
Write-Host 'Copia primero lib, test y pubspec.yaml. NO reemplaza android/.' -ForegroundColor Yellow
