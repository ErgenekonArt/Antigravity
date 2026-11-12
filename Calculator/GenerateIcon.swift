import AppKit
import CoreGraphics

// MARK: - 3. Görseldeki Orijinal macOS Dock İkonu Tasarımcısı (1024x1024 Vektörel 3D Çizim)
func createAppleCalculatorIconImage(size: CGFloat) -> NSImage {
    let img = NSImage(size: NSSize(width: size, height: size))
    img.lockFocus()

    guard let ctx = NSGraphicsContext.current?.cgContext else {
        img.unlockFocus()
        return img
    }

    let scale = size / 1024.0
    let colorSpace = CGColorSpaceCreateDeviceRGB()

    // 1. Dış Beyaz/Gümüş Apple Squircle Tabanı (3. Görseldeki Beyaz Kutu)
    let outerMargin: CGFloat = 100.0 * scale
    let outerSize = size - (outerMargin * 2)
    let outerRect = CGRect(x: outerMargin, y: outerMargin, width: outerSize, height: outerSize)
    let outerRadius: CGFloat = 185.0 * scale
    let outerPath = CGPath(roundedRect: outerRect, cornerWidth: outerRadius, cornerHeight: outerRadius, transform: nil)

    // Dış kutu yumuşak gölgesi ve 3D derinliği
    ctx.saveGState()
    ctx.setShadow(
        offset: CGSize(width: 0, height: -12.0 * scale),
        blur: 28.0 * scale,
        color: CGColor(red: 0, green: 0, blue: 0, alpha: 0.35)
    )
    ctx.setFillColor(CGColor(red: 0.96, green: 0.96, blue: 0.97, alpha: 1.0))
    ctx.addPath(outerPath)
    ctx.fillPath()
    ctx.restoreGState()

    // Dış kutu yüzey gradyanı (Üstten alta hafif 3D gümüş-beyaz geçiş)
    ctx.saveGState()
    ctx.addPath(outerPath)
    ctx.clip()
    let outerColors = [
        CGColor(red: 0.99, green: 0.99, blue: 1.00, alpha: 1.0),
        CGColor(red: 0.90, green: 0.91, blue: 0.92, alpha: 1.0)
    ] as CFArray
    let outerGrad = CGGradient(colorsSpace: colorSpace, colors: outerColors, locations: [0.0, 1.0])!
    ctx.drawLinearGradient(
        outerGrad,
        start: CGPoint(x: size / 2, y: outerRect.maxY),
        end: CGPoint(x: size / 2, y: outerRect.minY),
        options: []
    )
    ctx.restoreGState()

    // Dış kutu ince parlak iç kenar konturu
    ctx.saveGState()
    ctx.setStrokeColor(CGColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.85))
    ctx.setLineWidth(4.0 * scale)
    ctx.addPath(outerPath)
    ctx.strokePath()
    ctx.restoreGState()

    // 2. İçteki Koyu Gri/Siyah Hesap Makinesi Gövdesi (3. Görseldeki Ortadaki Cihaz)
    let bodyWidth: CGFloat = 460.0 * scale
    let bodyHeight: CGFloat = 580.0 * scale
    let bodyX = (size - bodyWidth) / 2.0
    let bodyY = (size - bodyHeight) / 2.0
    let bodyRect = CGRect(x: bodyX, y: bodyY, width: bodyWidth, height: bodyHeight)
    let bodyRadius: CGFloat = 86.0 * scale
    let bodyPath = CGPath(roundedRect: bodyRect, cornerWidth: bodyRadius, cornerHeight: bodyRadius, transform: nil)

    // Hesap makinesi gövdesinin beyaz zemin üzerindeki 3D gölgesi
    ctx.saveGState()
    ctx.setShadow(
        offset: CGSize(width: 0, height: -14.0 * scale),
        blur: 24.0 * scale,
        color: CGColor(red: 0, green: 0, blue: 0, alpha: 0.45)
    )
    ctx.setFillColor(CGColor(red: 0.16, green: 0.17, blue: 0.18, alpha: 1.0))
    ctx.addPath(bodyPath)
    ctx.fillPath()
    ctx.restoreGState()

    // Hesap makinesi gövde gradyanı (Koyu antrasit 3D görünüm)
    ctx.saveGState()
    ctx.addPath(bodyPath)
    ctx.clip()
    let bodyColors = [
        CGColor(red: 0.22, green: 0.23, blue: 0.24, alpha: 1.0),
        CGColor(red: 0.12, green: 0.12, blue: 0.13, alpha: 1.0)
    ] as CFArray
    let bodyGrad = CGGradient(colorsSpace: colorSpace, colors: bodyColors, locations: [0.0, 1.0])!
    ctx.drawLinearGradient(
        bodyGrad,
        start: CGPoint(x: size / 2, y: bodyRect.maxY),
        end: CGPoint(x: size / 2, y: bodyRect.minY),
        options: []
    )

    // 3. Üstteki Gri Ekran Bölümü (Yazısız, sade yuvarlatılmış ekran - 3. Görseldeki gibi)
    let screenMarginX: CGFloat = 48.0 * scale
    let screenTopMargin: CGFloat = 50.0 * scale
    let screenWidth = bodyWidth - (screenMarginX * 2.0)
    let screenHeight: CGFloat = 135.0 * scale
    let screenX = bodyX + screenMarginX
    let screenY = bodyRect.maxY - screenTopMargin - screenHeight
    let screenRect = CGRect(x: screenX, y: screenY, width: screenWidth, height: screenHeight)
    let screenRadius: CGFloat = 34.0 * scale
    let screenPath = CGPath(roundedRect: screenRect, cornerWidth: screenRadius, cornerHeight: screenRadius, transform: nil)

    let screenColors = [
        CGColor(red: 0.34, green: 0.35, blue: 0.36, alpha: 1.0),
        CGColor(red: 0.39, green: 0.40, blue: 0.41, alpha: 1.0)
    ] as CFArray
    let screenGrad = CGGradient(colorsSpace: colorSpace, colors: screenColors, locations: [0.0, 1.0])!
    ctx.saveGState()
    ctx.addPath(screenPath)
    ctx.clip()
    ctx.drawLinearGradient(
        screenGrad,
        start: CGPoint(x: size / 2, y: screenRect.maxY),
        end: CGPoint(x: size / 2, y: screenRect.minY),
        options: []
    )
    ctx.restoreGState()

    // 4. 3x3 Yuvarlatılmış Kare Tuş Takımı (Sol 2 Sütun Açık Gri, Sağ 1 Sütun Turuncu - Yazısız 3D Butonlar)
    let cols = 3
    let rows = 3
    let btnWidth: CGFloat = 104.0 * scale
    let btnHeight: CGFloat = 86.0 * scale
    let btnCorner: CGFloat = 24.0 * scale
    let spacingX = (screenWidth - (CGFloat(cols) * btnWidth)) / CGFloat(cols - 1)
    let spacingY: CGFloat = 22.0 * scale
    let gridBottomY = bodyY + 52.0 * scale

    for row in 0..<rows {
        for col in 0..<cols {
            let bx = screenX + CGFloat(col) * (btnWidth + spacingX)
            let by = gridBottomY + CGFloat(row) * (btnHeight + spacingY)
            let btnRect = CGRect(x: bx, y: by, width: btnWidth, height: btnHeight)
            let btnPath = CGPath(roundedRect: btnRect, cornerWidth: btnCorner, cornerHeight: btnCorner, transform: nil)

            // Buton alt gölgesi (3D kabartma hissi)
            ctx.saveGState()
            ctx.setShadow(
                offset: CGSize(width: 0, height: -5.0 * scale),
                blur: 6.0 * scale,
                color: CGColor(red: 0, green: 0, blue: 0, alpha: 0.55)
            )
            ctx.addPath(btnPath)
            ctx.setFillColor(CGColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1.0))
            ctx.fillPath()
            ctx.restoreGState()

            // Buton yüzey gradyanı
            ctx.saveGState()
            ctx.addPath(btnPath)
            ctx.clip()

            if col == 2 {
                // Sağ sütun: Canlı Apple Turuncusu
                let orangeColors = [
                    CGColor(red: 1.00, green: 0.65, blue: 0.05, alpha: 1.0),
                    CGColor(red: 0.96, green: 0.52, blue: 0.00, alpha: 1.0)
                ] as CFArray
                let orangeGrad = CGGradient(colorsSpace: colorSpace, colors: orangeColors, locations: [0.0, 1.0])!
                ctx.drawLinearGradient(
                    orangeGrad,
                    start: CGPoint(x: btnRect.midX, y: btnRect.maxY),
                    end: CGPoint(x: btnRect.midX, y: btnRect.minY),
                    options: []
                )
            } else {
                // Sol 2 sütun: Açık Gümüş/Gri
                let grayColors = [
                    CGColor(red: 0.85, green: 0.86, blue: 0.87, alpha: 1.0),
                    CGColor(red: 0.72, green: 0.73, blue: 0.74, alpha: 1.0)
                ] as CFArray
                let grayGrad = CGGradient(colorsSpace: colorSpace, colors: grayColors, locations: [0.0, 1.0])!
                ctx.drawLinearGradient(
                    grayGrad,
                    start: CGPoint(x: btnRect.midX, y: btnRect.maxY),
                    end: CGPoint(x: btnRect.midX, y: btnRect.minY),
                    options: []
                )
            }
            ctx.restoreGState()
        }
    }

    ctx.restoreGState() // bodyPath clip sonu

    // Hesap makinesi gövdesi ince üst parlaklık konturu
    ctx.saveGState()
    ctx.setStrokeColor(CGColor(red: 0.38, green: 0.39, blue: 0.40, alpha: 0.7))
    ctx.setLineWidth(3.0 * scale)
    ctx.addPath(bodyPath)
    ctx.strokePath()
    ctx.restoreGState()

    img.unlockFocus()
    return img
}

