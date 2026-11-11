import SwiftUI
import AppKit

// MARK: - Hesap Makinesi Modları (⌘1 Temel, ⌘2 Bilimsel, ⌘3 Programcı)
enum CalcMode: Int {
    case basic = 1       // Temel (⌘1)
    case scientific = 2  // Bilimsel (⌘2)
    case programmer = 3  // Programcı (⌘3)

    func windowSize(convertMode: Bool, showBinary: Bool, rpnMode: Bool) -> NSSize {
        let extraConvertHeight: CGFloat = (convertMode && self != .programmer) ? 50 : 0
        let extraRPNHeight: CGFloat = rpnMode ? 58 : 0
        switch self {
        case .basic:
            return NSSize(width: 196, height: 324 + extraConvertHeight + extraRPNHeight)
        case .scientific:
            return NSSize(width: 492, height: 324 + extraConvertHeight + extraRPNHeight)
        case .programmer:
            return NSSize(width: 344, height: (showBinary ? 484 : 408) + extraRPNHeight)
        }
    }
}

// MARK: - Matematiksel İşlem Tipleri
enum Operation {
    case add       // Toplama (+) -> Kısayol: A
    case subtract  // Çıkarma (−) -> Kısayol: E
    case multiply  // Çarpma (×)  -> Kısayol: X
    case divide    // Bölme (÷)   -> Kısayol: B
    case power     // Üs Alma (xʸ)
    case yRoot     // Kök Alma (ʸ√x)
    case ee        // Bilimsel Üs (EE)
    case bitAnd    // Programcı AND
    case bitOr     // Programcı OR
    case bitXor    // Programcı XOR
    case bitNor    // Programcı NOR
    case shiftL    // Programcı <<
    case shiftR    // Programcı >>
    case shiftXY_L // Programcı X<<Y
    case shiftXY_R // Programcı X>>Y
    case modOp     // Programcı mod

    var symbol: String {
        switch self {
        case .add: return "+"
        case .subtract: return "−"
        case .multiply: return "×"
        case .divide: return "÷"
        case .power: return "^"
        case .yRoot: return "√"
        case .ee: return "E"
        case .bitAnd: return "AND"
        case .bitOr: return "OR"
        case .bitXor: return "XOR"
        case .bitNor: return "NOR"
        case .shiftL: return "<<"
        case .shiftR: return ">>"
        case .shiftXY_L: return "X<<Y"
        case .shiftXY_R: return "X>>Y"
        case .modOp: return "mod"
        }
    }
}

// MARK: - İşlem Geçmişi Kaydı
struct HistoryEntry: Identifiable {
    let id = UUID()
    let expression: String
    let result: String
}

// MARK: - Birim ve Para Birimi Dönüştürme Yapısı
struct UnitItem: Identifiable, Hashable {
    let id = UUID()
    let code: String
    let name: String
    let rateToBase: Double // 1 birim = kaç temel birim
}

// MARK: - Güvenli ve Tam Donanımlı Hesap Makinesi Motoru
class CalculatorModel: ObservableObject {
    static let shared = CalculatorModel()

    @Published var display: String = "0"
    @Published var expressionPreview: String = ""
    @Published var activeOperator: Operation? = nil
    @Published var mode: CalcMode = .basic
    @Published var showThousandsSeparator: Bool = false
    @Published var rpnMode: Bool = false
    @Published var convertMode: Bool = false
    @Published var decimalPlaces: Int = 8
    @Published var showHistory: Bool = false
    @Published var showMathNotes: Bool = false
    @Published var history: [HistoryEntry] = []
    @Published var mathNotesText: String = "125 + 75 =\n45 * 2 =\n"

    // Bilimsel Mod Durumları
    @Published var isSecondFunc: Bool = false
    @Published var useRadians: Bool = false
    private var memoryValue: Double = 0.0

    // Programcı Modu Durumları (2. Görsel ile Birebir Aynı!)
    @Published var programmerBase: Int = 16 // 8, 10 veya 16
    @Published var showBinaryGrid: Bool = true // "İkiliyi Gizle" / "İkiliyi Göster"
    @Published var showASCII: Bool = false
    @Published var showUnicode: Bool = false

    // RPN Yığını (Stack)
    @Published var rpnStack: [Double] = []

    // Dönüştürme (Convert) Birimleri (1. Görseldeki TRY / EUR Dahil!)
    let availableUnits: [UnitItem] = [
        UnitItem(code: "TRY", name: "Türk Lirası (TRY)", rateToBase: 1.0),
        UnitItem(code: "EUR", name: "Euro (EUR)", rateToBase: 55.942),
        UnitItem(code: "USD", name: "ABD Doları (USD)", rateToBase: 51.80),
        UnitItem(code: "GBP", name: "İngiliz Sterlini (GBP)", rateToBase: 66.40),
        UnitItem(code: "m",   name: "Metre (m)", rateToBase: 1.0),
        UnitItem(code: "km",  name: "Kilometre (km)", rateToBase: 1000.0),
        UnitItem(code: "cm",  name: "Santimetre (cm)", rateToBase: 0.01),
        UnitItem(code: "kg",  name: "Kilogram (kg)", rateToBase: 1.0),
        UnitItem(code: "g",   name: "Gram (g)", rateToBase: 0.001)
    ]
    @Published var fromUnitCode: String = "TRY"
    @Published var toUnitCode: String = "EUR"

    private var storedValue: Double? = nil
    private var pendingOperation: Operation? = nil
    @Published var isTyping: Bool = false

    // Pencere Boyutunu Güncelleme Kancası
    var onLayoutChange: (() -> Void)?

    func setMode(_ newMode: CalcMode) {
        mode = newMode
        if newMode == .programmer {
            convertMode = false
            if display == "0" {
                display = "0"
            }
        }
        onLayoutChange?()
    }

    func toggleConvert() {
        guard mode != .programmer else { return }
        convertMode.toggle()
        if convertMode {
            rpnMode = false
        }
        onLayoutChange?()
    }

    func toggleRPN() {
        rpnMode.toggle()
        if rpnMode {
            convertMode = false
        } else {
            expressionPreview = ""
        }
        onLayoutChange?()
    }

    func toggleBinaryGrid() {
        showBinaryGrid.toggle()
        onLayoutChange?()
    }

    func swapConvertUnits() {
        let temp = fromUnitCode
        fromUnitCode = toUnitCode
        toUnitCode = temp
    }

    // Programcı modundaki 64-bit tam sayı değeri
    var currentUInt64: UInt64 {
        let val = parseDisplay()
        if val < 0 {
            return UInt64(bitPattern: Int64(val))
        }
        if val >= Double(UInt64.max) {
            return UInt64.max
        }
        return UInt64(val)
    }

    func setFromUInt64(_ uval: UInt64) {
        display = "\(uval)"
        isTyping = true
    }

    // Birim Dönüştürme Sonucu (1. Görseldeki Alt Satır Değeri)
    var convertedResultDisplay: String {
        let val = parseDisplay()
        let fromRate = availableUnits.first(where: { $0.code == fromUnitCode })?.rateToBase ?? 1.0
        let toRate = availableUnits.first(where: { $0.code == toUnitCode })?.rateToBase ?? 1.0
        let converted = (val * fromRate) / toRate

        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 0
        formatter.decimalSeparator = ","
        formatter.groupingSeparator = showThousandsSeparator ? "." : ""
        return formatter.string(from: NSNumber(value: converted)) ?? "0"
    }

    // Ekranda gösterilecek formatlı metin
    var formattedDisplay: String {
        if display == "Hata" { return "Hata" }
        if mode == .programmer {
            let uval = currentUInt64
            if showASCII {
                let bytes = [
                    UInt8((uval >> 24) & 0xFF),
                    UInt8((uval >> 16) & 0xFF),
                    UInt8((uval >> 8) & 0xFF),
                    UInt8(uval & 0xFF)
                ]
                let chars = bytes.map { (b: UInt8) -> String in
                    (b >= 32 && b <= 126) ? String(UnicodeScalar(b)) : "·"
                }.joined()
                return chars
            }
            if showUnicode {
                if let scalar = UnicodeScalar(UInt32(uval & 0x10FFFF)) {
                    return String(Character(scalar))
                }
            }
            switch programmerBase {
            case 16: return String(uval, radix: 16).uppercased()
            case 8:  return String(uval, radix: 8)
            default: return "\(uval)"
            }
        }
        guard showThousandsSeparator else { return display }
        let parts = display.split(separator: ",", omittingEmptySubsequences: false)
        guard let firstPart = parts.first else { return display }
        let isNegative = firstPart.hasPrefix("-")
        let digitsOnly = isNegative ? String(firstPart.dropFirst()) : String(firstPart)
        guard let intVal = Int64(digitsOnly) else { return display }

        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = "."
        formatter.decimalSeparator = ","
        let formattedInt = formatter.string(from: NSNumber(value: intVal)) ?? digitsOnly
        let prefix = isNegative ? "-" : ""

        if parts.count > 1 {
            return "\(prefix)\(formattedInt),\(parts[1])"
        } else if display.hasSuffix(",") {
            return "\(prefix)\(formattedInt),"
        }
        return "\(prefix)\(formattedInt)"
    }

    // Sayı Girişi (0-9, 00, FF ve Programcı A-F)
    func inputDigit(_ digit: String) {
        if mode == .programmer {
            inputProgrammerToken(digit)
            return
        }
        if !isTyping || display == "Hata" {
            display = (digit == "00") ? "0" : digit
            isTyping = true
        } else {
            if display == "0" {
                display = (digit == "00") ? "0" : digit
            } else if display == "-0" {
                display = "-" + ((digit == "00") ? "0" : digit)
            } else if display.replacingOccurrences(of: ",", with: "").replacingOccurrences(of: "-", with: "").count < 10 {
                display += digit
            }
        }
    }

