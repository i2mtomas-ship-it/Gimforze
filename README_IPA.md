# Generación de IPA de Gimforze

El workflow `.github/workflows/build-ios.yml` crea la plataforma iOS en el runner macOS,
genera el icono de iOS y construye una IPA sin firma con:

`flutter build ipa --release --no-codesign`

No se ejecuta `flutter_launcher_icons` para Android en el runner iOS porque este
repositorio no contiene la plataforma Android completa y esa configuración provocaba
el error `android/app/src/main/AndroidManifest.xml` no encontrado.
