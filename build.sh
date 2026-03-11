#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

cd "$SCRIPT_DIR"

xcodebuild \
  build \
  -scheme NotEnoughResins \
  -configuration Debug \
  -destination 'platform=macOS' \
  -derivedDataPath "$SCRIPT_DIR/build" \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGN_IDENTITY=-