    // Programcı Modu Girişi (Taban 8, 10, 16 Desteği + A-F + FF + 00)
    func inputProgrammerToken(_ token: String) {
        let base = UInt64(programmerBase)
        var current = isTyping ? currentUInt64 : 0

        if token == "00" {
            current = current &* base &* base
            display = "\(current)"
            isTyping = true
            return
        } else if token == "FF" {
            guard programmerBase == 16 else { return }
            current = (current &* 256) &+ 0xFF
            display = "\(current)"
            isTyping = true
            return
        }

        guard let digitVal = UInt64(token, radix: programmerBase) else { return }
        let next = (current &* base) &+ digitVal
        display = "\(next)"
        isTyping = true
    }

    // 64-Bit İkili (Binary) Izgarada Tek Bir Bite Tıklayarak 0 <-> 1 Değiştirme
    func toggleBit(at bitIndex: Int) {
        let mask: UInt64 = 1 << UInt64(bitIndex)
        let toggled = currentUInt64 ^ mask
        setFromUInt64(toggled)
    }

    // Ondalık Virgül Girişi (,)
    func inputDecimal() {
        if mode == .programmer { return }
        if !isTyping || display == "Hata" {
            display = "0,"
            isTyping = true
        } else if !display.contains(",") {
            display += ","
        }
    }

    // RPN Enter (Yığına Ekle) ve RPN Yığın Manipülasyonları (x↔y, R↓, R↑, at)
    func rpnEnter() {
        let val = parseDisplay()
        rpnStack.append(val)
        isTyping = false
    }

    func rpnSwapXY() {
        guard let last = rpnStack.popLast() else { return }
        let current = parseDisplay()
        rpnStack.append(current)
        display = mode == .programmer ? "\(UInt64(max(0, last)))" : formatResult(last)
        isTyping = false
    }

    func rpnRollDown() {
        guard !rpnStack.isEmpty else { return }
        let current = parseDisplay()
        let bottom = rpnStack.removeFirst()
        rpnStack.append(current)
        display = mode == .programmer ? "\(UInt64(max(0, bottom)))" : formatResult(bottom)
        isTyping = false
    }

    func rpnRollUp() {
        guard !rpnStack.isEmpty else { return }
        let current = parseDisplay()
        let top = rpnStack.removeLast()
        rpnStack.insert(current, at: 0)
        display = mode == .programmer ? "\(UInt64(max(0, top)))" : formatResult(top)
        isTyping = false
    }

    func rpnDrop() {
        if let last = rpnStack.popLast() {
            display = mode == .programmer ? "\(UInt64(max(0, last)))" : formatResult(last)
        } else {
            display = "0"
        }
        isTyping = false
    }

    func formatStackValue(_ val: Double) -> String {
        if mode == .programmer {
            let uval = UInt64(max(0, val))
            switch programmerBase {
            case 16: return String(uval, radix: 16).uppercased()
            case 8:  return String(uval, radix: 8)
            default: return "\(uval)"
            }
        }
        return formatResult(val)
    }

    // İşlem Seçimi (+, −, ×, ÷ vb.)
    func selectOperation(_ op: Operation) {
        if display == "Hata" { clear() }
        let currentValue = parseDisplay()

        if rpnMode {
            if let last = rpnStack.popLast() {
                let res = performBinary(op: op, lhs: last, rhs: currentValue)
                display = formatResult(res)
                expressionPreview = "RPN: \(formatResult(last)) \(op.symbol) \(formatResult(currentValue))"
                isTyping = false
            } else {
                rpnStack.append(currentValue)
                isTyping = false
            }
            return
        }

        if isTyping && pendingOperation != nil && storedValue != nil {
            calculateIntermediate()
        } else {
            storedValue = currentValue
        }

        pendingOperation = op
        activeOperator = op
        expressionPreview = "\(formatResult(storedValue ?? currentValue)) \(op.symbol)"
        isTyping = false
    }

    private func performBinary(op: Operation, lhs: Double, rhs: Double) -> Double {
        let uLhs = UInt64(lhs >= 0 ? lhs : 0)
        let uRhs = UInt64(rhs >= 0 ? rhs : 0)
        switch op {
        case .add: return lhs + rhs
        case .subtract: return lhs - rhs
        case .multiply: return lhs * rhs
        case .divide: return rhs == 0 ? Double.nan : (mode == .programmer ? Double(uLhs / uRhs) : lhs / rhs)
        case .power: return pow(lhs, rhs)
        case .yRoot: return rhs == 0 ? Double.nan : pow(lhs, 1.0 / rhs)
        case .ee: return lhs * pow(10.0, rhs)
        case .bitAnd: return Double(uLhs & uRhs)
        case .bitOr:  return Double(uLhs | uRhs)
        case .bitXor: return Double(uLhs ^ uRhs)
        case .bitNor: return Double(~(uLhs | uRhs))
        case .shiftL: return Double(uLhs << 1)
        case .shiftR: return Double(uLhs >> 1)
        case .shiftXY_L: return Double(uLhs << (uRhs & 63))
        case .shiftXY_R: return Double(uLhs >> (uRhs & 63))
        case .modOp: return uRhs == 0 ? Double.nan : Double(uLhs % uRhs)
        }
    }

    // Eşittir (=)
    func calculateResult() {
        if rpnMode {
            rpnEnter()
            return
        }
        guard let op = pendingOperation, let stored = storedValue else { return }
        let current = parseDisplay()
        let result = performBinary(op: op, lhs: stored, rhs: current)

        if result.isNaN || result.isInfinite {
            display = "Hata"
            expressionPreview = ""
            storedValue = nil
            pendingOperation = nil
            activeOperator = nil
            isTyping = false
            return
        }

        let formattedRes = mode == .programmer ? "\(UInt64(max(0, result)))" : formatResult(result)
        let expr = "\(formatResult(stored)) \(op.symbol) \(formatResult(current))"
        history.insert(HistoryEntry(expression: expr, result: formattedRes), at: 0)
        expressionPreview = ""
        display = formattedRes
        storedValue = nil
        pendingOperation = nil
        activeOperator = nil
        isTyping = false
    }

    // Ara Sonuç Hesaplama
    private func calculateIntermediate() {
        guard let op = pendingOperation, let stored = storedValue else { return }
        let current = parseDisplay()
        let result = performBinary(op: op, lhs: stored, rhs: current)

        if result.isNaN || result.isInfinite {
            display = "Hata"
            storedValue = nil
            pendingOperation = nil
            activeOperator = nil
            isTyping = false
            return
        }

        storedValue = result
        display = mode == .programmer ? "\(UInt64(max(0, result)))" : formatResult(result)
    }

    // Bilimsel ve Programcı Tekil Fonksiyonlar
    func applyUnary(_ funcName: String) {
        if display == "Hata" { clear() }
        let x = parseDisplay()
        let uval = currentUInt64
        let angle = useRadians ? x : (x * .pi / 180.0)
        var res: Double = x

        switch funcName {
        case "x²": res = x * x
        case "x³": res = x * x * x
        case "√x": res = x < 0 ? .nan : sqrt(x)
        case "∛x": res = cbrt(x)
        case "1/x": res = x == 0 ? .nan : 1.0 / x
        case "ln": res = x <= 0 ? .nan : log(x)
        case "log₁₀": res = x <= 0 ? .nan : log10(x)
        case "eˣ": res = exp(x)
        case "10ˣ": res = pow(10.0, x)
        case "sin": res = isSecondFunc ? (useRadians ? asin(x) : asin(x) * 180.0 / .pi) : sin(angle)
        case "cos": res = isSecondFunc ? (useRadians ? acos(x) : acos(x) * 180.0 / .pi) : cos(angle)
        case "tan": res = isSecondFunc ? (useRadians ? atan(x) : atan(x) * 180.0 / .pi) : tan(angle)
        case "sinh": res = isSecondFunc ? asinh(x) : sinh(x)
        case "cosh": res = isSecondFunc ? acosh(x) : cosh(x)
        case "tanh": res = isSecondFunc ? atanh(x) : tanh(x)
        case "x!":
            if x < 0 || x > 170 || x != floor(x) {
                res = .nan
            } else {
                var fact = 1.0
                if Int(x) >= 1 {
                    for i in 1...Int(x) { fact *= Double(i) }
                }
                res = fact
            }
        case "π": res = Double.pi
        case "e": res = M_E
        case "Rand": res = Double.random(in: 0.0...1.0)
        // Programcı Özel Tekil İşlemleri (2. Görseldeki Tuşlar)
        case "NOT":
            setFromUInt64(~uval); isTyping = false; return
        case "<<":
            setFromUInt64(uval << 1); isTyping = false; return
        case ">>":
            setFromUInt64(uval >> 1); isTyping = false; return
        case "NEG":
            let neg = UInt64(bitPattern: -Int64(bitPattern: uval))
            setFromUInt64(neg); isTyping = false; return
        case "RoL":
            setFromUInt64((uval << 1) | (uval >> 63)); isTyping = false; return
        case "RoR":
            setFromUInt64((uval >> 1) | (uval << 63)); isTyping = false; return
        case "flip8":
            let low8 = uval & 0xFF
            var rev: UInt64 = 0
            for i in 0..<8 {
                if (low8 & (1 << i)) != 0 { rev |= (1 << (7 - i)) }
            }
            setFromUInt64((uval & ~0xFF) | rev); isTyping = false; return
        case "flip16":
            let low16 = ((uval & 0xFF) << 8) | ((uval >> 8) & 0xFF)
            setFromUInt64((uval & ~0xFFFF) | low16); isTyping = false; return
        default: break
        }

        display = formatResult(res)
        isTyping = false
    }

