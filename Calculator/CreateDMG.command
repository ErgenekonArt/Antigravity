#!/bin/bash
# -------------------------------------------------------------
# Calculator.dmg Arkadaşa Gönderme Paketi Oluşturucu (Apple M1)
# -------------------------------------------------------------
set -e

cd "$(dirname "$0")"

echo "=========================================================="
echo "🎁 Calculator.dmg Kurulum Paketi Hazırlanıyor..."
echo "=========================================================="

APP_NAME="Calculator.app"
DMG_NAME="Calculator.dmg"
TEMP_DIR="dmg_temp"

# 1. Eğer .app henüz derlenmemişse önce derle
if [ ! -d "$APP_NAME" ]; then
    echo "⚠️ Calculator.app bulunamadı, önce derleme başlatılıyor..."
    ./BuildCalculator.command
fi

# 2. Eski DMG ve geçici klasörü temizle
rm -rf "$TEMP_DIR" "$DMG_NAME"
mkdir -p "$TEMP_DIR"

# 3. Uygulamayı geçici paket klasörüne kopyala
echo "📦 Uygulama kargo paketine yerleştiriliyor..."
cp -R "$APP_NAME" "$TEMP_DIR/"

# 4. 'Uygulamalar' (Applications) kısayolunu oluştur
echo "🔗 'Uygulamalar' klasörü kısayolu ekleniyor..."
ln -s /Applications "$TEMP_DIR/Uygulamalar"

# 5. Apple hdiutil aracı ile sıkıştırılmış DMG oluştur
echo "💿 Sıkıştırılmış Calculator.dmg diski oluşturuluyor..."
hdiutil create -volname "Calculator" -srcfolder "$TEMP_DIR" -ov -format UDZO "$DMG_NAME"

# 6. Temizlik
rm -rf "$TEMP_DIR"

echo ""
echo "=========================================================="
echo "🎉 TEBRİKLER! Arkadaşınıza Gönderebileceğiniz Paket Hazır."
echo "=========================================================="
echo "📍 Dosya: $(pwd)/$DMG_NAME"
echo ""
echo "💡 Bu tek dosyayı AirDrop, WhatsApp veya E-Posta ile arkadaşınıza gönderebilirsiniz."
echo "Arkadaşınız çift tıkladığında uygulamayı 'Uygulamalar' klasörüne sürükleyip anında kullanabilir!"
echo ""
echo "Çıkmak için bu pencereyi kapatabilirsiniz."
