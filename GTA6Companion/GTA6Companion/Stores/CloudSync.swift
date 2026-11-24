import Foundation

/// Kleine Hülle um iCloud Key-Value-Storage (max. 1 MB, ideal für Fortschritt und Notizen).
/// Ohne iCloud-Berechtigung oder Anmeldung bleibt alles lokal, die App funktioniert trotzdem.
final class CloudSync {
    private let store = NSUbiquitousKeyValueStore.default
    private var observer: NSObjectProtocol?

    /// Wird aufgerufen, wenn ein anderes Gerät Daten geändert hat. Liefert die geänderten Schlüssel.
    var onExternalChange: (([String]) -> Void)?

    init() {
        observer = NotificationCenter.default.addObserver(
            forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: store, queue: .main
        ) { [weak self] note in
            let keys = note.userInfo?[NSUbiquitousKeyValueStoreChangedKeysKey] as? [String] ?? []
            self?.onExternalChange?(keys)
        }
        store.synchronize()
    }

    deinit {
        if let observer { NotificationCenter.default.removeObserver(observer) }
    }

    func strings(_ key: String) -> [String]? { store.array(forKey: key) as? [String] }
    func data(_ key: String) -> Data? { store.data(forKey: key) }
    func set(_ value: Any?, for key: String) { store.set(value, forKey: key) }

    var isAvailable: Bool { FileManager.default.ubiquityIdentityToken != nil }
}
