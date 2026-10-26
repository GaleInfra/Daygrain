import SwiftUI

enum Palette {
    static let ink = Color(hex: "43342F")
    static let accent = adaptive("994B38", "F0B89C")
    static let action = Color(hex: "A1533F")
    static let gold = adaptive("8C6329", "E8C381")
    static let sage = adaptive("4E735B", "B8D3AD")
    static let plum = adaptive("795A91", "D1B9E6")
    static let mint = adaptive("E7EEDC", "2C3A2E")
    static let background = adaptive("F8F1E8", "211D1C")
    static let surface = adaptive("FFFCF8", "302927")
    static let soft = adaptive("F0E4D9", "3E322E")
    static let text = adaptive("43342F", "F8EDDF")
    static let secondary = adaptive("6F5D50", "CAB7A4")
    static let line = adaptive("E6D6C7", "56453F")
    static let hero = adaptive("F2DEC4", "493527")
    static let rose = adaptive("964E6B", "E5B2C4")
    static let pageApricot = adaptive("F5DDCA", "382820")
    static let pageSage = adaptive("E6EDD9", "28342C")
    static let pageLavender = adaptive("EDE1F1", "352B3D")
    static let brandGrains = [
        ["FBE5AE", "E7AF56"],
        ["DCE7BA", "A0BF8F"],
        ["FFDBB7", "F1A076"],
        ["F4D0D5", "E29BAE"],
        ["E6D7F4", "B49AD7"]
    ].map { $0.map { Color(hex: $0) } }

    static func adaptive(_ light: String, _ dark: String) -> Color {
        Color(UIColor { $0.userInterfaceStyle == .dark ? UIColor(hex: dark) : UIColor(hex: light) })
    }
}

enum JournalTone {
    case clay, sage, honey, rose, lavender

    var ink: Color {
        switch self {
        case .clay: return Palette.accent
        case .sage: return Palette.sage
        case .honey: return Palette.gold
        case .rose: return Palette.rose
        case .lavender: return Palette.plum
        }
    }

    var wash: Color {
        switch self {
        case .clay: return Palette.adaptive("F6DFD0", "453128")
        case .sage: return Palette.adaptive("E8EEDC", "2E3C30")
        case .honey: return Palette.adaptive("F7E9C9", "453923")
        case .rose: return Palette.adaptive("F5E1E7", "45313B")
        case .lavender: return Palette.adaptive("EEE3F4", "3A2F45")
        }
    }

    var action: Color {
        switch self {
        case .clay: return Color(hex: "A1533F")
        case .sage: return Color(hex: "4C7059")
        case .honey: return Color(hex: "8D652C")
        case .rose: return Color(hex: "9B5672")
        case .lavender: return Color(hex: "79558F")
        }
    }

    var actionEnd: Color {
        switch self {
        case .clay: return Color(hex: "874237")
        case .sage: return Color(hex: "3D5C4D")
        case .honey: return Color(hex: "73502B")
        case .rose: return Color(hex: "814660")
        case .lavender: return Color(hex: "60456F")
        }
    }

