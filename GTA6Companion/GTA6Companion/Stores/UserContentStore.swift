import Foundation
import Observation

/// Eigene Kartenpins und Missionsnotizen des Nutzers (lokal + iCloud).
@MainActor
@Observable
final class UserContentStore {
    private(set) var pins: [UserPin] = []
    private(set) var notes: [String: String] = [:]

    private let defaults: UserDefaults
    @ObservationIgnored private let cloud = CloudSync()

    private enum Key {
        static let pins = "user.pins"
        static let notes = "user.notes"
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        pins = decode(defaults.data(forKey: Key.pins)) ?? []
        notes = decode(defaults.data(forKey: Key.notes)) ?? [:]

        cloud.onExternalChange = { [weak self] keys in
            MainActor.assumeIsolated { self?.pullFromCloud(keys: keys) }
        }
        if pins.isEmpty && notes.isEmpty { pullFromCloud(keys: [Key.pins, Key.notes]) }
    }

    private func pullFromCloud(keys: [String]) {
        if keys.contains(Key.pins), let remote: [UserPin] = decode(cloud.data(Key.pins)) { pins = remote }
        if keys.contains(Key.notes), let remote: [String: String] = decode(cloud.data(Key.notes)) { notes = remote }
        save(pushToCloud: false)
    }

    // MARK: Pins

    func add(_ pin: UserPin) { pins.append(pin); save() }

    func update(_ pin: UserPin) {
        guard let index = pins.firstIndex(where: { $0.id == pin.id }) else { return }
        pins[index] = pin
        save()
    }

    func delete(_ pin: UserPin) { pins.removeAll { $0.id == pin.id }; save() }

    // MARK: Notizen

    func note(for missionID: String) -> String { notes[missionID] ?? "" }

    func setNote(_ text: String, for missionID: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        notes[missionID] = trimmed.isEmpty ? nil : text
        save()
    }

    // MARK: Speichern

    private func save(pushToCloud: Bool = true) {
        let encoder = JSONEncoder()
        let pinData = try? encoder.encode(pins)
        let noteData = try? encoder.encode(notes)
        defaults.set(pinData, forKey: Key.pins)
        defaults.set(noteData, forKey: Key.notes)
        if pushToCloud {
            cloud.set(pinData, for: Key.pins)
            cloud.set(noteData, for: Key.notes)
        }
    }

    private func decode<T: Decodable>(_ data: Data?) -> T? {
        guard let data else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }
}
