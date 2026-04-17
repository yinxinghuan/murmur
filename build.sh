#!/bin/bash
# Build Murmur and package into .app bundle
set -e

cd "$(dirname "$0")"

echo "Building Murmur..."
swift build -c release --arch arm64 2>&1

ARCH_DIR=".build/arm64-apple-macosx/release"
APP_DIR="build/Murmur.app/Contents"

# Create app bundle structure
mkdir -p "$APP_DIR/MacOS" "$APP_DIR/Resources" "$APP_DIR/Frameworks"

# Copy executable
cp "$ARCH_DIR/Murmur" "$APP_DIR/MacOS/Murmur"

# Copy Info.plist
cp "Murmur/Info.plist" "$APP_DIR/Info.plist"

# Copy resource bundle if exists
if [ -d "$ARCH_DIR/Murmur_Murmur.bundle" ]; then
    cp -R "$ARCH_DIR/Murmur_Murmur.bundle" "$APP_DIR/Resources/"
fi

# Copy app icon
cp "Murmur/Resources/AppIcon.icns" "$APP_DIR/Resources/AppIcon.icns" 2>/dev/null || true

# Copy any framework dependencies
if [ -d "$ARCH_DIR/PackageFrameworks" ]; then
    cp -R "$ARCH_DIR/PackageFrameworks"/* "$APP_DIR/Frameworks/" 2>/dev/null || true
fi

# Sign
codesign --force --deep --sign - "build/Murmur.app"

echo ""
echo "Done! App bundle at: build/Murmur.app"
echo ""
echo "To install:"
echo "  cp -R build/Murmur.app /Applications/"
echo ""
