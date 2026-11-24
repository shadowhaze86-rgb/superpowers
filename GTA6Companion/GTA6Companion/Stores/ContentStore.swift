import Foundation
import Observation

/// Lädt alle Inhalte aus JSON-Dateien im App-Bundle.
/// Inhalte sind bewusst datengetrieben, damit sie ohne Code-Änderung gepflegt werden können
/// (später z. B. per Remote-JSON aktualisierbar).
@Observable
final class ContentStore {
    private(set) var missions: [Mission] = []
    private(set) var locations: [MapLocation] = []
    private(set) var knowledge: [KnowledgeEntry] = []
    private(set) var loadErrors: [String] = []

    init(bundle: Bundle = .main) {
        missions = load("missions", bundle)
        locations = load("locations", bundle)
        knowledge = load("knowledge", bundle)
        missions.sort { ($0.chapter, $0.id) < ($1.chapter, $1.id) }
    }

    private func load<T: Decodable>(_ name: String, _ bundle: Bundle) -> [T] {
        guard let url = bundle.url(forResource: name, withExtension: "json") else {
            loadErrors.append("\(name).json fehlt im Bundle")
            return []
        }
        do {
            return try JSONDecoder().decode([T].self, from: Data(contentsOf: url))
        } catch {
            loadErrors.append("\(name).json: \(error.localizedDescription)")
            return []
        }
    }

    // MARK: - Abfragen

    struct Chapter: Identifiable {
        let number: Int
        let title: String
        let missions: [Mission]
        var id: Int { number }
    }

    func chapters(from list: [Mission]) -> [Chapter] {
        Dictionary(grouping: list, by: \.chapter)
            .map { Chapter(number: $0.key, title: $0.value.first?.chapterTitle ?? "", missions: $0.value) }
            .sorted { $0.number < $1.number }
    }

    func location(id: String?) -> MapLocation? {
        guard let id else { return nil }
        return locations.first { $0.id == id }
    }

    var collectibles: [MapLocation] { locations.filter { $0.category == .collectible } }
    var goldObjectives: [Objective] { missions.flatMap(\.objectives).filter(\.isGold) }

    var containsPlaceholders: Bool {
        missions.contains(where: \.isPlaceholder) || locations.contains(where: \.isPlaceholder)
    }
}
