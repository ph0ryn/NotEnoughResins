#!/usr/bin/env bash

rm -rf ./build
mkdir ./build

xcodebuild \
  archive \
  -project NotEnoughResins.xcodeproj \
  -scheme NotEnoughResins \
  -archivePath build/archive.xcarchive \
  -configuration Release \
  -destination "platform=macOS" \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGN_IDENTITY=-

cp -r build/archive.xcarchive/Products/Applications/NotEnoughResins.app ./build/NotEnoughResins.app

echo "Build complete!"