    var gradient: LinearGradient {
        LinearGradient(colors: [action, actionEnd], startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

extension JournalKind {
    var tone: JournalTone { self == .sensory ? .clay : .lavender }
}

extension Color {
    init(hex: String) { self.init(uiColor: UIColor(hex: hex)) }

    func readableInk(in scheme: ColorScheme) -> Color {
        let traits = UITraitCollection(userInterfaceStyle: scheme == .dark ? .dark : .light)
        let source = UIColor(self).resolvedColor(with: traits)
        let paper = UIColor(Palette.surface).resolvedColor(with: traits)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        var pr: CGFloat = 0, pg: CGFloat = 0, pb: CGFloat = 0, pa: CGFloat = 0
        guard source.getRed(&r, green: &g, blue: &b, alpha: &a),
              paper.getRed(&pr, green: &pg, blue: &pb, alpha: &pa) else { return self }
        func linear(_ value: CGFloat) -> CGFloat { value <= 0.04045 ? value / 12.92 : pow((value + 0.055) / 1.055, 2.4) }
        func luminance(_ red: CGFloat, _ green: CGFloat, _ blue: CGFloat) -> CGFloat {
            0.2126 * linear(red) + 0.7152 * linear(green) + 0.0722 * linear(blue)
        }
        let paperLevel = luminance(pr, pg, pb)
        let target: CGFloat = paperLevel > 0.5 ? 0 : 1
        // Leave contrast headroom for the subtle color wash on cards and chips.
        for step in 0...24 {
            let amount = CGFloat(step) / 24
            let red = r + (target - r) * amount, green = g + (target - g) * amount, blue = b + (target - b) * amount
            let level = luminance(red, green, blue)
            if (max(level, paperLevel) + 0.05) / (min(level, paperLevel) + 0.05) >= 5 {
                return Color(red: Double(red), green: Double(green), blue: Double(blue))
            }
        }
        return target == 0 ? .black : .white
    }

    func readableForeground(in scheme: ColorScheme) -> Color {
        let traits = UITraitCollection(userInterfaceStyle: scheme == .dark ? .dark : .light)
        let resolved = UIColor(self).resolvedColor(with: traits)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        guard resolved.getRed(&r, green: &g, blue: &b, alpha: &a) else { return .white }
        func linear(_ channel: CGFloat) -> CGFloat { channel <= 0.04045 ? channel / 12.92 : pow((channel + 0.055) / 1.055, 2.4) }
        let luminance = 0.2126 * linear(r) + 0.7152 * linear(g) + 0.0722 * linear(b)
        return 1.05 / (luminance + 0.05) >= 4.5 ? .white : .black
    }
}

extension Sense {
    var tint: Color {
        let dark: String
        switch self {
        case .smell: dark = "BCD3A4"
        case .sound: dark = "E8C381"
        case .taste: dark = "F0B498"
        case .touch: dark = "E5B2C4"
        case .sight: dark = "D1B9E6"
        }
        return Palette.adaptive(colorHex, dark)
    }
}

extension UIColor {
    convenience init(hex: String) {
        let number = UInt64(hex, radix: 16) ?? 0x974B36
        self.init(red: CGFloat((number >> 16) & 0xFF) / 255, green: CGFloat((number >> 8) & 0xFF) / 255, blue: CGFloat(number & 0xFF) / 255, alpha: 1)
    }
}

struct Surface: ViewModifier {
    var padding: CGFloat = 18
    var tint: Color? = nil
    func body(content: Content) -> some View {
        content.padding(padding)
            .background {
                ZStack {
                    Palette.surface
                    LinearGradient(colors: [(tint ?? .clear).opacity(0.14), (tint ?? .clear).opacity(0.025)], startPoint: .topLeading, endPoint: .bottomTrailing)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 23, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 23, style: .continuous).stroke(tint?.opacity(0.22) ?? Palette.line.opacity(0.72), lineWidth: 1))
            .shadow(color: (tint ?? Palette.ink).opacity(0.035), radius: 12, x: 0, y: 5)
    }
}

struct PageBackdrop: View {
    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Palette.background
                RadialGradient(gradient: Gradient(colors: [Palette.pageApricot.opacity(0.72), Palette.pageApricot.opacity(0)]), center: .topLeading, startRadius: 0, endRadius: max(360, proxy.size.width * 1.2))
                RadialGradient(gradient: Gradient(colors: [Palette.pageLavender.opacity(0.60), Palette.pageLavender.opacity(0)]), center: .topTrailing, startRadius: 0, endRadius: max(310, proxy.size.width))
                RadialGradient(gradient: Gradient(colors: [Palette.pageSage.opacity(0.55), Palette.pageSage.opacity(0)]), center: .bottomLeading, startRadius: 0, endRadius: max(350, proxy.size.width * 1.1))
            }
        }.allowsHitTesting(false).accessibilityHidden(true)
    }
}

