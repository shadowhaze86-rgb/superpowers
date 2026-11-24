import SwiftUI

/// Sammelobjekte nach Region gruppiert, mit Fortschritt je Region.
struct CollectiblesView: View {
    @Environment(ContentStore.self) private var content
    @Environment(ProgressStore.self) private var progress

    @State private var hideFound = false
    @State private var mapFocus: MapLocation?

    private var groups: [(region: String, items: [MapLocation])] {
        Dictionary(grouping: content.collectibles, by: \.region)
            .map { (region: $0.key, items: $0.value.sorted { $0.name < $1.name }) }
            .sorted { $0.region < $1.region }
    }

    var body: some View {
        List {
            if content.collectibles.isEmpty {
                ContentUnavailableView("Keine Sammelobjekte",
                                       systemImage: "star.slash",
                                       description: Text("Sammelobjekte über Einstellungen → Punkte importieren hinzufügen."))
                    .listRowBackground(Color.clear)
            }
            ForEach(groups, id: \.region) { group in
                let items = hideFound ? group.items.filter { !progress.isFound($0) } : group.items
                Section {
                    ForEach(items) { item in
                        HStack {
                            Button {
                                withAnimation(.snappy) { progress.toggleFound(item) }
                            } label: {
                                Image(systemName: progress.isFound(item) ? "checkmark.circle.fill" : "circle")
                                    .font(.title3)
                                    .foregroundStyle(progress.isFound(item) ? Theme.teal : Theme.textSecondary)
                            }
                            .buttonStyle(.plain)
                            VStack(alignment: .leading) {
                                Text(item.name).font(.headline)
                                if let note = item.note {
                                    Text(note).font(.caption).foregroundStyle(Theme.textSecondary).lineLimit(2)
                                }
                            }
                            Spacer()
                            Button { mapFocus = item } label: { Image(systemName: "map") }
                                .buttonStyle(.borderless)
                                .tint(Theme.pink)
                        }
                        .listRowBackground(Theme.card)
                    }
                } header: {
                    HStack {
                        Text(group.region)
                        Spacer()
                        Text("\(group.items.filter { progress.isFound($0) }.count)/\(group.items.count)")
                            .foregroundStyle(Theme.gold)
                    }
                    .font(.subheadline.weight(.heavy))
                }
            }
        }
        .navigationTitle("Sammelobjekte")
        .toolbar {
            Toggle(isOn: $hideFound) { Image(systemName: hideFound ? "eye.slash" : "eye") }
                .toggleStyle(.button)
        }
        .screenBackground()
        .sheet(item: $mapFocus) { item in
            NavigationStack {
                LeonidaMapView(focusID: item.id)
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) { Button("Fertig") { mapFocus = nil } }
                    }
            }
        }
    }
}
