#!/bin/bash
# -------------------------------------------------------------
# Calculator.app Otomatik Derleyici ve Paketleyici (Universal: Apple Silicon + Intel)
# En Düşük Sistem Gereksinimi: macOS 11.0 (Big Sur ve sonrası)
#
# Bu betik hataları GİZLEMEZ: bir şey ters giderse nedenini yazar ve durur.
# -------------------------------------------------------------
set -euo pipefail

# Betiğin bulunduğu klasöre geçiş yap
cd "$(dirname "$0")"

fail() {
    echo ""
    echo "❌ HATA: $1"
    echo ""
    exit 1
}

echo "=========================================================="
echo "🍎 MacBook Calculator.app Derleme Süreci Başlatıldı"
echo "=========================================================="

APP_NAME="Calculator.app"
CONTENTS_DIR="$APP_NAME/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

# 0. Ön kontroller: doğru sistem, gerekli araçlar ve gerekli dosyalar var mı?
[ "$(uname -s)" = "Darwin" ] || fail "Bu betik sadece macOS (Mac) üzerinde çalışır."

for tool in swift swiftc lipo codesign plutil; do
    command -v "$tool" >/dev/null 2>&1 || fail "'$tool' aracı bulunamadı. Terminal'e şunu yazıp Apple'ın geliştirici araçlarını kurun, sonra bu betiği tekrar çalıştırın:  xcode-select --install"
done

for f in Calculator.swift GenerateIcon.swift Info.plist; do
    [ -f "$f" ] || fail "'$f' dosyası bu klasörde yok. Tüm dosyalar BuildCalculator.command ile aynı klasörde olmalı."
done

plutil -lint Info.plist >/dev/null || fail "Info.plist dosyası bozuk görünüyor."

# 1. Eski derleme varsa temizle
if [ -d "$APP_NAME" ]; then
    echo "🧹 Eski $APP_NAME temizleniyor..."
    rm -rf "$APP_NAME"
fi

# 2. Standart Mac .app klasör hiyerarşisini kur
echo "📁 Uygulama paket yapısı oluşturuluyor..."
mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"

# 3. Apple İkonu (AppIcon.icns) Üretimi
echo "🎨 Apple Hesap Makinesi Dock simgesi üretiliyor..."
rm -f "AppIcon.icns"
if swift GenerateIcon.swift && [ -f "AppIcon.icns" ]; then
    echo "🖼️ Simge uygulama paketine kopyalanıyor..."
    cp AppIcon.icns "$RESOURCES_DIR/AppIcon.icns"
else
    echo "⚠️ UYARI: Simge üretilemedi. Uygulama varsayılan simgeyle devam edecek."
fi

# 4. Info.plist kimlik dosyasını yerleştir
echo "📄 Info.plist kimlik kartı ekleniyor..."
cp Info.plist "$CONTENTS_DIR/Info.plist"

# 5. Tüm MacBook'lar için Evrensel (Universal: arm64 + x86_64) Derleme (macOS 11.0+)
echo "⚙️ Swift kodu tüm MacBook'lar (Apple Silicon M1/M2/M3/M4 + Intel x86_64) için derleniyor..."
ARM_BIN="$MACOS_DIR/Calculator_arm64"
X86_BIN="$MACOS_DIR/Calculator_x86_64"

if swiftc -O -target arm64-apple-macos11.0 Calculator.swift -o "$ARM_BIN" && \
   swiftc -O -target x86_64-apple-macos11.0 Calculator.swift -o "$X86_BIN"; then
    lipo -create -output "$MACOS_DIR/Calculator" "$ARM_BIN" "$X86_BIN"
    rm -f "$ARM_BIN" "$X86_BIN"
    echo "✅ Evrensel (Universal Binary: arm64 + x86_64) derleme tamamlandı!"
else
    rm -f "$ARM_BIN" "$X86_BIN"
    ARCH="$(uname -m)"
    echo ""
    echo "⚠️ UYARI: Evrensel derleme başarısız oldu. Sadece bu Mac'in işlemcisi ($ARCH) için derleniyor."
    echo "⚠️ Bu uygulama diğer işlemci tipindeki Mac'lerde ÇALIŞMAZ."
    echo ""
    swiftc -O -target "${ARCH}-apple-macos11.0" Calculator.swift -o "$MACOS_DIR/Calculator" \
        || fail "Swift kodu derlenemedi. Yukarıdaki derleyici mesajlarını kontrol edin."
fi

# 6. Çalıştırma izni ver, dosya kalıntılarını temizle ve yerel (ad-hoc) imza uygula
chmod 755 "$MACOS_DIR/Calculator"

echo "🛡️ macOS yerel güvenlik imzası (codesign) uygulanıyor..."
codesign --force --sign - "$APP_NAME" \
    || fail "Uygulama imzalanamadı (codesign). Paket güvenilir biçimde oluşturulamadı."

echo "🔍 İmza doğrulanıyor..."
codesign --verify --deep --strict "$APP_NAME" \
    || fail "İmza doğrulaması başarısız oldu. Uygulama paketi bozuk olabilir."

echo "🧩 Desteklenen işlemci mimarileri: $(lipo -archs "$MACOS_DIR/Calculator")"

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
