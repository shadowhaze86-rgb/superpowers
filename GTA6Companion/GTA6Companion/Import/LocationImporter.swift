import Foundation

/// Liest Kartenpunkte aus fremden Formaten ein und rechnet sie in normalisierte Koordinaten (0…1) um.
///
/// Unterstützt:
/// - App-eigenes JSON (`[MapLocation]`, bereits normalisiert)
/// - GeoJSON `FeatureCollection` mit `Point`-Geometrien (z. B. Export aus Leaflet-Karten)
/// - CSV mit Kopfzeile, Spalten: `name, category, region, x, y, note` (Reihenfolge egal)
enum LocationImporter {
    struct RawPoint: Hashable {
        var id: String?
        var name: String
        var category: String
        var region: String
        var note: String?
        var a: Double   // erste Koordinate (x bzw. Längengrad)
        var b: Double   // zweite Koordinate (y bzw. Breitengrad)
    }

    /// Umrechnung Rohkoordinaten → 0…1. Vorbelegt mit der Ausdehnung der Daten.
    struct Calibration: Equatable {
        var minA: Double, maxA: Double
        var minB: Double, maxB: Double
        /// Leaflet/GeoJSON: y wächst nach oben → für Bildkoordinaten umdrehen
        var flipB: Bool
        var swap: Bool

        static func fitting(_ points: [RawPoint]) -> Calibration {
            let a = points.map(\.a), b = points.map(\.b)
            let alreadyNormalized = (a + b).allSatisfy { (0...1).contains($0) }
            if alreadyNormalized { return Calibration(minA: 0, maxA: 1, minB: 0, maxB: 1, flipB: false, swap: false) }
            return Calibration(minA: a.min() ?? 0, maxA: a.max() ?? 1,
                               minB: b.min() ?? 0, maxB: b.max() ?? 1,
                               flipB: true, swap: false)
        }

        func apply(_ p: RawPoint) -> (x: Double, y: Double) {
            let (first, second) = swap ? (p.b, p.a) : (p.a, p.b)
            let (minF, maxF, minS, maxS) = swap ? (minB, maxB, minA, maxA) : (minA, maxA, minB, maxB)
            let x = (first - minF) / max(maxF - minF, .ulpOfOne)
            var y = (second - minS) / max(maxS - minS, .ulpOfOne)
            if flipB { y = 1 - y }
            return (min(max(x, 0), 1), min(max(y, 0), 1))
        }
    }

    enum ImportError: LocalizedError {
        case unsupported, empty
        var errorDescription: String? {
            switch self {
            case .unsupported: "Format nicht erkannt (erwartet: JSON, GeoJSON oder CSV)."
            case .empty: "Keine Punkte gefunden."
            }
        }
    }

    // MARK: - Parsen

    static func parse(_ data: Data, fileExtension: String) throws -> [RawPoint] {
        let points: [RawPoint]
        if fileExtension.lowercased() == "csv" {
            points = try parseCSV(data)
        } else if let native = try? JSONDecoder().decode([MapLocation].self, from: data) {
            points = native.map {
                RawPoint(id: $0.id, name: $0.name, category: $0.category.rawValue,
                         region: $0.region, note: $0.note, a: $0.x, b: $0.y)
            }
        } else {
            points = try parseGeoJSON(data)
        }
        guard !points.isEmpty else { throw ImportError.empty }
        return points
    }

    static func makeLocations(_ points: [RawPoint], calibration: Calibration, source: String) -> [MapLocation] {
        points.enumerated().map { index, p -> MapLocation in
            let (x, y) = calibration.apply(p)
            return MapLocation(
                id: p.id.map { "import-\(source)-\($0)" } ?? "import-\(source)-\(index)",
                name: p.name,
                category: LocationCategory(fuzzy: p.category),
                region: p.region.isEmpty ? "Unbekannt" : p.region,
                x: x, y: y,
                note: p.note
            )
        }
    }

    private static func parseGeoJSON(_ data: Data) throws -> [RawPoint] {
        guard let root = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw ImportError.unsupported
        }
        let features: [[String: Any]]
        if let list = root["features"] as? [[String: Any]] {
            features = list
        } else if root["geometry"] != nil {
            features = [root]
        } else {
            throw ImportError.unsupported
        }

        return features.compactMap { feature in
            guard let geometry = feature["geometry"] as? [String: Any],
                  (geometry["type"] as? String) == "Point",
                  let coords = geometry["coordinates"] as? [Any], coords.count >= 2,
                  let a = number(coords[0]), let b = number(coords[1]) else { return nil }
            let props = feature["properties"] as? [String: Any] ?? [:]
            func text(_ keys: String...) -> String? {
                for key in keys { if let v = props[key] { return "\(v)" } }
                return nil
            }
            let id = (feature["id"]).map { "\($0)" } ?? text("id")
            return RawPoint(
                id: id,
                name: text("name", "title", "label") ?? "Punkt",
                category: text("category", "type", "group", "layer") ?? "",
                region: text("region", "area", "district", "county") ?? "",
                note: text("note", "description", "desc", "info"),
                a: a, b: b
            )
        }
    }

    private static func parseCSV(_ data: Data) throws -> [RawPoint] {
        guard let text = String(data: data, encoding: .utf8) else { throw ImportError.unsupported }
        var lines = text.split(whereSeparator: \.isNewline).map(String.init)
        guard !lines.isEmpty else { throw ImportError.empty }
        let separator: Character = lines[0].contains(";") ? ";" : ","
        let header = splitCSV(lines.removeFirst(), separator).map { $0.lowercased() }
        func column(_ names: String...) -> Int? { header.firstIndex { names.contains($0) } }
        guard let xi = column("x", "lng", "lon", "longitude"),
              let yi = column("y", "lat", "latitude") else { throw ImportError.unsupported }
        let ni = column("name", "title"), ci = column("category", "type"),
            ri = column("region", "area"), oi = column("note", "description"), ii = column("id")

        return lines.compactMap { line in
            let cols = splitCSV(line, separator)
            func value(_ i: Int?) -> String? { i.flatMap { $0 < cols.count ? cols[$0] : nil } }
            guard let a = value(xi).flatMap({ number($0) }), let b = value(yi).flatMap({ number($0) }) else { return nil }
            return RawPoint(id: value(ii), name: value(ni) ?? "Punkt", category: value(ci) ?? "",
                            region: value(ri) ?? "", note: value(oi), a: a, b: b)
        }
    }

    /// Einfache CSV-Zerlegung mit Unterstützung für Anführungszeichen.
    private static func splitCSV(_ line: String, _ separator: Character) -> [String] {
        var result: [String] = []
        var current = ""
        var quoted = false
        for char in line {
            if char == "\"" { quoted.toggle() }
            else if char == separator && !quoted { result.append(current); current = "" }
            else { current.append(char) }
        }
        result.append(current)
        return result.map { $0.trimmingCharacters(in: .whitespaces) }
    }

    private static func number(_ any: Any) -> Double? {
        if let d = any as? Double { return d }
        if let n = any as? NSNumber { return n.doubleValue }
        if let s = any as? String { return Double(s.replacingOccurrences(of: ",", with: ".")) }
        return nil
    }
}
