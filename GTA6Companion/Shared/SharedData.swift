import Foundation
import ActivityKit

/// Gemeinsamer Speicher von App und Widget-Erweiterung.
/// Die ID muss mit der App-Group in beiden .entitlements-Dateien übereinstimmen.
enum AppGroup {
    static let id = "group.com.example.leonidaguide"
    static var defaults: UserDefaults { UserDefaults(suiteName: id) ?? .standard }
}

/// Kompakter Fortschritts-Stand, den die App für das Widget ablegt.
struct ProgressSnapshot: Codable, Hashable {
    var overall: Double
    var storyDone: Int
    var storyTotal: Int
    var goldDone: Int
    var goldTotal: Int
    var collectiblesDone: Int
    var collectiblesTotal: Int
    var nextMission: String?

    static let key = "widget.snapshot"
    static let empty = ProgressSnapshot(overall: 0, storyDone: 0, storyTotal: 0, goldDone: 0, goldTotal: 0,
                                        collectiblesDone: 0, collectiblesTotal: 0, nextMission: nil)

    static func load() -> ProgressSnapshot {
        guard let data = AppGroup.defaults.data(forKey: key),
              let snapshot = try? JSONDecoder().decode(ProgressSnapshot.self, from: data) else { return .empty }
        return snapshot
    }

    func save() {
        guard let data = try? JSONEncoder().encode(self) else { return }
        AppGroup.defaults.set(data, forKey: Self.key)
    }
}

/// Live-Aktivität für die aktuell verfolgte Mission (Sperrbildschirm und Dynamic Island).
struct MissionActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var done: Int
        var total: Int
        var goldDone: Int
        var goldTotal: Int
        var currentObjective: String?
    }

    var missionID: String
    var missionTitle: String
    var chapter: String
    var character: String
}
