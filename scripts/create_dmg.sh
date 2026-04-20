#!/bin/bash
# Create a DMG installer with background image and Applications symlink
set -e

cd "$(dirname "$0")/.."

APP_PATH="build/Murmur.app"
DMG_NAME="Murmur-${1:-dev}"
DMG_DIR="build/dmg_staging"
DMG_PATH="build/${DMG_NAME}.dmg"
BG_IMG="Murmur/Resources/dmg_background.png"
VOLUME_NAME="Murmur"

if [ ! -d "$APP_PATH" ]; then
    echo "Error: $APP_PATH not found. Run build.sh first."
    exit 1
fi

echo "Creating DMG: $DMG_NAME..."

# Unmount any previous volume and clean staging
hdiutil detach "/Volumes/$VOLUME_NAME" 2>/dev/null || true
rm -rf "$DMG_DIR" "$DMG_PATH"
mkdir -p "$DMG_DIR"

# Copy app and create Applications symlink + set icon from system
cp -R "$APP_PATH" "$DMG_DIR/"
ln -s /Applications "$DMG_DIR/Applications"

# Create temporary DMG (read-write)
TEMP_DMG="build/${DMG_NAME}_temp.dmg"
hdiutil create -srcfolder "$DMG_DIR" -volname "$VOLUME_NAME" -fs HFS+ \
    -fsargs "-c c=64,a=16,e=16" -format UDRW -size 200m "$TEMP_DMG" -quiet

# Mount it
MOUNT_DIR="/Volumes/$VOLUME_NAME"
hdiutil attach -readwrite -noverify "$TEMP_DMG" -quiet
echo "Mounted at: $MOUNT_DIR"

if [ ! -d "$MOUNT_DIR" ]; then
    echo "Error: Failed to mount DMG at $MOUNT_DIR"
    exit 1
fi

# Copy background image
mkdir -p "$MOUNT_DIR/.background"
cp "$BG_IMG" "$MOUNT_DIR/.background/background.png"

# Set DMG window appearance via AppleScript
osascript <<APPLESCRIPT
tell application "Finder"
    tell disk "$VOLUME_NAME"
        open
        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        set bounds of container window to {100, 100, 760, 500}
        set theViewOptions to icon view options of container window
        set arrangement of theViewOptions to not arranged
        set icon size of theViewOptions to 80
        set text size of theViewOptions to 12
        set label position of theViewOptions to bottom
        set background picture of theViewOptions to file ".background:background.png"
        set position of item "Murmur.app" of container window to {165, 200}
        set position of item "Applications" of container window to {495, 200}
        close
        open
        update without registering applications
        delay 1
        close
    end tell
end tell
APPLESCRIPT

# Finalize
sync
hdiutil detach "$MOUNT_DIR" -quiet
hdiutil convert "$TEMP_DMG" -format UDZO -imagekey zlib-level=9 -o "$DMG_PATH" -quiet
rm -f "$TEMP_DMG"
rm -rf "$DMG_DIR"

echo ""
echo "Done! DMG at: $DMG_PATH"
ls -lh "$DMG_PATH"