// MARK: - Mac Standartlarında .icns Dosyasını Üret
func generateICNS() {
    let fileManager = FileManager.default
    let iconsetName = "AppIcon.iconset"

    print("🎨 3. Görseldeki Orijinal macOS Hesap Makinesi Dock simgesi çiziliyor...")

    if fileManager.fileExists(atPath: iconsetName) {
        try? fileManager.removeItem(atPath: iconsetName)
    }
    try? fileManager.createDirectory(atPath: iconsetName, withIntermediateDirectories: true)

    let iconSizes: [(name: String, points: CGFloat, scale: CGFloat)] = [
        ("icon_16x16.png", 16, 1),
        ("icon_16x16@2x.png", 16, 2),
        ("icon_32x32.png", 32, 1),
        ("icon_32x32@2x.png", 32, 2),
        ("icon_128x128.png", 128, 1),
        ("icon_128x128@2x.png", 128, 2),
        ("icon_256x256.png", 256, 1),
        ("icon_256x256@2x.png", 256, 2),
        ("icon_512x512.png", 512, 1),
        ("icon_512x512@2x.png", 512, 2)
    ]

    for item in iconSizes {
        let pixelSize = item.points * item.scale
        let image = createAppleCalculatorIconImage(size: pixelSize)

        if let tiffData = image.tiffRepresentation,
           let bitmap = NSBitmapImageRep(data: tiffData),
           let pngData = bitmap.representation(using: .png, properties: [:]) {
            let filePath = "\(iconsetName)/\(item.name)"
            try? pngData.write(to: URL(fileURLWithPath: filePath))
        }
    }

    print("📦 .icns paketi derleniyor (iconutil)...")
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
    process.arguments = ["-c", "icns", iconsetName, "-o", "AppIcon.icns"]
    try? process.run()
    process.waitUntilExit()

    try? fileManager.removeItem(atPath: iconsetName)

    print("✨ Başarılı! Orijinal Dock İkonu (AppIcon.icns) hazırlandı.")
}

generateICNS()
