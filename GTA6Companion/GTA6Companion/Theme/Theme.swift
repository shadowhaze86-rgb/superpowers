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

// MARK: - Wiederverwendbare Bausteine

struct ScreenBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .scrollContentBackground(.hidden)
            .background {
                ZStack(alignment: .top) {
                    Theme.backdrop
                    // Sonnenuntergangs-Glühen am oberen Rand
                    RadialGradient(colors: [Theme.pink.opacity(0.35), .clear],
                                   center: .top, startRadius: 0, endRadius: 420)
                }
                .ignoresSafeArea()
            }
            .toolbarBackground(Theme.night.opacity(0.85), for: .navigationBar)
    }
}

extension View {
    func screenBackground() -> some View { modifier(ScreenBackground()) }

    func neonCard(padding: CGFloat = 16) -> some View {
        self
            .padding(padding)
            .background(Theme.card, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(Theme.stroke))
    }
}

struct GradientTitle: View {
    let text: String
    var size: CGFloat = 34

    var body: some View {
        Text(text.uppercased())
            .font(Theme.title(size))
            .italic()
            .foregroundStyle(Theme.sunset)
            .shadow(color: Theme.pink.opacity(0.6), radius: 12)
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

struct Pill: View {
    let text: String
    var color: Color = Theme.pink

    var body: some View {
        Text(text)
            .font(.caption.weight(.bold))
            .padding(.horizontal, 8).padding(.vertical, 3)
            .background(color.opacity(0.2), in: Capsule())
            .foregroundStyle(color)
    }
}

struct DemoBanner: View {
    var body: some View {
        Label("Demo-Daten: Inhalte in Resources/Data/*.json durch echte ersetzen.",
              systemImage: "exclamationmark.triangle.fill")
            .font(.footnote.weight(.semibold))
            .foregroundStyle(Theme.sun)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(Theme.sun.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
    }
}