    // Hafıza İşlemleri (mc, m+, m-, mr)
    func memoryAction(_ cmd: String) {
        let current = parseDisplay()
        switch cmd {
        case "mc": memoryValue = 0.0
        case "m+": memoryValue += current; isTyping = false
        case "m-": memoryValue -= current; isTyping = false
        case "mr": display = formatResult(memoryValue); isTyping = false
        default: break
        }
    }

    // İşaret Değiştirme (+/−)
    func toggleSign() {
        if display == "0" || display == "Hata" { return }
        if display.hasPrefix("-") {
            display.removeFirst()
        } else {
            display = "-" + display
        }
    }

    // Yüzde Alma (%)
    func applyPercent() {
        if display == "Hata" { return }
        let current = parseDisplay()
        let result = current / 100.0
        display = formatResult(result)
        isTyping = false
    }

    // Sol Üst / Sağ Üst Silme Butonu Aksiyonu (⌫ veya AC)
    func topLeftButtonAction() {
        if isTyping && display != "0" && display != "Hata" {
            backspace()
        } else {
            allClear()
        }
    }

    // Tamamen Temizle (AC)
    func allClear() {
        display = "0"
        expressionPreview = ""
        storedValue = nil
        pendingOperation = nil
        activeOperator = nil
        isTyping = false
        rpnStack.removeAll()
    }

    // Temizleme (C / ESC)
    func clear() {
        if isTyping && display != "0" && display != "Hata" {
            display = "0"
            isTyping = false
        } else {
            allClear()
        }
    }

    // Geri Silme (Backspace / Delete -> ⌫)
    func backspace() {
        guard isTyping && display != "0" && display != "Hata" else { return }
        if mode == .programmer {
            let base = UInt64(programmerBase)
            let next = currentUInt64 / base
            display = "\(next)"
            if next == 0 { isTyping = false }
            return
        }
        if display.count > 1 {
            display.removeLast()
            if display == "-" || display == "-0" {
                display = "0"
                isTyping = false
            }
        } else {
            display = "0"
            isTyping = false
        }
    }

    // Matematik Notları Değerlendiricisi (⌥⌘M)
    func evaluateMathNotes() {
        let lines = mathNotesText.components(separatedBy: "\n")
        var updatedLines: [String] = []
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasSuffix("=") {
                let exprPart = String(trimmed.dropLast()).trimmingCharacters(in: .whitespaces)
                    .replacingOccurrences(of: ",", with: ".")
                    .replacingOccurrences(of: "×", with: "*")
                    .replacingOccurrences(of: "÷", with: "/")
                let nsExpr = NSExpression(format: exprPart)
                if let val = nsExpr.expressionValue(with: nil, context: nil) as? NSNumber {
                    updatedLines.append("\(trimmed) \(formatResult(val.doubleValue))")
                    continue
                }
            }
            updatedLines.append(line)
        }
        mathNotesText = updatedLines.joined(separator: "\n")
    }

    // Sonucu Panoya Kopyala (⌘ + C)
    func copyToClipboard() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(formattedDisplay, forType: .string)
    }

    // Panodan Sayı Yapıştır (⌘ + V)
    func pasteFromClipboard() {
        guard let pasted = NSPasteboard.general.string(forType: .string) else { return }
        let trimmed = pasted.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: ".", with: ",")
        if let val = Double(trimmed.replacingOccurrences(of: ",", with: ".")), !val.isNaN, !val.isInfinite {
            display = formatResult(val)
            isTyping = true
        }
    }

    // Ekrandaki virgüllü metni güvenli sayıya çevir
    func parseDisplay() -> Double {
        let clean = display.replacingOccurrences(of: ",", with: ".")
        return Double(clean) ?? 0.0
    }

    // Sayıyı Apple biçiminde temiz ve seçilen ondalık basamağa göre formatla
    func formatResult(_ value: Double) -> String {
        if value.isNaN || value.isInfinite { return "Hata" }
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = decimalPlaces
        formatter.decimalSeparator = ","
        formatter.groupingSeparator = ""
        return formatter.string(from: NSNumber(value: value)) ?? "Hata"
    }

    // Klavye Olayı İşleyici (A, E, X, B Özel Kısayolları + Mac Sistem Kısayolları)
    func handleKeyPress(_ event: NSEvent) -> NSEvent? {
        if event.modifierFlags.contains(.command) || event.modifierFlags.contains(.control) {
            return event
        }
        if showMathNotes {
            return event
        }
        if event.keyCode == 51 {
            backspace()
            return nil
        } else if event.keyCode == 53 {
            clear()
            return nil
        }

        guard let characters = event.characters else { return event }

        for char in characters {
            switch char {
            // --- KULLANICI ÖZEL KISAYOLLARI (A: +, E: −, X: ×, B: ÷) ---
            case "a", "A", "t", "T":
                selectOperation(.add)
                return nil
            case "e", "E", "ç", "Ç":
                selectOperation(.subtract)
                return nil
            case "x", "X":
                selectOperation(.multiply)
                return nil
            case "b", "B":
                selectOperation(.divide)
                return nil

            // Standart İşlem Tuşları
            case "+":
                selectOperation(.add)
                return nil
            case "-":
                selectOperation(.subtract)
                return nil
            case "*":
                selectOperation(.multiply)
                return nil
            case "/":
                selectOperation(.divide)
                return nil

            // Rakamlar
            case "0"..."9":
                inputDigit(String(char))
                return nil

            // Virgül ve Nokta
            case ",", ".":
                inputDecimal()
                return nil

            // Eşittir & Enter
            case "=", "\r", "\n":
                calculateResult()
                return nil

            // Yüzde
            case "%":
                applyPercent()
                return nil

            // Temizleme (C)
            case "c", "C":
                clear()
                return nil

            default:
                break
            }
        }
        return nil
    }
}

// MARK: - SwiftUI Ana Görünümü (1. Görseldeki Dönüştür ve 2. Görseldeki Programcı Modu ile Birebir!)
struct ContentView: View {
    @ObservedObject private var model = CalculatorModel.shared

    let btnSize: CGFloat = 40
    let buttonSpacing: CGFloat = 6

    // Orijinal macOS Hesap Makinesi Renk Paleti
    let windowBg = Color(red: 0.14, green: 0.14, blue: 0.14)
    let numberBtnColor = Color(red: 0.27, green: 0.27, blue: 0.28)
    let sciBtnColor = Color(red: 0.21, green: 0.21, blue: 0.22)
    let functionBtnColor = Color(red: 0.38, green: 0.38, blue: 0.39)
    let orangeColor = Color(red: 1.0, green: 0.62, blue: 0.04)

    var currentWindowSize: NSSize {
        model.mode.windowSize(convertMode: model.convertMode, showBinary: model.showBinaryGrid, rpnMode: model.rpnMode)
    }

    var body: some View {
        ZStack {
            if model.mode == .programmer {
                // Programcı Modu (Normal veya 3. Görseldeki RPN Programcı Düzeni)
                programmerFullView
            } else {
                // Temel (⌘1) ve Bilimsel (⌘2) + Dönüştür (⌥⌘C) + RPN (⌘R) Düzeni
                VStack(spacing: 0) {
                    // Üst Ekran: RPN Açıksa Tam Genişlikte RPN Yığın Ekranı (1. Görsel ile Birebir: 3 Çizgili!)
                    if model.rpnMode {
                        rpnFullWidthHeader(showBaseSubscript: false, dropButtonTitle: "at")
                            .frame(height: 148)
                    } else if model.convertMode {
                        // 2. ve 3. Görseldeki gibi Dönüştür çizgisi tüm pencere genişliğince uzanır!
                        convertHeaderView
                            .frame(height: 140)
                    } else {
                        HStack(spacing: 0) {
                            Spacer()
                            standardHeaderView
                                .frame(width: 196, height: 90, alignment: .bottomTrailing)
                        }
                    }

                    // Alt Tuş Takımı (Sol: Bilimsel, Sağ: Temel)
                    HStack(spacing: 0) {
                        if model.mode == .scientific {
                            scientificKeypad
                                .padding(.leading, 9)
                                .padding(.bottom, 10)
                        }

                        basicKeypad
                            .padding(.horizontal, 9)
                            .padding(.bottom, 10)
                            .frame(width: 196)
                    }
                }
            }

            if model.showHistory {
                historyOverlay
            }
            if model.showMathNotes {
                mathNotesOverlay
            }
        }
        .frame(width: currentWindowSize.width, height: currentWindowSize.height)
        .fixedSize()
        .background(windowBg)
    }

