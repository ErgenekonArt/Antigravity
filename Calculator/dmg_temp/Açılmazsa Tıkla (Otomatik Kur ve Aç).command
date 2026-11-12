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
