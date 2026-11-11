#!/bin/bash
set -e
cd "$(dirname "$0")"

APP_NAME="Calculator.app"
DMG_NAME="Calculator.dmg"
TEMP_DIR="dmg_temp"

chmod +x ./BuildCalculator.command
./BuildCalculator.command

rm -rf "$TEMP_DIR" "$DMG_NAME"
mkdir -p "$TEMP_DIR"

cp -R "$APP_NAME" "$TEMP_DIR/"
chmod 755 "$TEMP_DIR/$APP_NAME/Contents/MacOS/Calculator"
xattr -cr "$TEMP_DIR/$APP_NAME" 2>/dev/null || true
codesign --force --deep --sign - "$TEMP_DIR/$APP_NAME" 2>/dev/null || true

cat << 'EOF' > "$TEMP_DIR/Açılmazsa Tıkla (Otomatik Kur ve Aç).command"
#!/bin/bash
cd "$(dirname "$0")"
TARGET_APP="/Applications/Hesap Makinesi (Özel).app"
rm -rf "$TARGET_APP" "/Applications/Calculator 2.app" 2>/dev/null || true
cp -R "Calculator.app" "$TARGET_APP"
xattr -cr "$TARGET_APP" 2>/dev/null || true
chmod 755 "$TARGET_APP/Contents/MacOS/Calculator" 2>/dev/null || true
codesign --force --deep --sign - "$TARGET_APP" 2>/dev/null || true
open "$TARGET_APP"
EOF
chmod 755 "$TEMP_DIR/Açılmazsa Tıkla (Otomatik Kur ve Aç).command"

ln -s /Applications "$TEMP_DIR/Uygulamalar"
hdiutil create -volname "Calculator" -srcfolder "$TEMP_DIR" -ov -format UDZO "$DMG_NAME"
rm -rf "$TEMP_DIR"