    // MARK: - 1. ve 4. Görseldeki Orijinal RPN Yığın Ekranı (Tam 3 Yatay Çizgi + Sağda x↔y, R↓, R↑, at/drop Hap Butonları)
    private func rpnFullWidthHeader(showBaseSubscript: Bool, dropButtonTitle: String) -> some View {
        let count = model.rpnStack.count
        let tText = count >= 3 ? model.formatStackValue(model.rpnStack[count - 3]) : ""
        let zText = count >= 2 ? model.formatStackValue(model.rpnStack[count - 2]) : ""
        let yText = count >= 1 ? model.formatStackValue(model.rpnStack[count - 1]) : ""

        return VStack(spacing: 0) {
            Spacer(minLength: 22)
            HStack(alignment: .bottom, spacing: 8) {
                // Sol: 4 Seviye (T, Z, Y ve Aktif X Satırı) ve Aralarında TAM 3 YATAY ÇİZGİ (Orijinal ile Birebir!)
                VStack(alignment: .trailing, spacing: 3) {
                    // 4. Seviye (T) -> 1. Çizginin Üstü
                    HStack {
                        Spacer()
                        Text(tText)
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(Color.white.opacity(0.65))
                            .lineLimit(1)
                    }
                    .frame(height: 18)
                    Rectangle().fill(Color.white.opacity(0.14)).frame(height: 1) // 1. ÇİZGİ

                    // 3. Seviye (Z) -> 2. Çizginin Üstü
                    HStack {
                        Spacer()
                        Text(zText)
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(Color.white.opacity(0.65))
                            .lineLimit(1)
                    }
                    .frame(height: 18)
                    Rectangle().fill(Color.white.opacity(0.14)).frame(height: 1) // 2. ÇİZGİ

                    // 2. Seviye (Y) -> 3. Çizginin Üstü
                    HStack {
                        Spacer()
                        Text(yText)
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(Color.white.opacity(0.65))
                            .lineLimit(1)
                    }
                    .frame(height: 18)
                    Rectangle().fill(Color.white.opacity(0.14)).frame(height: 1) // 3. ÇİZGİ

                    // 1. Seviye (Aktif X Satırı) -> 3. Çizginin Altı
                    HStack(alignment: .lastTextBaseline, spacing: 2) {
                        Spacer()
                        Text(model.formattedDisplay)
                            .font(.system(size: 25, weight: .regular))
                            .foregroundColor(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.35)
                        if showBaseSubscript {
                            Text("\(model.programmerBase)")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(Color.white.opacity(0.8))
                        }
                    }
                    .frame(height: 28)
                }

                // Sağ: 4 Adet RPN Yığın Manipülasyon Hap Butonu (x↔y, R↓, R↑, at/drop)
                VStack(spacing: 5) {
                    rpnPillButton(title: "x↔y") { model.rpnSwapXY() }
                    rpnPillButton(title: "R↓")  { model.rpnRollDown() }
                    rpnPillButton(title: "R↑")  { model.rpnRollUp() }
                    rpnPillButton(title: dropButtonTitle)  { model.rpnDrop() }
                }
                .padding(.bottom, 2)
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 6)
        }
    }

