#!/bin/bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$ROOT_DIR/build"
PRODUCTS_DIR="$BUILD_DIR/Products"
STAGING_DIR="$BUILD_DIR/dmg"
APP_PATH="$PRODUCTS_DIR/Release/nohand.app"

rm -rf "$PRODUCTS_DIR" "$STAGING_DIR"
mkdir -p "$STAGING_DIR"

echo "Building universal Release application..."
xcodebuild \
  -project "$ROOT_DIR/nohand.xcodeproj" \
  -scheme nohand \
  -configuration Release \
  -destination 'generic/platform=macOS' \
  -derivedDataPath "$BUILD_DIR/DerivedData" \
  CONFIGURATION_BUILD_DIR="$PRODUCTS_DIR/Release" \
  ARCHS='arm64 x86_64' \
  ONLY_ACTIVE_ARCH=NO \
  CODE_SIGNING_ALLOWED=NO \
  clean build

if [[ ! -d "$APP_PATH" ]]; then
  echo "Build failed: $APP_PATH was not created." >&2
  exit 1
fi

# An ad-hoc signature is sufficient for a local installer without an Apple
# Developer certificate. Public distribution still requires notarization.
codesign --force --deep --sign - --options runtime "$APP_PATH"
codesign --verify --deep --strict --verbose=2 "$APP_PATH"

VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$APP_PATH/Contents/Info.plist")"
DMG_PATH="$BUILD_DIR/NoHand-$VERSION.dmg"

ditto "$APP_PATH" "$STAGING_DIR/NoHand.app"
ln -s /Applications "$STAGING_DIR/Applications"
rm -f "$DMG_PATH"

echo "Creating $DMG_PATH..."
hdiutil create \
  -volname "NoHand $VERSION" \
  -srcfolder "$STAGING_DIR" \
  -ov \
  -format UDZO \
  "$DMG_PATH"

echo "Created: $DMG_PATH"
