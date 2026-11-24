import SwiftUI

// MARK: - Wiederverwendbare Bausteine (nur App)

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

// MARK: - Spoiler-Schutz

struct SpoilerModifier: ViewModifier {
    let hidden: Bool
    let reveal: () -> Void

    func body(content: Content) -> some View {
        content
            .blur(radius: hidden ? 12 : 0)
            .allowsHitTesting(!hidden)
            .accessibilityHidden(hidden)
            .overlay {
                if hidden {
                    Button(action: reveal) {
                        Label("Spoiler – tippen zum Aufdecken", systemImage: "eye.slash.fill")
                            .font(.headline)
                            .padding(.horizontal, 16).padding(.vertical, 10)
                            .background(Theme.neon, in: Capsule())
                            .foregroundStyle(.white)
                            .shadow(color: Theme.pink.opacity(0.6), radius: 10)
                    }
                    .buttonStyle(.plain)
                }
            }
    }
}

extension View {
    func spoiler(hidden: Bool, reveal: @escaping () -> Void) -> some View {
        modifier(SpoilerModifier(hidden: hidden, reveal: reveal))
    }
}
