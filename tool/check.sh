#!/usr/bin/env bash
set -euo pipefail
# Execute verificações pesadas em sequência, mantendo apenas um worker de testes.
flutter_command="${FLUTTER_BIN:-flutter}"
"$flutter_command" --no-version-check pub get
"$flutter_command" --no-version-check analyze --no-pub
"$flutter_command" --no-version-check test --no-pub --concurrency=1
