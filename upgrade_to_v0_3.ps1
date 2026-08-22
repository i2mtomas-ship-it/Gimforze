param(
  [Parameter(Mandatory=$true)]
  [string]$ProjectPath
)
$ErrorActionPreference = "Stop"
$sourceRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$project = (Resolve-Path $ProjectPath).Path

Write-Host "Fuente v0.3.0: $sourceRoot"
Write-Host "Proyecto destino: $project"

if (-not (Test-Path "$project\android")) {
  throw "El proyecto destino no tiene carpeta android. Usa primero flutter create --platforms=android . en el proyecto destino."
}

if (Test-Path "$project\lib") { Remove-Item "$project\lib" -Recurse -Force }
Copy-Item "$sourceRoot\lib" "$project\lib" -Recurse -Force
Copy-Item "$sourceRoot\pubspec.yaml" "$project\pubspec.yaml" -Force
Copy-Item "$sourceRoot\README.md" "$project\README.md" -Force
Copy-Item "$sourceRoot\EXERCISE_CATALOG.md" "$project\EXERCISE_CATALOG.md" -Force

$manifest = "$project\android\app\src\main\AndroidManifest.xml"
if (Test-Path $manifest) {
  $xml = Get-Content $manifest -Raw
  if ($xml -notmatch 'android.permission.INTERNET') {
    $xml = $xml -replace '(<manifest[^>]*>)', '$1`r`n    <uses-permission android:name="android.permission.INTERNET" />'
    Set-Content -Path $manifest -Value $xml -Encoding UTF8
  }
}

Set-Location $project
flutter pub get
flutter analyze
flutter test
Write-Host "EvolvAI v0.3.0 actualizado correctamente."
