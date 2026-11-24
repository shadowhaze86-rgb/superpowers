import Foundation
import Observation

/// Inhalte (Missionen, Orte, Wissen) – datengetrieben aus JSON.
///
/// Ladereihenfolge je Datei: Remote-Cache (Application Support/content) → App-Bundle.
/// Zusätzlich importierte Kartenpunkte (z. B. aus GeoJSON/CSV) liegen separat und überleben Updates.
@MainActor
@Observable
final class ContentStore {
    private(set) var missions: [Mission] = []
    private(set) var baseLocations: [MapLocation] = []
    private(set) var importedLocations: [MapLocation] = []
    private(set) var knowledge: [KnowledgeEntry] = []
    private(set) var loadErrors: [String] = []
    private(set) var isRefreshing = false
    private(set) var lastUpdated: Date?

    var locations: [MapLocation] { baseLocations + importedLocations }

    private let bundle: Bundle
    private static let files = ["missions", "locations", "knowledge"]

    private static var supportDir: URL { URL.applicationSupportDirectory }
    private static var cacheDir: URL { supportDir.appending(path: "content", directoryHint: .isDirectory) }
    private static var importFile: URL { supportDir.appending(path: "imported-locations.json") }

    init(bundle: Bundle = .main) {
        self.bundle = bundle
        lastUpdated = UserDefaults.standard.object(forKey: "content.lastUpdated") as? Date
        loadLocal()
        if let data = try? Data(contentsOf: Self.importFile) {
            importedLocations = (try? JSONDecoder().decode([MapLocation].self, from: data)) ?? []
        }
    }

    var usesRemoteContent: Bool { FileManager.default.fileExists(atPath: Self.cacheDir.path) }

    // MARK: - Laden

    private func loadLocal() {
        loadErrors = []
        missions = load("missions")
        baseLocations = load("locations")
        knowledge = load("knowledge")
        missions.sort { ($0.chapter, $0.id) < ($1.chapter, $1.id) }
    }

    private func load<T: Decodable>(_ name: String) -> [T] {
        let cached = Self.cacheDir.appending(path: "\(name).json")
        let url = FileManager.default.fileExists(atPath: cached.path)
            ? cached
            : bundle.url(forResource: name, withExtension: "json")
        guard let url else {
            loadErrors.append("\(name).json fehlt")
            return []
        }
        do {
            return try JSONDecoder().decode([T].self, from: Data(contentsOf: url))
        } catch {
            loadErrors.append("\(name).json: \(error.localizedDescription)")
            return []
        }
    }

    /// Lädt `missions.json`, `locations.json`, `knowledge.json` von `baseURL`,
    /// prüft sie und übernimmt sie nur, wenn alle drei gültig sind.
    func refresh(from baseURL: URL) async {
        isRefreshing = true
        defer { isRefreshing = false }
        do {
            var fetched: [String: Data] = [:]
            for name in Self.files {
                let (data, response) = try await URLSession.shared.data(from: baseURL.appending(path: "\(name).json"))
                guard (response as? HTTPURLResponse)?.statusCode == 200 else {
                    throw URLError(.badServerResponse)
                }
                fetched[name] = data
            }
            let decoder = JSONDecoder()
            _ = try decoder.decode([Mission].self, from: fetched["missions"] ?? Data())
            _ = try decoder.decode([MapLocation].self, from: fetched["locations"] ?? Data())
            _ = try decoder.decode([KnowledgeEntry].self, from: fetched["knowledge"] ?? Data())

            try FileManager.default.createDirectory(at: Self.cacheDir, withIntermediateDirectories: true)
            for (name, data) in fetched {
                try data.write(to: Self.cacheDir.appending(path: "\(name).json"), options: .atomic)
            }
            lastUpdated = Date()
            UserDefaults.standard.set(lastUpdated, forKey: "content.lastUpdated")
            loadLocal()
        } catch {
            loadErrors.append("Aktualisierung fehlgeschlagen: \(error.localizedDescription)")
        }
    }

    /// Verwirft heruntergeladene Inhalte und nutzt wieder die mitgelieferten.
    func resetToBundled() {
        try? FileManager.default.removeItem(at: Self.cacheDir)
        lastUpdated = nil
        UserDefaults.standard.removeObject(forKey: "content.lastUpdated")
        loadLocal()
    }

    // MARK: - Import

    /// Übernimmt importierte Punkte; vorhandene IDs werden ersetzt.
    func addImported(_ items: [MapLocation]) throws {
        var byID = Dictionary(importedLocations.map { ($0.id, $0) }, uniquingKeysWith: { $1 })
        for item in items { byID[item.id] = item }
        importedLocations = byID.values.sorted { $0.name < $1.name }
        try persistImported()
    }

    func clearImported() {
        importedLocations = []
        try? FileManager.default.removeItem(at: Self.importFile)
    }

    private func persistImported() throws {
        try FileManager.default.createDirectory(at: Self.supportDir, withIntermediateDirectories: true)
        try JSONEncoder().encode(importedLocations).write(to: Self.importFile, options: .atomic)
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
    var regions: [String] { Array(Set(locations.map(\.region))).sorted() }

    var containsPlaceholders: Bool {
        missions.contains(where: \.isPlaceholder) || locations.contains(where: \.isPlaceholder)
    }
}