    private func rpnPillButton(title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white)
                .frame(width: 40, height: 22)
                .background(functionBtnColor)
                .clipShape(Capsule())
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Standart Sayı Ekranı
    private var standardHeaderView: some View {
        VStack(alignment: .trailing, spacing: 2) {
            Spacer()
            if !model.expressionPreview.isEmpty {
                Text(model.expressionPreview)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(Color.white.opacity(0.55))
                    .lineLimit(1)
                    .padding(.horizontal, 12)
            }
            HStack {
                Spacer()
                Text(model.formattedDisplay)
                    .font(.system(size: 30, weight: .regular, design: .default))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.35)
                    .padding(.horizontal, 12)
                    .padding(.bottom, 6)
            }
        }
    }

    // MARK: - 1. Görseldeki Orijinal "Dönüştür" (Convert) Çift Satırlı Ekranı (TRY ⇅ EUR)
    private var convertHeaderView: some View {
        VStack(alignment: .trailing, spacing: 2) {
            Spacer(minLength: 24)

            // Üst Satır: Girilen Değer + Birim Seçici (Örn: TRY ⌄)
            Text(model.formattedDisplay)
                .font(.system(size: 24, weight: .regular))
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.4)
                .padding(.horizontal, 12)

            unitMenuButton(selectedCode: $model.fromUnitCode)
                .padding(.horizontal, 12)

            // Orta Satır: Sol tarafta turuncu ⇅ değiştirme butonu + İnce ayırıcı çizgi
            HStack(spacing: 6) {
                Button(action: { model.swapConvertUnits() }) {
                    Text("↑↓")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(orangeColor)
                }
                .buttonStyle(PlainButtonStyle())

                Rectangle()
                    .fill(Color.white.opacity(0.15))
                    .frame(height: 1)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 2)

            // Alt Satır: Dönüştürülen Değer + Hedef Birim Seçici (Örn: EUR ⌄)
            Text(model.convertedResultDisplay)
                .font(.system(size: 24, weight: .regular))
                .foregroundColor(Color.white.opacity(0.65))
                .lineLimit(1)
                .minimumScaleFactor(0.4)
                .padding(.horizontal, 12)

            unitMenuButton(selectedCode: $model.toUnitCode)
                .padding(.horizontal, 12)
                .padding(.bottom, 4)
        }
    }

    private func unitMenuButton(selectedCode: Binding<String>) -> some View {
        Menu {
            ForEach(model.availableUnits) { unit in
                Button(unit.name) {
                    selectedCode.wrappedValue = unit.code
                }
            }
        } label: {
            HStack(spacing: 3) {
                Text(selectedCode.wrappedValue)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(Color.white.opacity(0.65))
                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 8, weight: .semibold))
                    .foregroundColor(Color.white.opacity(0.5))
            }
        }
        .menuStyle(BorderlessButtonMenuStyle())
        .fixedSize()
    }

    // MARK: - 4x5 Yuvarlak Temel Tuş Takımı
    private var basicKeypad: some View {
        VStack(spacing: buttonSpacing) {
            // 1. Satır: ⌫/AC, ⁺∕₋, %, ÷
            HStack(spacing: buttonSpacing) {
                Button(action: { model.topLeftButtonAction() }) {
                    Group {
                        if model.isTyping && model.display != "0" && model.display != "Hata" {
                            Image(systemName: "delete.left")
                                .font(.system(size: 16, weight: .medium))
                        } else {
                            Text("AC")
                                .font(.system(size: 15, weight: .regular))
                        }
                    }
                    .foregroundColor(.white)
                    .frame(width: btnSize, height: btnSize)
                    .background(functionBtnColor)
                    .clipShape(Circle())
                }
                .buttonStyle(PlainButtonStyle())

                RoundCalcButton(title: "⁺∕₋", size: btnSize, bg: functionBtnColor, fg: .white, fontSize: 16) {
                    model.toggleSign()
                }
                RoundCalcButton(title: "%", size: btnSize, bg: functionBtnColor, fg: .white, fontSize: 16) {
                    model.applyPercent()
                }
                RoundCalcButton(
                    title: "÷",
                    size: btnSize,
                    bg: model.activeOperator == .divide ? .white : orangeColor,
                    fg: model.activeOperator == .divide ? orangeColor : .white,
                    fontSize: 19
                ) { model.selectOperation(.divide) }
            }

            // 2. Satır: 7, 8, 9, ×
            HStack(spacing: buttonSpacing) {
                RoundCalcButton(title: "7", size: btnSize, bg: numberBtnColor, fg: .white, fontSize: 17) { model.inputDigit("7") }
                RoundCalcButton(title: "8", size: btnSize, bg: numberBtnColor, fg: .white, fontSize: 17) { model.inputDigit("8") }
                RoundCalcButton(title: "9", size: btnSize, bg: numberBtnColor, fg: .white, fontSize: 17) { model.inputDigit("9") }
                RoundCalcButton(
                    title: "×",
                    size: btnSize,
                    bg: model.activeOperator == .multiply ? .white : orangeColor,
                    fg: model.activeOperator == .multiply ? orangeColor : .white,
                    fontSize: 19
                ) { model.selectOperation(.multiply) }
            }

            // 3. Satır: 4, 5, 6, −
            HStack(spacing: buttonSpacing) {
                RoundCalcButton(title: "4", size: btnSize, bg: numberBtnColor, fg: .white, fontSize: 17) { model.inputDigit("4") }
                RoundCalcButton(title: "5", size: btnSize, bg: numberBtnColor, fg: .white, fontSize: 17) { model.inputDigit("5") }
                RoundCalcButton(title: "6", size: btnSize, bg: numberBtnColor, fg: .white, fontSize: 17) { model.inputDigit("6") }
                RoundCalcButton(
                    title: "−",
                    size: btnSize,
                    bg: model.activeOperator == .subtract ? .white : orangeColor,
                    fg: model.activeOperator == .subtract ? orangeColor : .white,
                    fontSize: 19
                ) { model.selectOperation(.subtract) }
            }

            // 4. Satır: 1, 2, 3, +
            HStack(spacing: buttonSpacing) {
                RoundCalcButton(title: "1", size: btnSize, bg: numberBtnColor, fg: .white, fontSize: 17) { model.inputDigit("1") }
                RoundCalcButton(title: "2", size: btnSize, bg: numberBtnColor, fg: .white, fontSize: 17) { model.inputDigit("2") }
                RoundCalcButton(title: "3", size: btnSize, bg: numberBtnColor, fg: .white, fontSize: 17) { model.inputDigit("3") }
                RoundCalcButton(
                    title: "+",
                    size: btnSize,
                    bg: model.activeOperator == .add ? .white : orangeColor,
                    fg: model.activeOperator == .add ? orangeColor : .white,
                    fontSize: 19
                ) { model.selectOperation(.add) }
            }

            // 5. Satır: Geniş 0 (Ortalanmış), ,, = (veya RPN modunda enter)
            HStack(spacing: buttonSpacing) {
                Button(action: { model.inputDigit("0") }) {
                    Text("0")
                        .font(.system(size: 17, weight: .regular))
                        .foregroundColor(.white)
                        .frame(width: (btnSize * 2) + buttonSpacing, height: btnSize)
                        .background(numberBtnColor)
                        .clipShape(Capsule())
                }
                .buttonStyle(PlainButtonStyle())

                RoundCalcButton(title: ",", size: btnSize, bg: numberBtnColor, fg: .white, fontSize: 17) { model.inputDecimal() }
                RoundCalcButton(title: model.rpnMode ? "enter" : "=", size: btnSize, bg: orangeColor, fg: .white, fontSize: model.rpnMode ? 11 : 19) {
                    model.calculateResult()
                }
            }
        }
    }

    // MARK: - 2. Görseldeki Orijinal Programcı Modu Görünümü (Birebir Aynı!)
    private var programmerFullView: some View {
        let hexActive = (model.programmerBase == 16)
        let decActive = (model.programmerBase >= 10)

        return VStack(spacing: 0) {
            if model.rpnMode {
                // 4. Görseldeki Programcı + RPN Yığın Ekranı (3 Çizgili ve sağ altta "drop")
                rpnFullWidthHeader(showBaseSubscript: true, dropButtonTitle: "drop")
                    .frame(height: 144)
            } else {
                Spacer(minLength: 28)

                // 1) Üst Büyük Sayı Ekranı + Alt İndis Taban Gösterimi (Örn: 84746B8E₁₆)
                HStack(alignment: .lastTextBaseline, spacing: 2) {
                    Spacer()
                    Text(model.formattedDisplay)
                        .font(.system(size: 32, weight: .regular))
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.35)
                    Text("\(model.programmerBase)")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color.white.opacity(0.75))
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 6)
            }

            Rectangle()
                .fill(Color.white.opacity(0.12))
                .frame(height: 1)

            // 2) Orta Kontrol Çubuğu: [ASCII | Unicode]  [İkiliyi Gizle]  [8 | 10 | 16]
            HStack {
                // Sol: ASCII | Unicode
                HStack(spacing: 0) {
                    pillToggleBtn(title: "ASCII", isSelected: model.showASCII) {
                        model.showASCII.toggle()
                        if model.showASCII { model.showUnicode = false }
                    }
                    Rectangle().fill(Color.white.opacity(0.2)).frame(width: 1, height: 14)
                    pillToggleBtn(title: "Unicode", isSelected: model.showUnicode) {
                        model.showUnicode.toggle()
                        if model.showUnicode { model.showASCII = false }
                    }
                }
                .background(Color.white.opacity(0.08))
                .cornerRadius(5)

                Spacer()

                // Orta: İkiliyi Gizle / İkiliyi Göster
                Button(action: { model.toggleBinaryGrid() }) {
                    Text(model.showBinaryGrid ? "İkiliyi Gizle" : "İkiliyi Göster")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 3)
                        .background(Color.white.opacity(model.showBinaryGrid ? 0.28 : 0.10))
                        .cornerRadius(5)
                }
                .buttonStyle(PlainButtonStyle())

                Spacer()

                // Sağ: 8 | 10 | 16 Seçici
                HStack(spacing: 0) {
                    baseSegmentBtn(title: "8", base: 8)
                    baseSegmentBtn(title: "10", base: 10)
                    baseSegmentBtn(title: "16", base: 16)
                }
                .background(Color.white.opacity(0.08))
                .cornerRadius(5)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)

            // 3) 64-Bit İkili (Binary) Görünümü (2 Satır x 8 Grup x 4 Bit + Bit İndisleri: 63, 47, 32 ve 31, 15, 0)
            if model.showBinaryGrid {
                binary64BitGrid
                    .padding(.horizontal, 12)
                    .padding(.bottom, 8)
            }

            // 4) 7 Sütun x 6 Satır Bitişik Yuvarlak Programcı Tuş Takımı (4. Görseldeki Orijinal Açıklık ile Birebir!)
            VStack(spacing: buttonSpacing) {
                // Satır 1: (, ), XOR, D, E, F, ⌫/AC
                HStack(spacing: buttonSpacing) {
                    RoundCalcButton(title: "(", size: btnSize, bg: sciBtnColor, fg: .white, fontSize: 15) {}
                    RoundCalcButton(title: ")", size: btnSize, bg: sciBtnColor, fg: .white, fontSize: 15) {}
                    RoundCalcButton(title: "XOR", size: btnSize, bg: sciBtnColor, fg: .white, fontSize: 12) { model.selectOperation(.bitXor) }
                    RoundCalcButton(title: "D", size: btnSize, bg: numberBtnColor.opacity(hexActive ? 1.0 : 0.4), fg: .white.opacity(hexActive ? 1.0 : 0.35), fontSize: 16) { model.inputProgrammerToken("D") }
                    RoundCalcButton(title: "E", size: btnSize, bg: numberBtnColor.opacity(hexActive ? 1.0 : 0.4), fg: .white.opacity(hexActive ? 1.0 : 0.35), fontSize: 16) { model.inputProgrammerToken("E") }
                    RoundCalcButton(title: "F", size: btnSize, bg: numberBtnColor.opacity(hexActive ? 1.0 : 0.4), fg: .white.opacity(hexActive ? 1.0 : 0.35), fontSize: 16) { model.inputProgrammerToken("F") }
                    Button(action: { model.topLeftButtonAction() }) {
                        Group {
                            if model.isTyping && model.display != "0" {
                                Image(systemName: "delete.left")
                                    .font(.system(size: 15, weight: .medium))
                            } else {
                                Text("AC")
                                    .font(.system(size: 14, weight: .regular))
                            }
                        }
                        .foregroundColor(.white)
                        .frame(width: btnSize, height: btnSize)
                        .background(functionBtnColor)
                        .clipShape(Circle())
                    }
                    .buttonStyle(PlainButtonStyle())
                }

                // Satır 2: AND, OR, NOR, A, B, C, ÷
                HStack(spacing: buttonSpacing) {
                    RoundCalcButton(title: "AND", size: btnSize, bg: sciBtnColor, fg: .white, fontSize: 12) { model.selectOperation(.bitAnd) }
                    RoundCalcButton(title: "OR", size: btnSize, bg: sciBtnColor, fg: .white, fontSize: 12) { model.selectOperation(.bitOr) }
                    RoundCalcButton(title: "NOR", size: btnSize, bg: sciBtnColor, fg: .white, fontSize: 12) { model.selectOperation(.bitNor) }
                    RoundCalcButton(title: "A", size: btnSize, bg: numberBtnColor.opacity(hexActive ? 1.0 : 0.4), fg: .white.opacity(hexActive ? 1.0 : 0.35), fontSize: 16) { model.inputProgrammerToken("A") }
                    RoundCalcButton(title: "B", size: btnSize, bg: numberBtnColor.opacity(hexActive ? 1.0 : 0.4), fg: .white.opacity(hexActive ? 1.0 : 0.35), fontSize: 16) { model.inputProgrammerToken("B") }
                    RoundCalcButton(title: "C", size: btnSize, bg: numberBtnColor.opacity(hexActive ? 1.0 : 0.4), fg: .white.opacity(hexActive ? 1.0 : 0.35), fontSize: 16) { model.inputProgrammerToken("C") }
                    RoundCalcButton(title: "÷", size: btnSize, bg: model.activeOperator == .divide ? .white : orangeColor, fg: model.activeOperator == .divide ? orangeColor : .white, fontSize: 19) { model.selectOperation(.divide) }
                }

                // Satır 3: NOT, <<, >>, 7, 8, 9, ×
                HStack(spacing: buttonSpacing) {
                    RoundCalcButton(title: "NOT", size: btnSize, bg: sciBtnColor, fg: .white, fontSize: 12) { model.applyUnary("NOT") }
                    RoundCalcButton(title: "<<", size: btnSize, bg: sciBtnColor, fg: .white, fontSize: 14) { model.applyUnary("<<") }
                    RoundCalcButton(title: ">>", size: btnSize, bg: sciBtnColor, fg: .white, fontSize: 14) { model.applyUnary(">>") }
                    RoundCalcButton(title: "7", size: btnSize, bg: numberBtnColor, fg: .white, fontSize: 17) { model.inputProgrammerToken("7") }
                    RoundCalcButton(title: "8", size: btnSize, bg: numberBtnColor.opacity(decActive ? 1.0 : 0.4), fg: .white.opacity(decActive ? 1.0 : 0.35), fontSize: 17) { model.inputProgrammerToken("8") }
                    RoundCalcButton(title: "9", size: btnSize, bg: numberBtnColor.opacity(decActive ? 1.0 : 0.4), fg: .white.opacity(decActive ? 1.0 : 0.35), fontSize: 17) { model.inputProgrammerToken("9") }
                    RoundCalcButton(title: "×", size: btnSize, bg: model.activeOperator == .multiply ? .white : orangeColor, fg: model.activeOperator == .multiply ? orangeColor : .white, fontSize: 19) { model.selectOperation(.multiply) }
                }

                // Satır 4: NEG, X<<Y, X>>Y, 4, 5, 6, −
                HStack(spacing: buttonSpacing) {
                    RoundCalcButton(title: "NEG", size: btnSize, bg: sciBtnColor, fg: .white, fontSize: 12) { model.applyUnary("NEG") }
                    RoundCalcButton(title: "X<<Y", size: btnSize, bg: sciBtnColor, fg: .white, fontSize: 11) { model.selectOperation(.shiftXY_L) }
                    RoundCalcButton(title: "X>>Y", size: btnSize, bg: sciBtnColor, fg: .white, fontSize: 11) { model.selectOperation(.shiftXY_R) }
                    RoundCalcButton(title: "4", size: btnSize, bg: numberBtnColor, fg: .white, fontSize: 17) { model.inputProgrammerToken("4") }
                    RoundCalcButton(title: "5", size: btnSize, bg: numberBtnColor, fg: .white, fontSize: 17) { model.inputProgrammerToken("5") }
                    RoundCalcButton(title: "6", size: btnSize, bg: numberBtnColor, fg: .white, fontSize: 17) { model.inputProgrammerToken("6") }
                    RoundCalcButton(title: "−", size: btnSize, bg: model.activeOperator == .subtract ? .white : orangeColor, fg: model.activeOperator == .subtract ? orangeColor : .white, fontSize: 19) { model.selectOperation(.subtract) }
                }

                // Satır 5: mod, RoL, RoR, 1, 2, 3, +
                HStack(spacing: buttonSpacing) {
                    RoundCalcButton(title: "mod", size: btnSize, bg: sciBtnColor, fg: .white, fontSize: 12) { model.selectOperation(.modOp) }
                    RoundCalcButton(title: "RoL", size: btnSize, bg: sciBtnColor, fg: .white, fontSize: 12) { model.applyUnary("RoL") }
                    RoundCalcButton(title: "RoR", size: btnSize, bg: sciBtnColor, fg: .white, fontSize: 12) { model.applyUnary("RoR") }
                    RoundCalcButton(title: "1", size: btnSize, bg: numberBtnColor, fg: .white, fontSize: 17) { model.inputProgrammerToken("1") }
                    RoundCalcButton(title: "2", size: btnSize, bg: numberBtnColor, fg: .white, fontSize: 17) { model.inputProgrammerToken("2") }
                    RoundCalcButton(title: "3", size: btnSize, bg: numberBtnColor, fg: .white, fontSize: 17) { model.inputProgrammerToken("3") }
                    RoundCalcButton(title: "+", size: btnSize, bg: model.activeOperator == .add ? .white : orangeColor, fg: model.activeOperator == .add ? orangeColor : .white, fontSize: 19) { model.selectOperation(.add) }
                }

                // Satır 6: [Boş], flip₈, flip₁₆, FF, 0, 00, = / enter
                HStack(spacing: buttonSpacing) {
                    Color.clear.frame(width: btnSize, height: btnSize)
                    RoundCalcButton(title: "flip₈", size: btnSize, bg: sciBtnColor, fg: .white, fontSize: 12) { model.applyUnary("flip8") }
                    RoundCalcButton(title: "flip₁₆", size: btnSize, bg: sciBtnColor, fg: .white, fontSize: 11) { model.applyUnary("flip16") }
                    RoundCalcButton(title: "FF", size: btnSize, bg: numberBtnColor.opacity(hexActive ? 1.0 : 0.4), fg: .white.opacity(hexActive ? 1.0 : 0.35), fontSize: 14) { model.inputProgrammerToken("FF") }
                    RoundCalcButton(title: "0", size: btnSize, bg: numberBtnColor, fg: .white, fontSize: 17) { model.inputProgrammerToken("0") }
                    RoundCalcButton(title: "00", size: btnSize, bg: numberBtnColor, fg: .white, fontSize: 14) { model.inputProgrammerToken("00") }
                    RoundCalcButton(title: model.rpnMode ? "enter" : "=", size: btnSize, bg: orangeColor, fg: .white, fontSize: model.rpnMode ? 11 : 19) { model.calculateResult() }
                }
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 12)
        }
    }

    private func pillToggleBtn(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Color.white.opacity(isSelected ? 0.28 : 0.0))
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func baseSegmentBtn(title: String, base: Int) -> some View {
        Button(action: { model.programmerBase = base }) {
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Color.white.opacity(model.programmerBase == base ? 0.28 : 0.0))
                .cornerRadius(4)
        }
        .buttonStyle(PlainButtonStyle())
    }

    // 2. Görseldeki 64-Bit İkili (Binary) Satırları (Tıklanabilir Bitler)
    private var binary64BitGrid: some View {
        let uval = model.currentUInt64
        return VStack(spacing: 6) {
            // Üst Satır: Bit 63 ... 32
            VStack(spacing: 1) {
                HStack(spacing: 0) {
                    ForEach(0..<8, id: \.self) { group in
                        let startBit = 63 - (group * 4)
                        nibbleView(uval: uval, topBit: startBit)
                        if group < 7 { Spacer() }
                    }
                }
                HStack {
                    Text("63").font(.system(size: 9, weight: .semibold)).foregroundColor(.white)
                    Spacer()
                    Text("47").font(.system(size: 9, weight: .semibold)).foregroundColor(.white)
                    Spacer()
                    Text("32").font(.system(size: 9, weight: .semibold)).foregroundColor(.white)
                }
            }

            // Alt Satır: Bit 31 ... 0
            VStack(spacing: 1) {
                HStack(spacing: 0) {
                    ForEach(0..<8, id: \.self) { group in
                        let startBit = 31 - (group * 4)
                        nibbleView(uval: uval, topBit: startBit)
                        if group < 7 { Spacer() }
                    }
                }
                HStack {
                    Text("31").font(.system(size: 9, weight: .semibold)).foregroundColor(.white)
                    Spacer()
                    Text("15").font(.system(size: 9, weight: .semibold)).foregroundColor(.white)
                    Spacer()
                    Text("0").font(.system(size: 9, weight: .semibold)).foregroundColor(.white)
                }
            }
        }
    }

    private func nibbleView(uval: UInt64, topBit: Int) -> some View {
        HStack(spacing: 1.5) {
            ForEach(0..<4, id: \.self) { offset in
                let bitIndex = topBit - offset
                let isOne = ((uval >> UInt64(bitIndex)) & 1) == 1
                Button(action: { model.toggleBit(at: bitIndex) }) {
                    Text(isOne ? "1" : "0")
                        .font(.system(size: 11, weight: isOne ? .bold : .regular, design: .monospaced))
                        .foregroundColor(isOne ? .white : Color.white.opacity(0.65))
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }

    // MARK: - Bilimsel Mod (⌘2) Sol Tuş Takımı (6 Sütun x 5 Satır)
    private var scientificKeypad: some View {
        VStack(spacing: buttonSpacing) {
            HStack(spacing: buttonSpacing) {
                RoundCalcButton(title: "(", size: btnSize, bg: sciBtnColor, fg: .white, fontSize: 14) {}
                RoundCalcButton(title: ")", size: btnSize, bg: sciBtnColor, fg: .white, fontSize: 14) {}
                RoundCalcButton(title: "mc", size: btnSize, bg: sciBtnColor, fg: .white, fontSize: 13) { model.memoryAction("mc") }
                RoundCalcButton(title: "m+", size: btnSize, bg: sciBtnColor, fg: .white, fontSize: 13) { model.memoryAction("m+") }
                RoundCalcButton(title: "m-", size: btnSize, bg: sciBtnColor, fg: .white, fontSize: 13) { model.memoryAction("m-") }
                RoundCalcButton(title: "mr", size: btnSize, bg: sciBtnColor, fg: .white, fontSize: 13) { model.memoryAction("mr") }
            }
            HStack(spacing: buttonSpacing) {
                RoundCalcButton(title: "2ⁿᵈ", size: btnSize, bg: model.isSecondFunc ? functionBtnColor : sciBtnColor, fg: .white, fontSize: 13) { model.isSecondFunc.toggle() }
                RoundCalcButton(title: "x²", size: btnSize, bg: sciBtnColor, fg: .white, fontSize: 14) { model.applyUnary("x²") }
                RoundCalcButton(title: "x³", size: btnSize, bg: sciBtnColor, fg: .white, fontSize: 14) { model.applyUnary("x³") }
                RoundCalcButton(title: "xʸ", size: btnSize, bg: sciBtnColor, fg: .white, fontSize: 14) { model.selectOperation(.power) }
                RoundCalcButton(title: "eˣ", size: btnSize, bg: sciBtnColor, fg: .white, fontSize: 14) { model.applyUnary("eˣ") }
                RoundCalcButton(title: "10ˣ", size: btnSize, bg: sciBtnColor, fg: .white, fontSize: 13) { model.applyUnary("10ˣ") }
            }
            HStack(spacing: buttonSpacing) {
                RoundCalcButton(title: "1/x", size: btnSize, bg: sciBtnColor, fg: .white, fontSize: 13) { model.applyUnary("1/x") }
                RoundCalcButton(title: "√x", size: btnSize, bg: sciBtnColor, fg: .white, fontSize: 14) { model.applyUnary("√x") }
                RoundCalcButton(title: "∛x", size: btnSize, bg: sciBtnColor, fg: .white, fontSize: 14) { model.applyUnary("∛x") }
                RoundCalcButton(title: "ʸ√x", size: btnSize, bg: sciBtnColor, fg: .white, fontSize: 13) { model.selectOperation(.yRoot) }
                RoundCalcButton(title: "ln", size: btnSize, bg: sciBtnColor, fg: .white, fontSize: 14) { model.applyUnary("ln") }
                RoundCalcButton(title: "log₁₀", size: btnSize, bg: sciBtnColor, fg: .white, fontSize: 12) { model.applyUnary("log₁₀") }
            }
            HStack(spacing: buttonSpacing) {
                RoundCalcButton(title: "x!", size: btnSize, bg: sciBtnColor, fg: .white, fontSize: 14) { model.applyUnary("x!") }
                RoundCalcButton(title: model.isSecondFunc ? "sin⁻¹" : "sin", size: btnSize, bg: sciBtnColor, fg: .white, fontSize: 13) { model.applyUnary("sin") }
                RoundCalcButton(title: model.isSecondFunc ? "cos⁻¹" : "cos", size: btnSize, bg: sciBtnColor, fg: .white, fontSize: 13) { model.applyUnary("cos") }
                RoundCalcButton(title: model.isSecondFunc ? "tan⁻¹" : "tan", size: btnSize, bg: sciBtnColor, fg: .white, fontSize: 13) { model.applyUnary("tan") }
                RoundCalcButton(title: "e", size: btnSize, bg: sciBtnColor, fg: .white, fontSize: 14) { model.applyUnary("e") }
                RoundCalcButton(title: "EE", size: btnSize, bg: sciBtnColor, fg: .white, fontSize: 13) { model.selectOperation(.ee) }
            }
            HStack(spacing: buttonSpacing) {
                RoundCalcButton(title: model.useRadians ? "Deg" : "Rad", size: btnSize, bg: sciBtnColor, fg: .white, fontSize: 13) { model.useRadians.toggle() }
                RoundCalcButton(title: model.isSecondFunc ? "sinh⁻¹" : "sinh", size: btnSize, bg: sciBtnColor, fg: .white, fontSize: 12) { model.applyUnary("sinh") }
                RoundCalcButton(title: model.isSecondFunc ? "cosh⁻¹" : "cosh", size: btnSize, bg: sciBtnColor, fg: .white, fontSize: 12) { model.applyUnary("cosh") }
                RoundCalcButton(title: model.isSecondFunc ? "tanh⁻¹" : "tanh", size: btnSize, bg: sciBtnColor, fg: .white, fontSize: 12) { model.applyUnary("tanh") }
                RoundCalcButton(title: "π", size: btnSize, bg: sciBtnColor, fg: .white, fontSize: 14) { model.applyUnary("π") }
                RoundCalcButton(title: "Rand", size: btnSize, bg: sciBtnColor, fg: .white, fontSize: 12) { model.applyUnary("Rand") }
            }
        }
    }

    // MARK: - Geçmişi Göster (^⌘S) Paneli
    private var historyOverlay: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Geçmiş")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                Spacer()
                Button("Temizle") { model.history.removeAll() }
                    .font(.system(size: 11))
                    .foregroundColor(orangeColor)
                    .buttonStyle(PlainButtonStyle())
                Button("✕") { model.showHistory = false }
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.gray)
                    .buttonStyle(PlainButtonStyle())
                    .padding(.leading, 6)
            }
            .padding(.top, 24)

            Divider().background(Color.gray.opacity(0.4))

            if model.history.isEmpty {
                Spacer()
                HStack {
                    Spacer()
                    Text("Henüz işlem geçmişi yok")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                    Spacer()
                }
                Spacer()
            } else {
                ScrollView {
                    VStack(alignment: .trailing, spacing: 8) {
                        ForEach(model.history) { item in
                            Button(action: {
                                model.display = item.result
                                model.showHistory = false
                            }) {
                                VStack(alignment: .trailing, spacing: 2) {
                                    Text(item.expression)
                                        .font(.system(size: 11))
                                        .foregroundColor(.gray)
                                    Text(item.result)
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.white)
                                }
                                .frame(maxWidth: .infinity, alignment: .trailing)
                                .padding(.vertical, 4)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
            }
        }
        .padding(12)
        .background(windowBg.opacity(0.97))
    }

    // MARK: - Matematik Notları (⌥⌘M) Paneli
    private var mathNotesOverlay: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Matematik Notları")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                Spacer()
                Button("Hesapla (=)") { model.evaluateMathNotes() }
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(orangeColor)
                    .buttonStyle(PlainButtonStyle())
                Button("✕") { model.showMathNotes = false }
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.gray)
                    .buttonStyle(PlainButtonStyle())
                    .padding(.leading, 6)
            }
            .padding(.top, 24)

            TextEditor(text: $model.mathNotesText)
                .font(.system(size: 13, design: .monospaced))
                .foregroundColor(.white)
                .background(Color.black.opacity(0.3))
                .cornerRadius(6)
        }
        .padding(12)
        .background(windowBg.opacity(0.98))
    }
}

