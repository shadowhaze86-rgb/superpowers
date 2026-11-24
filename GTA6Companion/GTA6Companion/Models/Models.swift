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
    case landmark, mission, safehouse, shop, activity, collectible
    var id: String { rawValue }

    var label: String {
        switch self {
        case .landmark: "Regionen"
        case .mission: "Missionen"
        case .safehouse: "Unterschlupf"
        case .shop: "Shops"
        case .activity: "Aktivitäten"
        case .collectible: "Sammelobjekte"
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
}

struct KnowledgeEntry: Identifiable, Codable, Hashable {
    enum Kind: String, Codable, CaseIterable, Identifiable {
        case character, region
        var id: String { rawValue }
        var label: String { self == .character ? "Charaktere" : "Regionen" }
        var icon: String { self == .character ? "person.crop.square.fill" : "map.circle.fill" }
    }

    let id: String
    let kind: Kind
    let name: String
    let subtitle: String
    let text: String
    var source: String? = nil
    var locationID: String? = nil
}
