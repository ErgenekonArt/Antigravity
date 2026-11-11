# 🍎 MacBook Calculator (Özel Kısayollu Orijinal Hesap Makinesi)

MacBook'larda ayrı bir sayı tuş takımı (numpad) bulunmadığı için hesaplama işlemlerini klavyeden elleri ve parmakları yormadan, en hızlı şekilde yapabilmeniz için geliştirilmiş **tüm MacBook'larla (Apple Silicon M1/M2/M3/M4 ve Intel, en düşük macOS 11.0 ve üzeri)** uyumlu yerel macOS uygulaması.

Orijinal Apple macOS Hesap Makinesi'nin **birebir kompakt boyutları (196 × 324 piksel Temel, 492 × 324 Bilimsel, 344 × 484 Programcı)**, RPN, Dönüştür, Matematik Notları, Geçmiş, Türkçe üst menü çubuğu, simgesi ve güvenli altyapısıyla hazırlanmıştır.

## 📥 Doğrudan İndirme (MacBook `.dmg` Kurulum Paketi)
- **Tek Tıkla İndir (`Calculator.dmg`):** [https://github.com/ErgenekonArt/Antigravity/releases/latest/download/Calculator.dmg](https://github.com/ErgenekonArt/Antigravity/releases/latest/download/Calculator.dmg)
- **GitHub Proje Adresi:** [https://github.com/ErgenekonArt/Antigravity/tree/main/Calculator](https://github.com/ErgenekonArt/Antigravity/tree/main/Calculator)

## ⌨️ Özel Klavye Kısayolları
Bu hesap makinesinde parmakların en rahat uzandığı harfler matematiksel işlemlere dönüştürülmüştür:

| Tuş | Matematiksel İşlem | Açıklama |
| :--- | :--- | :--- |
| **A** (veya **T**) | **+** (Toplama) | İki sayıyı toplar |
| **E** (veya **Ç**) | **−** (Çıkarma) | Sayıdan çıkarma yapar |
| **X** | **×** (Çarpma) | Sayıları çarpar |
| **B** | **÷** (Bölme) | Sayıyı böler |
| **Enter** veya **=** | **=** (Eşittir) | Sonucu hesaplar |
| **Escape** veya **C** | **AC / C** | Sıfırlar veya temizler |
| **Silme** (Backspace) | **⌫** | Son basamağı siler |
| **,** veya **.** | **,** (Virgül) | Ondalık basamak ekler |
| **%** | **%** (Yüzde) | Yüzdesini alır |
| **⌘ + C** / **⌘ + V** | **Kopyala / Yapıştır** | Ekrandaki sonucu kopyalar veya sayı yapıştırır |
| **⌘ + Q** / **⌘ + W** | **Çıkış / Kapat** | Uygulamayı standart Mac kısayoluyla kapatır |

> **Apple Tasarım İnceliği:** Bir işlem tuşuna bastığınızda (örneğin **T** tuşu ile toplama), buton Apple'ın orijinal hesap makinesindeki gibi beyaz renge bürünerek hangi işlemin aktif olduğunu gösterir!

---

## 🚀 Mac'inizde Nasıl .app Oluşturup Çalıştırırsınız? (Çok Kolay!)
1. **Klasörü Mac'inize Aktarın:** Bu `Calculator` klasörünü AirDrop, USB bellek veya bulut ile MacBook'unuza kopyalayın.
2. **Tek Tıkla Uygulamanızı Oluşturun:** Klasörün içindeki `BuildCalculator.command` dosyasına çift tıklayın! *(Eğer Mac ilk açılışta güvenlik uyarısı verirse; dosyaya sağ tıklayıp "Aç" (Open) deyin ve onaylayın).*
   - Kodlar hem **Apple Silicon (M1/M2/M3/M4)** hem **Intel** işlemcilerde çalışacak şekilde **Evrensel (Universal)** olarak derlenir.
   - Orijinal Apple tarzı 1024x1024 piksellik `AppIcon.icns` simgesi otomatik üretilir.
   - Yerel güvenlik imzası (`codesign`) uygulanarak `Calculator.app` hazır hale getirilir.
3. **Kullanın:** Oluşan `Calculator.app` uygulamasına çift tıklayıp açın veya Mac'inizin **Uygulamalar** klasörüne taşıyın.

---

## 🎁 Arkadaşınıza Göndermek İçin: Tek Tıkla DMG Paketi Yapma
Arkadaşınıza tek bir kurulum dosyası göndermek isterseniz:
1. `CreateDMG.command` dosyasına çift tıklayın.
2. Otomatik olarak arkadaşınıza gönderebileceğiniz **`Calculator.dmg`** kargo paketi oluşacaktır!
3. Bu tek dosyayı arkadaşınıza WhatsApp, AirDrop veya e-posta ile gönderebilirsiniz.

> **Arkadaşınızın Bilmesi Gereken Güvenlik Adımı:** İnternetten indirdiği için Mac ilk açılışta *"Geliştiricisi doğrulanamadı"* diyebilir. Arkadaşınızın uygulamaya sağ tıklayıp "Aç" demesi ve mavi renkli "Aç" butonuna basması yeterlidir (sadece ilk seferde bir kez yapılır).

---

## 🛡️ Güvenlik ve Kararlılık Standartları
- **Orijinal Kompakt Boyutlar:** Pencere boyutu orijinal MacBook Hesap Makinesi gibi **196 × 324** piksele sabitlenmiş ve kenarlardan çekiştirilerek bozulması kilitlenmiştir.
- **Sıfıra Bölme Koruması:** Sıfıra bölme (`÷ 0`) durumunda çökmeyi engelleyen hata yakalama mekanizması bulunur.
- **Tam Sistem Uyumluluğu:** En düşük **macOS 11.0** tabanıyla macOS 11, 12, 13, 14 ve 15+ sürümlerinin tamamında sorunsuz çalışır.

---
*Başarı paylaşıldıkça değerlenir. 🚀*
