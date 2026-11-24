import SwiftUI

/// "Vice City Sunset"-Palette: Neon-Pink, Orange, Sonnengelb, Violett und Türkis
/// auf tiefem Nachtblau.
enum Theme {
    static let night = Color(hex: 0x0D071E)
    static let dusk = Color(hex: 0x22113F)
    static let card = Color.white.opacity(0.06)
    static let stroke = Color.white.opacity(0.10)

    static let pink = Color(hex: 0xFF3D8B)
    static let orange = Color(hex: 0xFF9A3C)
    static let sun = Color(hex: 0xFFD166)
    static let purple = Color(hex: 0x8B3DFF)
    static let teal = Color(hex: 0x19E3D1)
    static let gold = Color(hex: 0xF5C542)

    static let textSecondary = Color.white.opacity(0.65)

    static let sunset = LinearGradient(colors: [pink, orange, sun], startPoint: .leading, endPoint: .trailing)
    static let neon = LinearGradient(colors: [purple, pink], startPoint: .topLeading, endPoint: .bottomTrailing)
    static let backdrop = LinearGradient(colors: [dusk, night, night], startPoint: .top, endPoint: .bottom)

    static func title(_ size: CGFloat = 34) -> Font {
        .system(size: size, weight: .black, design: .rounded)
    }
}

extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        self.init(.sRGB,
                  red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255,
                  opacity: opacity)
    }
}

struct ProgressRing: View {
    let value: Double
    var lineWidth: CGFloat = 12
    var gradient: AngularGradient = AngularGradient(colors: [Theme.pink, Theme.orange, Theme.sun, Theme.pink], center: .center)

    var body: some View {
        ZStack {
            Circle().stroke(Color.white.opacity(0.08), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: max(0.001, min(value, 1)))
                .stroke(gradient, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .shadow(color: Theme.pink.opacity(0.5), radius: 6)
                .animation(.spring(duration: 0.6), value: value)
        }
    }
}
