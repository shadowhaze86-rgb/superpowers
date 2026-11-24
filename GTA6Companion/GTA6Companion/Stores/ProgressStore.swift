import Foundation
import Observation

/// Speichert den Spielfortschritt lokal (UserDefaults).
@Observable
final class ProgressStore {
    private(set) var completedMissions: Set<String> = []
    private(set) var completedObjectives: Set<String> = []
    private(set) var foundLocations: Set<String> = []

    private let defaults: UserDefaults
    private enum Key {
        static let missions = "progress.missions"
        static let objectives = "progress.objectives"
        static let locations = "progress.locations"
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        completedMissions = Set(defaults.stringArray(forKey: Key.missions) ?? [])
        completedObjectives = Set(defaults.stringArray(forKey: Key.objectives) ?? [])
        foundLocations = Set(defaults.stringArray(forKey: Key.locations) ?? [])
    }

    // MARK: Missionen

    func isDone(_ mission: Mission) -> Bool { completedMissions.contains(mission.id) }

    func toggle(_ mission: Mission) {
        if completedMissions.remove(mission.id) == nil {
            completedMissions.insert(mission.id)
            // Abschluss hakt alle Pflichtziele mit ab
            for objective in mission.objectives where !objective.isGold {
                completedObjectives.insert(objective.id)
            }
        }
        save()
    }

    // MARK: Ziele

    func isDone(_ objective: Objective) -> Bool { completedObjectives.contains(objective.id) }

    func toggle(_ objective: Objective) {
        if completedObjectives.remove(objective.id) == nil {
            completedObjectives.insert(objective.id)
        }
        save()
    }

    // MARK: Orte / Sammelobjekte

    func isFound(_ location: MapLocation) -> Bool { foundLocations.contains(location.id) }

    func toggleFound(_ location: MapLocation) {
        if foundLocations.remove(location.id) == nil {
            foundLocations.insert(location.id)
        }
        save()
    }

    // MARK: Statistik

    func ratio(done: Int, total: Int) -> Double {
        total == 0 ? 0 : Double(done) / Double(total)
    }

    func missionRatio(_ missions: [Mission]) -> Double {
        ratio(done: missions.filter { isDone($0) }.count, total: missions.count)
    }

    func goldRatio(_ objectives: [Objective]) -> Double {
        ratio(done: objectives.filter { isDone($0) }.count, total: objectives.count)
    }

    func collectibleRatio(_ items: [MapLocation]) -> Double {
        ratio(done: items.filter { isFound($0) }.count, total: items.count)
    }

    /// Gesamtfortschritt: Story 60 %, Gold-Ziele 20 %, Sammelobjekte 20 %
    /// (Kategorien ohne Inhalte werden ausgelassen und die Gewichte neu verteilt).
    func overall(content: ContentStore) -> Double {
        let parts: [(weight: Double, value: Double, present: Bool)] = [
            (0.6, missionRatio(content.missions), !content.missions.isEmpty),
            (0.2, goldRatio(content.goldObjectives), !content.goldObjectives.isEmpty),
            (0.2, collectibleRatio(content.collectibles), !content.collectibles.isEmpty),
        ]
        let present = parts.filter(\.present)
        let weightSum = present.reduce(0) { $0 + $1.weight }
        guard weightSum > 0 else { return 0 }
        return present.reduce(0) { $0 + $1.weight * $1.value } / weightSum
    }

    func reset() {
        completedMissions.removeAll()
        completedObjectives.removeAll()
        foundLocations.removeAll()
        save()
    }

    private func save() {
        defaults.set(Array(completedMissions), forKey: Key.missions)
        defaults.set(Array(completedObjectives), forKey: Key.objectives)
        defaults.set(Array(foundLocations), forKey: Key.locations)
    }
}
