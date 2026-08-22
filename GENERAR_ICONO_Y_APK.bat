@echo off
setlocal
cd /d "%~dp0"
echo ==========================================
echo GIMFORZE - ICONO + APK
echo ==========================================
call flutter pub get
if errorlevel 1 goto error
call dart run flutter_launcher_icons
if errorlevel 1 goto error
call flutter clean
call flutter pub get
call flutter build apk --release
if errorlevel 1 goto error
echo.
echo APK generada:
echo %CD%\build\app\outputs\flutter-apk\app-release.apk
pause
exit /b 0
:error
echo.
echo ERROR. Revisa el mensaje anterior.
pause
exit /b 1