extension View {
    func surface(padding: CGFloat = 18, tint: Color? = nil) -> some View { modifier(Surface(padding: padding, tint: tint)) }
    func pageBackground() -> some View {
        frame(maxWidth: .infinity, maxHeight: .infinity).background(PageBackdrop().ignoresSafeArea())
    }
    func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

struct FilledButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var tone: JournalTone = .clay
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.font(.system(.subheadline, design: .rounded).weight(.semibold))
            .frame(maxWidth: .infinity).frame(minHeight: 22).padding(.horizontal, 16).padding(.vertical, 15)
            .foregroundColor(isEnabled ? .white : Palette.secondary)
            .background {
                ZStack {
                    if isEnabled { tone.gradient } else { Palette.soft }
                    Color.black.opacity(configuration.isPressed && isEnabled ? 0.09 : 0)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 17, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 17, style: .continuous).stroke(Color.white.opacity(isEnabled ? 0.16 : 0), lineWidth: 1))
            .shadow(color: isEnabled ? tone.action.opacity(configuration.isPressed ? 0.06 : 0.16) : .clear, radius: configuration.isPressed ? 3 : 8, x: 0, y: configuration.isPressed ? 1 : 4)
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.985 : 1)
    }
}

struct QuietButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    var tone: JournalTone = .clay
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.font(.system(.subheadline, design: .rounded).weight(.semibold))
            .frame(maxWidth: .infinity).frame(minHeight: 22).padding(.horizontal, 14).padding(.vertical, 14)
            .foregroundColor(isEnabled ? tone.ink : Palette.secondary)
            .background {
                ZStack {
                    if isEnabled {
                        LinearGradient(colors: [tone.wash, Palette.surface], startPoint: .topLeading, endPoint: .bottomTrailing)
                    } else { Palette.soft }
                    tone.ink.opacity(configuration.isPressed && isEnabled ? 0.08 : 0)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 17, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 17, style: .continuous).stroke(isEnabled ? tone.ink.opacity(0.22) : Palette.line, lineWidth: 1))
    }
}

struct RoundIconButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    var tone: JournalTone = .clay
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.font(.system(size: 17, weight: .medium))
            .foregroundColor(isEnabled ? tone.ink : Palette.secondary).frame(width: 46, height: 46)
            .background(isEnabled ? tone.wash : Palette.soft)
            .overlay(tone.ink.opacity(configuration.isPressed && isEnabled ? 0.08 : 0))
            .clipShape(Circle()).overlay(Circle().stroke(isEnabled ? tone.ink.opacity(0.20) : Palette.line, lineWidth: 1))
    }
}

struct GrainBloom: Shape {
    var petalIndex: Int? = nil

    func path(in rect: CGRect) -> Path {
        var unit = Path()
        let petal = Path(ellipseIn: CGRect(x: 0.405, y: 0.145, width: 0.19, height: 0.32))
        for index in 0..<5 {
            if let petalIndex = petalIndex, petalIndex != index { continue }
            let angle = CGFloat(index) * .pi * 2 / 5
            let cosine = cos(angle), sine = sin(angle)
            let transform = CGAffineTransform(a: cosine, b: sine, c: -sine, d: cosine,
                                               tx: 0.5 - cosine / 2 + sine / 2,
                                               ty: 0.5 - sine / 2 - cosine / 2)
            unit.addPath(petal, transform: transform)
        }
        if petalIndex == nil {
            unit.addEllipse(in: CGRect(x: 0.46, y: 0.46, width: 0.08, height: 0.08))
        }
        let side = min(rect.width, rect.height)
        return unit.applying(CGAffineTransform(a: side, b: 0, c: 0, d: side, tx: rect.midX - side / 2, ty: rect.midY - side / 2))
    }
}

enum EnglishDate {
    static func string(_ date: Date, template: String) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.setLocalizedDateFormatFromTemplate(template)
        return formatter.string(from: date)
    }
}
