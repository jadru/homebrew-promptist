#!/bin/bash
set -euo pipefail

# Promptist Release Builder
# Usage: ./scripts/release.sh [version]
# Example: ./scripts/release.sh 1.0.0

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
SCHEME="Promptist"
APP_NAME="Promptist"
BUILD_DIR="$PROJECT_DIR/build/release"
DMG_DIR="$BUILD_DIR/dmg"

# Get version from argument or Xcode project
if [ -n "${1:-}" ]; then
    VERSION="$1"
else
    VERSION=$(grep 'MARKETING_VERSION' "$PROJECT_DIR/Promptist.xcodeproj/project.pbxproj" | head -1 | sed 's/.*= \(.*\);/\1/' | tr -d ' ')
fi

DMG_NAME="${APP_NAME}-${VERSION}.dmg"
ZIP_NAME="${APP_NAME}-${VERSION}.zip"

echo "==> Building $APP_NAME v$VERSION"

# Clean build directory
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

# Build Release
echo "==> Building Release configuration..."
xcodebuild \
    -scheme "$SCHEME" \
    -configuration Release \
    -derivedDataPath "$BUILD_DIR/DerivedData" \
    -archivePath "$BUILD_DIR/$APP_NAME.xcarchive" \
    archive \
    SKIP_INSTALL=NO \
    BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
    2>&1 | tail -3

# Export archive
echo "==> Exporting archive..."
APP_PATH="$BUILD_DIR/$APP_NAME.xcarchive/Products/Applications/$APP_NAME.app"

if [ ! -d "$APP_PATH" ]; then
    echo "Error: $APP_PATH not found"
    exit 1
fi

# Create DMG
echo "==> Creating DMG..."
mkdir -p "$DMG_DIR"
cp -R "$APP_PATH" "$DMG_DIR/"

# Create symlink to /Applications
ln -s /Applications "$DMG_DIR/Applications"

hdiutil create \
    -volname "$APP_NAME" \
    -srcfolder "$DMG_DIR" \
    -ov \
    -format UDZO \
    "$BUILD_DIR/$DMG_NAME"

# Create ZIP (alternative format)
echo "==> Creating ZIP..."
cd "$BUILD_DIR/$APP_NAME.xcarchive/Products/Applications"
zip -r "$BUILD_DIR/$ZIP_NAME" "$APP_NAME.app"
cd "$PROJECT_DIR"

# Calculate SHA256
DMG_SHA256=$(shasum -a 256 "$BUILD_DIR/$DMG_NAME" | awk '{print $1}')
ZIP_SHA256=$(shasum -a 256 "$BUILD_DIR/$ZIP_NAME" | awk '{print $1}')

echo ""
echo "========================================="
echo "  Release Build Complete!"
echo "========================================="
echo ""
echo "Version:  $VERSION"
echo ""
echo "DMG:      $BUILD_DIR/$DMG_NAME"
echo "DMG SHA:  $DMG_SHA256"
echo ""
echo "ZIP:      $BUILD_DIR/$ZIP_NAME"
echo "ZIP SHA:  $ZIP_SHA256"
echo ""
echo "Next steps:"
echo "  1. gh release create v$VERSION '$BUILD_DIR/$DMG_NAME' '$BUILD_DIR/$ZIP_NAME' --title 'Promptist v$VERSION' --generate-notes"
echo "  2. Cask formula will be auto-updated by CI on merge to main"
echo ""
