import SwiftUI

struct SettingsView: View {
    @Environment(ContentStore.self) private var content
    @Environment(ProgressStore.self) private var progress
    @AppStorage("mapImageURL") private var mapImageURL = ""
    @AppStorage("contentBaseURL") private var contentBaseURL = ""
    @AppStorage("spoilerProtection") private var spoilerProtection = true

    @State private var confirmReset = false
    @State private var confirmClearImport = false
    @State private var showImport = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle("Spoiler-Schutz", isOn: $spoilerProtection)
                } footer: {
                    Text("Verdeckt Briefing, Ziele und Tipps offener Missionen, bis du sie antippst.")
                }
                .listRowBackground(Theme.card)

                Section {
                    TextField("https://example.com/leonida/", text: $contentBaseURL)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    Button {
                        guard let url = URL(string: contentBaseURL) else { return }
                        Task { await content.refresh(from: url) }
                    } label: {
                        HStack {
                            Label("Jetzt aktualisieren", systemImage: "arrow.clockwise")
                            if content.isRefreshing { Spacer(); ProgressView() }
                        }
                    }
                    .disabled(contentBaseURL.isEmpty || content.isRefreshing)
                    if let date = content.lastUpdated {
                        LabeledContent("Stand", value: date.formatted(date: .abbreviated, time: .shortened))
                    }
                    if content.usesRemoteContent {
                        Button("Mitgelieferte Inhalte verwenden", role: .destructive) { content.resetToBundled() }
                    }
                    ForEach(content.loadErrors, id: \.self) { Text($0).font(.caption).foregroundStyle(.red) }
                } header: {
                    Text("Inhalte online")
                } footer: {
                    Text("Ordner-URL mit missions.json, locations.json und knowledge.json. Wird beim App-Start automatisch geladen, neue Missionen brauchen so kein App-Update.")
                }
                .listRowBackground(Theme.card)

                Section {
                    Button { showImport = true } label: {
                        Label("Punkte importieren (GeoJSON/CSV/JSON)", systemImage: "square.and.arrow.down")
                    }
                    LabeledContent("Importierte Punkte", value: "\(content.importedLocations.count)")
                    if !content.importedLocations.isEmpty {
                        Button("Importierte Punkte löschen", role: .destructive) { confirmClearImport = true }
                    }
                } header: {
                    Text("Kartenpunkte")
                }
                .listRowBackground(Theme.card)

                Section {
                    TextField("https://…/leonida-map.jpg", text: $mapImageURL)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                } header: {
                    Text("Kartenbild (URL)")
                } footer: {
                    Text("Quadratisches Übersichtsbild. Nur Quellen verwenden, deren Nutzung erlaubt ist. Ein Bild \"LeonidaMap\" im Asset-Katalog hat Vorrang.")
                }
                .listRowBackground(Theme.card)

                Section {
                    LabeledContent("iCloud-Sync", value: progress.iCloudAvailable ? "Aktiv" : "Nicht verfügbar")
                    Button("Fortschritt zurücksetzen", role: .destructive) { confirmReset = true }
                } header: {
                    Text("Fortschritt")
                } footer: {
                    Text("Fortschritt, eigene Pins und Notizen werden über iCloud zwischen iPhone und iPad abgeglichen.")
                }
                .listRowBackground(Theme.card)

                Section("Über") {
                    Text("Inoffizielle Fan-App. Nicht mit Rockstar Games oder Take-Two Interactive verbunden. Alle Marken gehören ihren jeweiligen Inhabern.")
                        .font(.footnote)
                        .foregroundStyle(Theme.textSecondary)
                }
                .listRowBackground(Theme.card)
            }
            .navigationTitle("Einstellungen")
            .screenBackground()
            .sheet(isPresented: $showImport) { ImportView() }
            .confirmationDialog("Gesamten Fortschritt löschen?", isPresented: $confirmReset, titleVisibility: .visible) {
                Button("Löschen", role: .destructive) { progress.reset() }
            }
            .confirmationDialog("Alle importierten Punkte löschen?", isPresented: $confirmClearImport, titleVisibility: .visible) {
                Button("Löschen", role: .destructive) { content.clearImported() }
            }
        }
    }
}
