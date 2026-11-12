#!/bin/bash
# -------------------------------------------------------------
# Calculator.dmg Paylaşım Paketi Oluşturucu (Universal: Intel + Apple Silicon)
#
# Bu betik hataları GİZLEMEZ: bir şey ters giderse nedenini yazar ve durur.
# -------------------------------------------------------------
set -euo pipefail

cd "$(dirname "$0")"

fail() {
    echo ""
    echo "❌ HATA: $1"
    echo ""
    exit 1
}

echo "=========================================================="
echo "🎁 Calculator.dmg Kurulum Paketi Hazırlanıyor..."
echo "=========================================================="

APP_NAME="Calculator.app"
INSTALL_APP_NAME="Hesap Makinesi (Özel).app"
DMG_NAME="Calculator.dmg"
TEMP_DIR="dmg_temp"

[ "$(uname -s)" = "Darwin" ] || fail "Bu betik sadece macOS (Mac) üzerinde çalışır."

for tool in hdiutil ditto lipo codesign; do
    command -v "$tool" >/dev/null 2>&1 || fail "'$tool' aracı bulunamadı."
done

[ -f "./BuildCalculator.command" ] || fail "BuildCalculator.command bu klasörde yok."

# Hata olsa da olmasa da geçici klasör en sonda temizlensin
trap 'rm -rf "$TEMP_DIR"' EXIT

# 1. Her zaman en güncel Universal (Intel + Apple Silicon) .app paketini derle
echo "🔄 En güncel Universal (Intel + Apple Silicon) Calculator.app derleniyor..."
chmod +x ./BuildCalculator.command
./BuildCalculator.command

# 1b. Paylaşılacak uygulama GERÇEKTEN her iki işlemciyi de destekliyor mu?
ARCHS="$(lipo -archs "$APP_NAME/Contents/MacOS/Calculator")"
case "$ARCHS" in *arm64*) ;; *) fail "Uygulamada Apple Silicon (arm64) desteği yok. Paylaşılabilir bir paket üretilmedi." ;; esac
case "$ARCHS" in *x86_64*) ;; *) fail "Uygulamada Intel (x86_64) desteği yok. Paylaşılabilir bir paket üretilmedi." ;; esac
echo "✅ Mimari kontrolü geçti: $ARCHS"

# 2. Eski DMG ve geçici klasörü temizle
rm -rf "$TEMP_DIR" "$DMG_NAME"
mkdir -p "$TEMP_DIR"

# 3. Uygulamayı geçici paket klasörüne kopyala ve imzasını doğrula
echo "📦 Uygulama kargo paketine yerleştiriliyor..."
ditto "$APP_NAME" "$TEMP_DIR/$INSTALL_APP_NAME"
chmod 755 "$TEMP_DIR/$INSTALL_APP_NAME/Contents/MacOS/Calculator"
codesign --verify --deep --strict "$TEMP_DIR/$INSTALL_APP_NAME" \
    || fail "Kopyalanan uygulamanın imzası geçersiz."

# 4. Alıcının Mac'inde çalışacak, ONAY İSTEYEN kurucuyu ekle
cat << 'EOF' > "$TEMP_DIR/Açılmazsa Tıkla (Otomatik Kur ve Aç).command"
#!/bin/bash
cd "$(dirname "$0")"

SOURCE_APP="Hesap Makinesi (Özel).app"
FINAL_NAME="Hesap Makinesi (Özel).app"

echo "=========================================================="
echo "🍎 MacBook Hesap Makinesi Kurulumu"
echo "=========================================================="

if [ ! -d "$SOURCE_APP" ]; then
    echo "❌ HATA: '$SOURCE_APP' bulunamadı. Bu dosyayı DMG diskinin içinden çalıştırın."
    exit 1
fi

# Yönetici değilseniz /Applications'a yazılamaz; o zaman kendi Uygulamalar klasörünüze kurulur.
if [ -w "/Applications" ]; then
    DEST_DIR="/Applications"
else
    DEST_DIR="$HOME/Applications"
    mkdir -p "$DEST_DIR"
fi
TARGET_APP="$DEST_DIR/$FINAL_NAME"

echo ""
echo "Şunlar yapılacak:"
echo "  1) Uygulama şu konuma kopyalanacak: $TARGET_APP"
echo "  2) macOS güvenlik izni gerekebilir; bu kurucu güvenlik işaretlerini silmez."
if [ -e "$TARGET_APP" ]; then
    echo "❌ Aynı isimli uygulama zaten var; üzerine yazılmadı."
    exit 1
