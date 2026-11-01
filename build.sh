#!/bin/bash
# Usage: ./build.sh test     → run the pure-logic tests
#        ./build.sh install  → test, build, ad-hoc sign, install to ~/Applications/AgentGrid.app and (re)launch
set -euo pipefail
cd "$(dirname "$0")"
OUT=.build; mkdir -p "$OUT"

run_tests() {
  swiftc -O Sources/AgentGrid/Layout.swift Tests/main.swift -o "$OUT/tests" 2>&1
  "$OUT/tests"
}

install_app() {
  run_tests
  APP="$OUT/AgentGrid.app"; rm -rf "$APP"; mkdir -p "$APP/Contents/MacOS"
  cp Info.plist "$APP/Contents/Info.plist"
  swiftc -O -parse-as-library Sources/AgentGrid/*.swift -o "$APP/Contents/MacOS/AgentGrid" 2>&1
  codesign --force --sign - "$APP" >/dev/null
  pkill -x AgentGrid 2>/dev/null || true
  mkdir -p "$HOME/Applications"; rm -rf "$HOME/Applications/AgentGrid.app"
  ditto "$APP" "$HOME/Applications/AgentGrid.app"
  open "$HOME/Applications/AgentGrid.app"
  echo "installed: ~/Applications/AgentGrid.app"
}

case "${1:-}" in
  test) run_tests ;;
  install) install_app ;;
  *) echo "usage: $0 test|install"; exit 2 ;;
esac
