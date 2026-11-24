import SwiftUI

enum Protagonist: String, Codable, CaseIterable, Identifiable {
    case lucia, jason, both
    var id: String { rawValue }

    var label: String {
        switch self {
        case .lucia: "Lucia"
        case .jason: "Jason"
        case .both: "Lucia & Jason"
        }
    }

    var color: Color {
        switch self {
        case .lucia: Theme.pink
        case .jason: Theme.teal
        case .both: Theme.orange
        }
    }
}

struct Objective: Identifiable, Codable, Hashable {
    let id: String
    let text: String
    /// Optionales Bonus-/Gold-Ziel
    var gold: Bool? = nil
    var isGold: Bool { gold ?? false }
}

struct Mission: Identifiable, Codable, Hashable {
    let id: String
    let title: String
    let chapter: Int
    let chapterTitle: String
    let character: Protagonist
    var giver: String? = nil
    let summary: String
    let objectives: [Objective]
    var tips: [String]? = nil
    var reward: String? = nil
    var locationID: String? = nil
    var placeholder: Bool? = nil

    var isPlaceholder: Bool { placeholder ?? false }
}

enum LocationCategory: String, Codable, CaseIterable, Identifiable {
    case landmark, mission, safehouse, shop, activity, collectible, other
    var id: String { rawValue }

    /// Unbekannte Kategorien (z. B. aus Importen) werden per Stichwort zugeordnet statt den Import abzubrechen.
    init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        self = LocationCategory(rawValue: raw) ?? LocationCategory(fuzzy: raw)
    }

    init(fuzzy raw: String) {
        let s = raw.lowercased()
        func has(_ words: String...) -> Bool { words.contains { s.contains($0) } }
        if let exact = LocationCategory(rawValue: s) { self = exact }
        else if has("collect", "sammel", "hidden", "package", "card", "relic", "token", "photo", "easter") { self = .collectible }
        else if has("mission", "story", "heist", "job", "stranger") { self = .mission }
        else if has("safe", "house", "home", "propert", "apartment", "motel") { self = .safehouse }
        else if has("shop", "store", "ammu", "cloth", "barber", "tattoo", "mod", "dealer", "gas") { self = .shop }
        else if has("activit", "race", "side", "hobby", "minigame", "event", "club", "bar") { self = .activity }
        else if has("landmark", "region", "city", "district", "area", "town", "park") { self = .landmark }
        else { self = .other }
    }

    var label: String {
        switch self {
        case .landmark: "Regionen"
        case .mission: "Missionen"
        case .safehouse: "Unterschlupf"
        case .shop: "Shops"
        case .activity: "Aktivitäten"
        case .collectible: "Sammelobjekte"
        case .other: "Sonstiges"
        }
    }

    var icon: String {
        switch self {
        case .landmark: "mappin.and.ellipse"
        case .mission: "flag.checkered"
        case .safehouse: "house.fill"
        case .shop: "bag.fill"
        case .activity: "gamecontroller.fill"
        case .collectible: "star.fill"
        case .other: "circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .landmark: Theme.purple
        case .mission: Theme.pink
        case .safehouse: Theme.teal
        case .shop: Theme.orange
        case .activity: Color(hex: 0x4DA3FF)
        case .collectible: Theme.gold
        case .other: Color(hex: 0xB8B8D0)
        }
    }
}

struct MapLocation: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let category: LocationCategory
    let region: String
    /// Normalisierte Kartenkoordinaten (0…1, Ursprung oben links)
    let x: Double
    let y: Double
    var note: String? = nil
    var placeholder: Bool? = nil

    var isPlaceholder: Bool { placeholder ?? false }
    var point: CGPoint { CGPoint(x: x, y: y) }
}

/// Vom Nutzer gesetzter Kartenpunkt mit Notiz.
struct UserPin: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String
    var note: String
    var x: Double
    var y: Double
    var created = Date()
}

struct KnowledgeEntry: Identifiable, Codable, Hashable {
    enum Kind: String, Codable, CaseIterable, Identifiable {
        case character, region, vehicle, weapon, business
        var id: String { rawValue }

        var label: String {
            switch self {
            case .character: "Charaktere"
            case .region: "Regionen"
            case .vehicle: "Fahrzeuge"
            case .weapon: "Waffen"
            case .business: "Geschäfte & Immobilien"
            }
        }

        var icon: String {
            switch self {
            case .character: "person.crop.square.fill"
            case .region: "map.circle.fill"
            case .vehicle: "car.fill"
            case .weapon: "scope"
            case .business: "building.2.fill"
            }
        }
    }

    let id: String
    let kind: Kind
    let name: String
    let subtitle: String
    let text: String
    var source: String? = nil
    var locationID: String? = nil
    /// Freie Kennwerte, z. B. ["Preis": "$250.000", "Klasse": "Sport"]
    var stats: [String: String]? = nil
}
