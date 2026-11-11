#!/bin/bash
# -------------------------------------------------------------
# Calculator.app Otomatik Derleyici ve Paketleyici (Universal: Apple Silicon + Intel)
# En Düşük Sistem Gereksinimi: macOS 11.0 (Big Sur, Monterey, Ventura, Sonoma, Sequoia, Tahoe+)
# -------------------------------------------------------------
set -e

cd "$(dirname "$0")"

echo "=========================================================="
echo "🍎 MacBook Calculator.app Derleme Süreci Başlatıldı"
echo "=========================================================="

APP_NAME="Calculator.app"
CONTENTS_DIR="$APP_NAME/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

if [ -d "$APP_NAME" ]; then
    echo "🧹 Eski $APP_NAME temizleniyor..."
    rm -rf "$APP_NAME"
fi

echo "📁 Uygulama paket yapısı oluşturuluyor..."
mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"

echo "🎨 Apple Hesap Makinesi Dock simgesi üretiliyor..."
rm -f "AppIcon.icns"
swift GenerateIcon.swift

if [ -f "AppIcon.icns" ]; then
    echo "🖼️ Simge uygulama paketine kopyalanıyor..."
    cp AppIcon.icns "$RESOURCES_DIR/AppIcon.icns"
fi

echo "📄 Info.plist kimlik kartı ekleniyor..."
cp Info.plist "$CONTENTS_DIR/Info.plist"

echo "⚙️ Swift kodu tüm MacBook'lar (Apple Silicon M1/M2/M3/M4 + Intel x86_64) için derleniyor..."
if swiftc -O -target arm64-apple-macos11.0 Calculator.swift -o "$MACOS_DIR/Calculator_arm64" && \
   swiftc -O -target x86_64-apple-macos11.0 Calculator.swift -o "$MACOS_DIR/Calculator_x86_64"; then
    lipo -create -output "$MACOS_DIR/Calculator" "$MACOS_DIR/Calculator_arm64" "$MACOS_DIR/Calculator_x86_64"
    rm -f "$MACOS_DIR/Calculator_arm64" "$MACOS_DIR/Calculator_x86_64"
    echo "✅ Evrensel (Universal Binary: arm64 + x86_64) derleme tamamlandı!"
    lipo -info "$MACOS_DIR/Calculator" || true
else
    rm -f "$MACOS_DIR/Calculator_arm64" "$MACOS_DIR/Calculator_x86_64"
    ARCH=$(uname -m)
    swiftc -O -target "${ARCH}-apple-macos11.0" Calculator.swift -o "$MACOS_DIR/Calculator"
    echo "✅ Yerel ($ARCH) derleme tamamlandı!"
fi

chmod 755 "$MACOS_DIR/Calculator"
xattr -cr "$APP_NAME" 2>/dev/null || true
echo "🛡️ macOS yerel güvenlik imzası (codesign) uygulanıyor..."
codesign --force --deep --sign - "$APP_NAME" 2>/dev/null || true

touch "$APP_NAME"
echo "🎉 TEBRİKLER! Orijinal Boyutlu ve Simgeli Calculator.app Hazır."
