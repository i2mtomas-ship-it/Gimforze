# EvolvAI v1.2.1

Corrección de inicio de entrenamiento en Android.

La carpeta `android` del proyecto base se conserva. Para probar en móvil:

```cmd
cd "C:\Users\i2mTo\EvolvAI-v0.9.0"
powershell -ExecutionPolicy Bypass -File "C:\Users\i2mTo\EvolvAI-v1.2.1\UPGRADE_V1_2_1.ps1"
flutter pub get
flutter test
flutter build apk --debug
```

APK: `build\app\outputs\flutter-apk\app-debug.apk`