fi
echo "Başka hiçbir dosyaya dokunulmayacak."
echo ""
read -r -p "Devam edilsin mi? (E = Evet / H = Hayır): " ANSWER

case "$ANSWER" in
    E|e|Evet|evet|EVET) ;;
    *) echo "İptal edildi. Hiçbir şey değiştirilmedi."; exit 0 ;;
esac

if ! mkdir "$TARGET_APP"; then
    echo "❌ HATA: Hedef klasör zaten var; hiçbir şeyin üzerine yazılmadı."
    exit 1
fi
if ! ditto "$SOURCE_APP/." "$TARGET_APP"; then
    rm -rf "$TARGET_APP"
    echo "❌ HATA: Kopyalama başarısız oldu."
    exit 1
fi
chmod 755 "$TARGET_APP/Contents/MacOS/Calculator"

if ! codesign --verify --deep --strict "$TARGET_APP"; then
    echo "❌ HATA: Uygulamanın imzası geçersiz. Dosya bozulmuş olabilir; DMG'yi yeniden indirin."
    exit 1
fi

echo "✅ Kurulum tamamlandı! Uygulama açılıyor..."
open "$TARGET_APP" || echo "⚠️ Uygulama otomatik açılamadı. Şu konumdan elle açabilirsiniz: $TARGET_APP"
EOF
chmod 755 "$TEMP_DIR/Açılmazsa Tıkla (Otomatik Kur ve Aç).command"

# 4b. Yeni macOS sürümleri için adım adım Türkçe yardım dosyası
cat << 'EOF' > "$TEMP_DIR/BENİ OKU.txt"
MacBook Hesap Makinesi (Özel) - Kurulum Yardımı
===============================================

1) "Hesap Makinesi (Özel).app" uygulamasını "Uygulamalar" klasörüne sürükleyin.
   Apple'ın kendi Hesap Makinesi ayrı kalır.

2) İlk açılışta güvenlik uyarısı çıkabilir. Uygulama Developer ID ile
   imzalanıp Apple tarafından noter onayından geçirilmediği için macOS izin
   istemektedir.

   macOS 15 ve macOS 26:
     a) Uygulamayı açmayı deneyin, çıkan uyarıyı kapatın.
     b) Sistem Ayarları > Gizlilik ve Güvenlik bölümünü açın.
     c) Uygulama için sunulan açma izni seçeneğini kullanın.

   macOS 11 - 14:
     Uygulamaya sağ tıklayın ve "Aç" deyin.

3) Aynı isimli uygulama zaten kuruluysa kurucu durur; mevcut dosyayı değiştirmez.
   Hata alırsanız mesajı not edin. Güvenlik işaretlerini silen Terminal
   komutları kullanmayın.

4) Kurulum betiği de ilk kullanımda macOS güvenlik uyarısı gösterebilir.
   Yalnızca bu projeye güveniyorsanız çalıştırın.
EOF

# 5. 'Uygulamalar' (Applications) kısayolunu oluştur
echo "🔗 'Uygulamalar' klasörü kısayolu ekleniyor..."
ln -s /Applications "$TEMP_DIR/Uygulamalar"

# 6. Apple hdiutil aracı ile sıkıştırılmış DMG oluştur
echo "💿 Sıkıştırılmış Calculator.dmg diski oluşturuluyor..."
hdiutil create -volname "Calculator" -srcfolder "$TEMP_DIR" -ov -format UDZO "$DMG_NAME" \
    || fail "DMG oluşturulamadı."

echo "🔍 DMG doğrulanıyor..."
hdiutil verify "$DMG_NAME" >/dev/null \
    || fail "DMG doğrulaması başarısız oldu."

echo ""
echo "=========================================================="
echo "🎉 TEBRİKLER! Arkadaşınıza Gönderebileceğiniz Paket Hazır."
echo "=========================================================="
echo "📍 Dosya: $(pwd)/$DMG_NAME"
echo ""
echo "💡 Bu tek dosyayı AirDrop, WhatsApp veya E-Posta ile gönderebilirsiniz."
echo "ℹ️ Alıcı ilk açılışta güvenlik uyarısı görebilir; DMG içindeki 'BENİ OKU.txt' dosyası nasıl açılacağını anlatır."
echo ""
echo "Çıkmak için bu pencereyi kapatabilirsiniz."
