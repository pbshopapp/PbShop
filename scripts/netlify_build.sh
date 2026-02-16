#!/bin/bash
set -euo pipefail

# Instalar Flutter en el workspace
FLUTTER_DIR="$PWD/flutter"
if [ ! -d "$FLUTTER_DIR" ]; then
  git clone https://github.com/flutter/flutter.git -b stable --depth 1 "$FLUTTER_DIR"
fi

export PATH="$FLUTTER_DIR/bin:$PATH"

# Verificar Flutter
flutter --version

# Habilitar web y precache
flutter config --enable-web
flutter precache --web

# Instalar dependencias y compilar
flutter pub get
flutter build web --release
