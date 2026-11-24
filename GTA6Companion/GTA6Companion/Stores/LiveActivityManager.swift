import ActivityKit
import Foundation
import Observation

/// Startet/aktualisiert die Live-Aktivität für die gerade verfolgte Mission.
@MainActor
@Observable
final class LiveActivityManager {
    private(set) var trackedMissionID: String?
    private(set) var lastError: String?
    @ObservationIgnored private var activity: Activity<MissionActivityAttributes>?

    init() {
        // Nach App-Neustart laufende Aktivität wieder aufnehmen
        if let running = Activity<MissionActivityAttributes>.activities.first {
            activity = running
            trackedMissionID = running.attributes.missionID
        }
    }

    var isEnabled: Bool { ActivityAuthorizationInfo().areActivitiesEnabled }

    func isTracking(_ mission: Mission) -> Bool { trackedMissionID == mission.id }

    func start(_ mission: Mission, progress: ProgressStore) async {
        await stop()
        let attributes = MissionActivityAttributes(
            missionID: mission.id,
            missionTitle: mission.title,
            chapter: "Kapitel \(mission.chapter)",
            character: mission.character.label
        )
        do {
            activity = try Activity.request(
                attributes: attributes,
                content: .init(state: Self.state(for: mission, progress: progress), staleDate: nil)
            )
            trackedMissionID = mission.id
            lastError = nil
        } catch {
            lastError = error.localizedDescription
        }
    }

    func update(_ mission: Mission, progress: ProgressStore) async {
        guard let activity, activity.attributes.missionID == mission.id else { return }
        await activity.update(.init(state: Self.state(for: mission, progress: progress), staleDate: nil))
    }

    func stop() async {
        if let activity {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
        activity = nil
        trackedMissionID = nil
    }

    private static func state(for mission: Mission, progress: ProgressStore) -> MissionActivityAttributes.ContentState {
        let required = mission.objectives.filter { !$0.isGold }
        let gold = mission.objectives.filter(\.isGold)
        return .init(
            done: required.filter { progress.isDone($0) }.count,
            total: required.count,
            goldDone: gold.filter { progress.isDone($0) }.count,
            goldTotal: gold.count,
            currentObjective: required.first { !progress.isDone($0) }?.text
        )
    }
}
