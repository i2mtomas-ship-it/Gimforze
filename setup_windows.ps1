$ErrorActionPreference = 'Stop'
Write-Host 'EvolvAI - inicializacion del proyecto' -ForegroundColor Cyan
if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
  Write-Error 'Flutter no esta instalado o no esta en PATH. Instala Flutter 3.44.x o superior y vuelve a ejecutar este script.'
}
flutter --version
flutter create --platforms=android,ios .
flutter pub get
flutter analyze
flutter test
Write-Host 'EvolvAI inicializado y validado por Flutter.' -ForegroundColor Green
