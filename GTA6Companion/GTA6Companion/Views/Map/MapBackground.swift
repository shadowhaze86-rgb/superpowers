import SwiftUI
import UIKit

/// Reihenfolge der Kartenquellen:
/// 1. Bild "LeonidaMap" im Asset-Katalog (eigene oder lizenzierte Karte, quadratisch)
/// 2. Bild-URL aus den Einstellungen (nur mit Erlaubnis des Rechteinhabers verwenden!)
/// 3. Stilisierte Platzhalterkarte
struct MapBackground: View {
    @AppStorage("mapImageURL") private var urlString = ""

    var body: some View {
        if let image = UIImage(named: "LeonidaMap") {
            Image(uiImage: image).resizable().scaledToFill()
        } else if let url = URL(string: urlString), !urlString.isEmpty {
            AsyncImage(url: url) { phase in
                if let image = phase.image {
                    image.resizable().scaledToFill()
                } else {
                    PlaceholderMap()
                        .overlay { if phase.error == nil { ProgressView().tint(Theme.pink) } }
                }
            }
        } else {
            PlaceholderMap()
        }
    }
}

/// Grob an der offiziell gezeigten Form von Leonida (Florida-ähnlich) orientiert –
/// KEINE echte Spielkarte.
struct PlaceholderMap: View {
    private static let coast: [CGPoint] = [
        .init(x: 0.04, y: 0.12), .init(x: 0.30, y: 0.10), .init(x: 0.56, y: 0.09),
        .init(x: 0.64, y: 0.14), .init(x: 0.70, y: 0.26), .init(x: 0.75, y: 0.42),
        .init(x: 0.80, y: 0.58), .init(x: 0.81, y: 0.70), .init(x: 0.77, y: 0.80),
        .init(x: 0.69, y: 0.85), .init(x: 0.61, y: 0.83), .init(x: 0.55, y: 0.72),
        .init(x: 0.50, y: 0.57), .init(x: 0.45, y: 0.42), .init(x: 0.41, y: 0.29),
        .init(x: 0.30, y: 0.24), .init(x: 0.16, y: 0.23), .init(x: 0.04, y: 0.22),
    ]

    var body: some View {
        Canvas { context, size in
            let rect = CGRect(origin: .zero, size: size)
            context.fill(Path(rect), with: .linearGradient(
                Gradient(colors: [Color(hex: 0x0B3A5B), Color(hex: 0x0A1E3D), Theme.night]),
                startPoint: .zero, endPoint: CGPoint(x: size.width, y: size.height)))

            // Raster
            let step = size.width / 16
            var grid = Path()
            for i in 0...16 {
                let p = CGFloat(i) * step
                grid.move(to: CGPoint(x: p, y: 0)); grid.addLine(to: CGPoint(x: p, y: size.height))
                grid.move(to: CGPoint(x: 0, y: p)); grid.addLine(to: CGPoint(x: size.width, y: p))
            }
            context.stroke(grid, with: .color(Theme.teal.opacity(0.08)), lineWidth: 1)

            // Festland
            var land = Path()
            land.addLines(Self.coast.map { CGPoint(x: $0.x * size.width, y: $0.y * size.height) })
            land.closeSubpath()
            context.fill(land, with: .linearGradient(
                Gradient(colors: [Color(hex: 0x2E5E3A), Color(hex: 0x3C7A4A), Color(hex: 0x6B8F4E)]),
                startPoint: CGPoint(x: 0, y: 0), endPoint: CGPoint(x: 0, y: size.height)))
            context.stroke(land, with: .color(Theme.sun.opacity(0.55)), lineWidth: 2)

            // Inselkette im Süden
            for i in 0..<9 {
                let t = CGFloat(i) / 8
                let center = CGPoint(x: (0.62 - 0.26 * t) * size.width, y: (0.89 + 0.05 * t) * size.height)
                let r = size.width * (0.012 - 0.005 * t)
                context.fill(Path(ellipseIn: CGRect(x: center.x - r, y: center.y - r, width: r * 2.4, height: r * 1.4)),
                             with: .color(Color(hex: 0x6B8F4E)))
            }

            context.draw(Text("PLATZHALTER-KARTE").font(.system(size: size.width * 0.025, weight: .heavy))
                            .foregroundColor(Color.white.opacity(0.25)),
                         at: CGPoint(x: size.width * 0.2, y: size.height * 0.95))
        }
    }
}
