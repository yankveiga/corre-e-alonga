#!/usr/bin/env bash
set -euo pipefail
project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
flutter_command="${FLUTTER_BIN:-flutter}"
android_sdk="${ANDROID_HOME:-${ANDROID_SDK_ROOT:-}}"
if [[ -z "$android_sdk" ]]; then
  echo 'Defina ANDROID_HOME com o caminho do Android SDK.' >&2
  exit 2
fi
cd "$project_root"
"$flutter_command" --no-version-check precache --android_gen_snapshot --android_maven
"$flutter_command" --no-version-check pub get
# pub get pode reescrever local.properties a partir da configuração global.
# Mantenha a escolha local explícita, sem editar a configuração do usuário.
python3 - "$android_sdk" <<'PYSDK'
from pathlib import Path
import sys
properties = Path('android/local.properties')
lines = properties.read_text().splitlines()
lines = [line for line in lines if not line.startswith('sdk.dir=')]
lines.append('sdk.dir=' + sys.argv[1])
properties.write_text('\n'.join(lines) + '\n')
PYSDK
cd android
./gradlew --no-daemon "-Pflutter.androidSdkRoot=$android_sdk" \
  -Ptarget-platform=android-arm64 -Psplit-per-abi=true -Ptarget=lib/main.dart assembleDebug
