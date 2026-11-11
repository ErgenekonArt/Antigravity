#!/bin/bash
# -------------------------------------------------------------
# Calculator.app Otomatik Derleyici ve Paketleyici (Universal: Apple Silicon + Intel)
# En Düşük Sistem Gereksinimi: macOS 11.0 (Big Sur, Monterey, Ventura, Sonoma, Sequoia+)
# -------------------------------------------------------------
set -e

# Betiğin bulunduğu klasöre geçiş yap
cd "$(dirname "$0")"

echo "=========================================================="
echo "🍎 MacBook Calculator.app Derleme Süreci Başlatıldı"
echo "=========================================================="

APP_NAME="Calculator.app"
CONTENTS_DIR="$APP_NAME/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

# 1. Eski derleme varsa temizle
if [ -d "$APP_NAME" ]; then
    echo "🧹 Eski $APP_NAME temizleniyor..."
    rm -rf "$APP_NAME"
fi

# 2. Standart Mac .app klasör hiyerarşisini kur
echo "📁 Uygulama paket yapısı oluşturuluyor..."
mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"

# 3. Apple İkonu (AppIcon.icns) Üretimi (Her derlemede 3. görseldeki güncel ikonu üret)
echo "🎨 Apple Hesap Makinesi Dock simgesi üretiliyor..."
rm -f "AppIcon.icns"
swift GenerateIcon.swift

if [ -f "AppIcon.icns" ]; then
    echo "🖼️ Simge uygulama paketine kopyalanıyor..."
    cp AppIcon.icns "$RESOURCES_DIR/AppIcon.icns"
fi

# 4. Info.plist kimlik dosyasını yerleştir
echo "📄 Info.plist kimlik kartı ekleniyor..."
cp Info.plist "$CONTENTS_DIR/Info.plist"

# 5. Tüm MacBook'lar için Evrensel (Universal: arm64 + x86_64) Derleme (macOS 11.0+)
echo "⚙️ Swift kodu tüm MacBook'lar (Apple Silicon M1/M2/M3/M4 + Intel) için derleniyor..."
if swiftc -O -target arm64-apple-macos11.0 Calculator.swift -o "$MACOS_DIR/Calculator_arm64" 2>/dev/null && \
   swiftc -O -target x86_64-apple-macos11.0 Calculator.swift -o "$MACOS_DIR/Calculator_x86_64" 2>/dev/null; then
    lipo -create -output "$MACOS_DIR/Calculator" "$MACOS_DIR/Calculator_arm64" "$MACOS_DIR/Calculator_x86_64"
    rm -f "$MACOS_DIR/Calculator_arm64" "$MACOS_DIR/Calculator_x86_64"
    echo "✅ Evrensel (Universal Binary) derleme tamamlandı!"
else
    rm -f "$MACOS_DIR/Calculator_arm64" "$MACOS_DIR/Calculator_x86_64"
    ARCH=$(uname -m)
    swiftc -O -target "${ARCH}-apple-macos11.0" Calculator.swift -o "$MACOS_DIR/Calculator"
    echo "✅ Yerel ($ARCH) derleme tamamlandı!"
fi

# 6. Çalıştırma izni ver ve macOS yerel güvenlik imzasını (Ad-Hoc Code Sign) uygula
chmod +x "$MACOS_DIR/Calculator"
echo "🛡️ macOS yerel güvenlik imzası (codesign) uygulanıyor..."
codesign --force --deep --sign - "$APP_NAME" 2>/dev/null || true

# 7. Mac Finder simge önbelleğini yenile
touch "$APP_NAME"

echo ""
echo "=========================================================="
echo "🎉 TEBRİKLER! Orijinal Boyutlu ve Simgeli Calculator.app Hazır."
echo "=========================================================="
echo "📍 Konum: $(pwd)/$APP_NAME"
echo ""
echo "💡 Kullanım:"
echo "1. Calculator.app dosyasına çift tıklayarak hemen açabilirsiniz."
echo "2. İsterseniz 'Uygulamalar' (Applications) klasörünüze sürükleyip kalıcı yapabilirsiniz."
echo ""
echo "Çıkmak için bu pencereyi kapatabilirsiniz."
