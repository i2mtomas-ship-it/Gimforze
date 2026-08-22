#!/bin/bash
set -e
cd "$(dirname "$0")"
echo "=========================================="
echo " GIMFORZE - ICONO + IPA"
echo "=========================================="
flutter pub get
dart run flutter_launcher_icons
flutter clean
flutter pub get
flutter build ipa --release
echo ""
echo "IPA generada en:"
echo "$(pwd)/build/ios/ipa/"
