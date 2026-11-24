import SwiftUI

struct SettingsView: View {
    @Environment(ProgressStore.self) private var progress
    @AppStorage("mapImageURL") private var mapImageURL = ""
    @State private var confirmReset = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("https://…/leonida-map.jpg", text: $mapImageURL)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                } header: {
                    Text("Kartenbild (URL)")
                } footer: {
                    Text("Quadratisches Kartenbild. Nur Quellen verwenden, deren Nutzung dir erlaubt ist. Ein Bild \"LeonidaMap\" im Asset-Katalog hat Vorrang.")
                }
                .listRowBackground(Theme.card)

                Section("Fortschritt") {
                    Button("Fortschritt zurücksetzen", role: .destructive) { confirmReset = true }
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
            .confirmationDialog("Gesamten Fortschritt löschen?", isPresented: $confirmReset, titleVisibility: .visible) {
                Button("Löschen", role: .destructive) { progress.reset() }
            }
        }
    }
}