// Yuvarlak Buton Bileşeni
struct RoundCalcButton: View {
    let title: String
    let size: CGFloat
    let bg: Color
    let fg: Color
    var fontSize: CGFloat = 17
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: fontSize, weight: .regular))
                .foregroundColor(fg)
                .frame(width: size, height: size)
                .background(bg)
                .clipShape(Circle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Doğrudan AppKit Sabit Pencere ve Orijinal macOS Üst Menü Çubuğu Yönetimi
class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    var window: NSWindow!
    let model = CalculatorModel.shared

    var basicMenuItem: NSMenuItem!
    var scientificMenuItem: NSMenuItem!
    var programmerMenuItem: NSMenuItem!
    var thousandsMenuItem: NSMenuItem!
    var rpnMenuItem: NSMenuItem!
    var convertMenuItem: NSMenuItem!
    var historyMenuItem: NSMenuItem!
    var alwaysOnTopMenuItem: NSMenuItem!
    var decimalItems: [NSMenuItem] = []

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        setupMenuBar()

        let fixedSize = model.mode.windowSize(convertMode: model.convertMode, showBinary: model.showBinaryGrid, rpnMode: model.rpnMode)

        window = NSWindow(
            contentRect: NSRect(origin: .zero, size: fixedSize),
            styleMask: [.titled, .closable, .miniaturizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        window.title = "Hesap Makinesi"
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.standardWindowButton(.zoomButton)?.isEnabled = false
        window.isRestorable = false
        window.isMovableByWindowBackground = true
        window.backgroundColor = NSColor(red: 0.14, green: 0.14, blue: 0.14, alpha: 1.0)
        window.contentMinSize = fixedSize
        window.contentMaxSize = fixedSize
        window.minSize = fixedSize
        window.maxSize = fixedSize
        window.delegate = self

        let hostingView = NSHostingView(rootView: ContentView())
        hostingView.frame = NSRect(origin: .zero, size: fixedSize)
        window.contentView = hostingView

        // Mod veya Dönüştür/İkili/RPN görünüm değiştiğinde pencere boyutunu yeni duruma göre kilitle
        model.onLayoutChange = { [weak self] in
            guard let self = self, let win = self.window else { return }
            let newSize = self.model.mode.windowSize(convertMode: self.model.convertMode, showBinary: self.model.showBinaryGrid, rpnMode: self.model.rpnMode)
            win.contentMinSize = newSize
            win.contentMaxSize = newSize
            win.minSize = newSize
            win.maxSize = newSize
            win.setContentSize(newSize)
            self.updateMenuCheckmarks()
        }

        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            return self?.model.handleKeyPress(event) ?? event
        }

        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func setupMenuBar() {
        let mainMenu = NSMenu()

        // 1) 🍎 Hesap Makinesi
        let appMenuItem = NSMenuItem()
        mainMenu.addItem(appMenuItem)
        let appMenu = NSMenu(title: "Hesap Makinesi")
        appMenuItem.submenu = appMenu

        appMenu.addItem(withTitle: "Hesap Makinesi Hakkında", action: #selector(showAbout), keyEquivalent: "")
        appMenu.addItem(NSMenuItem.separator())
        appMenu.addItem(withTitle: "Hesap Makinesi'ni Gizle", action: #selector(NSApplication.hide(_:)), keyEquivalent: "h")
        let hideOthers = appMenu.addItem(withTitle: "Diğerlerini Gizle", action: #selector(NSApplication.hideOtherApplications(_:)), keyEquivalent: "h")
        hideOthers.keyEquivalentModifierMask = [.command, .option]
        appMenu.addItem(withTitle: "Tümünü Göster", action: #selector(NSApplication.unhideAllApplications(_:)), keyEquivalent: "")
        appMenu.addItem(NSMenuItem.separator())
        appMenu.addItem(withTitle: "Hesap Makinesi'nden Çık", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")

        // 2) Düzen (3. Görsel ile Birebir Aynı!)
        let editMenuItem = NSMenuItem()
        mainMenu.addItem(editMenuItem)
        let editMenu = NSMenu(title: "Düzen")
        editMenu.autoenablesItems = false
        editMenuItem.submenu = editMenu

        let undoItem = editMenu.addItem(withTitle: "Geri Al", action: #selector(menuBackspace), keyEquivalent: "z")
        undoItem.isEnabled = false

        let redoItem = editMenu.addItem(withTitle: "Yinele", action: nil, keyEquivalent: "Z")
        redoItem.keyEquivalentModifierMask = [.command, .shift]
        redoItem.isEnabled = false

        editMenu.addItem(NSMenuItem.separator())

        let cutItem = editMenu.addItem(withTitle: "Kes", action: #selector(menuCut), keyEquivalent: "x")
        cutItem.isEnabled = false

        let copyItem = editMenu.addItem(withTitle: "Kopyala", action: #selector(menuCopy), keyEquivalent: "c")
        copyItem.isEnabled = true

        let pasteItem = editMenu.addItem(withTitle: "Yapıştır", action: #selector(menuPaste), keyEquivalent: "v")
        pasteItem.isEnabled = true

        let deleteItem = editMenu.addItem(withTitle: "Sil", action: #selector(menuClearAll), keyEquivalent: "")
        deleteItem.isEnabled = false

        let selectAllItem = editMenu.addItem(withTitle: "Tümünü Seç", action: nil, keyEquivalent: "a")
        selectAllItem.isEnabled = false

        editMenu.addItem(NSMenuItem.separator())

        let autoFillItem = NSMenuItem(title: "Otomatik Doldur", action: nil, keyEquivalent: "")
        let autoFillSubmenu = NSMenu(title: "Otomatik Doldur")
        autoFillSubmenu.addItem(withTitle: "Kişiler…", action: nil, keyEquivalent: "")
        autoFillSubmenu.addItem(withTitle: "Parolalar…", action: nil, keyEquivalent: "")
        autoFillItem.submenu = autoFillSubmenu
        editMenu.addItem(autoFillItem)

        // 3) Görüntü
        let viewMenuItem = NSMenuItem()
        mainMenu.addItem(viewMenuItem)
        let viewMenu = NSMenu(title: "Görüntü")
        viewMenu.autoenablesItems = false
        viewMenuItem.submenu = viewMenu

        basicMenuItem = viewMenu.addItem(withTitle: "Temel", action: #selector(selectBasicMode), keyEquivalent: "1")
        basicMenuItem.state = .on

        scientificMenuItem = viewMenu.addItem(withTitle: "Bilimsel", action: #selector(selectScientificMode), keyEquivalent: "2")
        programmerMenuItem = viewMenu.addItem(withTitle: "Programcı", action: #selector(selectProgrammerMode), keyEquivalent: "3")

        viewMenu.addItem(NSMenuItem.separator())

        thousandsMenuItem = viewMenu.addItem(withTitle: "Binlik Ayırıcıyı Göster", action: #selector(toggleThousandsSeparator), keyEquivalent: "")

        viewMenu.addItem(NSMenuItem.separator())

        rpnMenuItem = viewMenu.addItem(withTitle: "RPN Modu", action: #selector(toggleRPNMode), keyEquivalent: "r")

        convertMenuItem = viewMenu.addItem(withTitle: "Dönüştür", action: #selector(toggleConvertMode), keyEquivalent: "c")
        convertMenuItem.keyEquivalentModifierMask = [.command, .option]

        viewMenu.addItem(NSMenuItem.separator())

        let mathNotesItem = viewMenu.addItem(withTitle: "Matematik Notları…", action: #selector(openMathNotes), keyEquivalent: "m")
        mathNotesItem.keyEquivalentModifierMask = [.command, .option]

        viewMenu.addItem(NSMenuItem.separator())

        let decimalMenuItem = NSMenuItem(title: "Ondalık Basamak", action: nil, keyEquivalent: "")
        let decimalSubmenu = NSMenu(title: "Ondalık Basamak")
        decimalItems.removeAll()
        for i in 0...15 {
            let item = NSMenuItem(title: "\(i)", action: #selector(selectDecimalPlaces(_:)), keyEquivalent: "")
            item.tag = i
            item.state = (i == model.decimalPlaces) ? .on : .off
            decimalSubmenu.addItem(item)
            decimalItems.append(item)
        }
        decimalMenuItem.submenu = decimalSubmenu
        viewMenu.addItem(decimalMenuItem)

        viewMenu.addItem(NSMenuItem.separator())

        historyMenuItem = viewMenu.addItem(withTitle: "Geçmişi Göster", action: #selector(toggleHistory), keyEquivalent: "s")
        historyMenuItem.keyEquivalentModifierMask = [.control, .command]

        let fullScreenItem = NSMenuItem(title: "Tam Ekrana Geç", action: nil, keyEquivalent: "f")
        fullScreenItem.keyEquivalentModifierMask = [.control, .command]
        fullScreenItem.isEnabled = false
        viewMenu.addItem(fullScreenItem)

        // 4) Pencere (2. Görsel ile Birebir Aynı!)
        let windowMenuItem = NSMenuItem()
        mainMenu.addItem(windowMenuItem)
        let windowMenu = NSMenu(title: "Pencere")
        windowMenu.autoenablesItems = false
        windowMenuItem.submenu = windowMenu

        let closeItem = windowMenu.addItem(withTitle: "Kapat", action: #selector(NSWindow.performClose(_:)), keyEquivalent: "w")
        closeItem.isEnabled = true

        let minItem = windowMenu.addItem(withTitle: "Simge Durumuna Küçült", action: #selector(NSWindow.performMiniaturize(_:)), keyEquivalent: "m")
        minItem.isEnabled = true

        let minAllItem = windowMenu.addItem(withTitle: "Tümünü Simge Durumuna Küçült", action: #selector(miniaturizeAllWindows), keyEquivalent: "")
        minAllItem.isEnabled = true

        let zoomItem = windowMenu.addItem(withTitle: "Büyüt/Küçült", action: nil, keyEquivalent: "")
        zoomItem.isEnabled = false

        let fillItem = windowMenu.addItem(withTitle: "Doldur", action: nil, keyEquivalent: "f")
        fillItem.keyEquivalentModifierMask = [.control, .function]
        fillItem.isEnabled = false

        let centerItem = windowMenu.addItem(withTitle: "Ortala", action: #selector(centerMainWindow), keyEquivalent: "c")
        centerItem.keyEquivalentModifierMask = [.control, .function]
        centerItem.isEnabled = true

        windowMenu.addItem(NSMenuItem.separator())

        let moveResizeItem = NSMenuItem(title: "Taşı ve Boyutunu Değiştir", action: nil, keyEquivalent: "")
        let moveResizeSubmenu = NSMenu(title: "Taşı ve Boyutunu Değiştir")
        let subLeft = moveResizeSubmenu.addItem(withTitle: "Sola", action: nil, keyEquivalent: "")
        subLeft.isEnabled = false
        let subRight = moveResizeSubmenu.addItem(withTitle: "Sağa", action: nil, keyEquivalent: "")
        subRight.isEnabled = false
        moveResizeItem.submenu = moveResizeSubmenu
        windowMenu.addItem(moveResizeItem)

        let tileItem = windowMenu.addItem(withTitle: "Tam Ekran Döşe", action: nil, keyEquivalent: "")
        tileItem.isEnabled = false

        windowMenu.addItem(NSMenuItem.separator())

        let removeSetItem = windowMenu.addItem(withTitle: "Pencereyi Kümeden Sil", action: nil, keyEquivalent: "")
        removeSetItem.isEnabled = false

        windowMenu.addItem(NSMenuItem.separator())

        alwaysOnTopMenuItem = windowMenu.addItem(withTitle: "Her Zaman En Üstte", action: #selector(toggleAlwaysOnTop), keyEquivalent: "")
        alwaysOnTopMenuItem.isEnabled = true

        windowMenu.addItem(NSMenuItem.separator())

        let frontItem = windowMenu.addItem(withTitle: "Tümünü Öne Getir", action: #selector(NSApplication.arrangeInFront(_:)), keyEquivalent: "")
        frontItem.isEnabled = true

        // 5) Yardım
        let helpMenuItem = NSMenuItem()
        mainMenu.addItem(helpMenuItem)
        let helpMenu = NSMenu(title: "Yardım")
        helpMenuItem.submenu = helpMenu

        helpMenu.addItem(withTitle: "Hesap Makinesi Yardımı ve Özel Kısayollar", action: #selector(showHelp), keyEquivalent: "?")
        NSApp.helpMenu = helpMenu

        NSApp.mainMenu = mainMenu
    }

    private func updateMenuCheckmarks() {
        basicMenuItem.state = (model.mode == .basic) ? .on : .off
        scientificMenuItem.state = (model.mode == .scientific) ? .on : .off
        programmerMenuItem.state = (model.mode == .programmer) ? .on : .off
        thousandsMenuItem.state = model.showThousandsSeparator ? .on : .off
        rpnMenuItem.state = model.rpnMode ? .on : .off
        convertMenuItem.state = model.convertMode ? .on : .off
        // Programcı modunda "Dönüştür" seçeneği seçilemez (pasif/gri) olur
        convertMenuItem.isEnabled = (model.mode != .programmer)
        historyMenuItem.title = model.showHistory ? "Geçmişi Gizle" : "Geçmişi Göster"
    }

    @objc func showAbout() {
        let alert = NSAlert()
        alert.messageText = "Hesap Makinesi"
        alert.informativeText = "Sürüm 1.0 (macOS 11.0+ Universal)\n\nÖzel Hızlı Klavye Kısayolları:\n• A : Toplama (+)\n• E : Çıkarma (−)\n• X : Çarpma (×)\n• B : Bölme (÷)"
        alert.runModal()
    }

    @objc func showHelp() { showAbout() }
    @objc func menuCut() { model.copyToClipboard(); model.allClear() }
    @objc func menuCopy() { model.copyToClipboard() }
    @objc func menuPaste() { model.pasteFromClipboard() }
    @objc func menuBackspace() { model.backspace() }
    @objc func menuClearAll() { model.allClear() }
    @objc func selectBasicMode() { model.setMode(.basic) }
    @objc func selectScientificMode() { model.setMode(.scientific) }
    @objc func selectProgrammerMode() { model.setMode(.programmer) }
    @objc func toggleThousandsSeparator() { model.showThousandsSeparator.toggle(); updateMenuCheckmarks() }
    @objc func toggleRPNMode() { model.toggleRPN() }
    @objc func toggleConvertMode() { model.toggleConvert() }
    @objc func openMathNotes() { model.showMathNotes.toggle() }
    @objc func centerMainWindow() { window?.center() }
    @objc func miniaturizeAllWindows() { NSApp.windows.forEach { $0.miniaturize(nil) } }
    @objc func toggleAlwaysOnTop() {
        guard let win = window else { return }
        if win.level == .floating {
            win.level = .normal
            alwaysOnTopMenuItem.state = .off
        } else {
            win.level = .floating
            alwaysOnTopMenuItem.state = .on
        }
    }
    @objc func selectDecimalPlaces(_ sender: NSMenuItem) {
        model.decimalPlaces = sender.tag
        for item in decimalItems { item.state = (item.tag == sender.tag) ? .on : .off }
    }
    @objc func toggleHistory() { model.showHistory.toggle(); updateMenuCheckmarks() }

    func windowWillResize(_ sender: NSWindow, to frameSize: NSSize) -> NSSize {
        return model.mode.windowSize(convertMode: model.convertMode, showBinary: model.showBinaryGrid, rpnMode: model.rpnMode)
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return false
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
