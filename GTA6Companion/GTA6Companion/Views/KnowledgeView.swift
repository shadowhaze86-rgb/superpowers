import SwiftUI

struct KnowledgeView: View {
    @Environment(ContentStore.self) private var content
    @State private var search = ""

    private func entries(_ kind: KnowledgeEntry.Kind) -> [KnowledgeEntry] {
        content.knowledge.filter {
            $0.kind == kind && (search.isEmpty
                || $0.name.localizedCaseInsensitiveContains(search)
                || $0.text.localizedCaseInsensitiveContains(search))
        }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(KnowledgeEntry.Kind.allCases) { kind in
                    let items = entries(kind)
                    if !items.isEmpty {
                        Section {
                            ForEach(items) { entry in
                                NavigationLink(value: entry) {
                                    HStack(spacing: 12) {
                                        Image(systemName: kind.icon)
                                            .font(.title2)
                                            .foregroundStyle(Theme.neon)
                                            .frame(width: 36)
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(entry.name).font(.headline)
                                            Text(entry.subtitle).font(.subheadline)
                                                .foregroundStyle(Theme.textSecondary)
                                        }
                                    }
                                }
                                .listRowBackground(Theme.card)
                            }
                        } header: {
                            Text(kind.label).font(.subheadline.weight(.heavy))
                        }
                    }
                }
            }
            .navigationTitle("Wissen")
            .searchable(text: $search, prompt: "Charaktere, Orte …")
            .navigationDestination(for: KnowledgeEntry.self) { KnowledgeDetailView(entry: $0) }
            .screenBackground()
        }
    }
}

struct KnowledgeDetailView: View {
    @Environment(ContentStore.self) private var content
    let entry: KnowledgeEntry
    @State private var showMap = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(entry.kind.label.uppercased())
                    .font(.caption.weight(.heavy)).foregroundStyle(Theme.orange)
                GradientTitle(text: entry.name, size: 32)
                Text(entry.subtitle).font(.headline).foregroundStyle(Theme.textSecondary)

                Text(entry.text)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .neonCard()

                if content.location(id: entry.locationID) != nil {
                    Button { showMap = true } label: {
                        Label("Auf Karte zeigen", systemImage: "map.fill").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .tint(Theme.teal)
                }

                if let source = entry.source {
                    Text("Quelle: \(source)").font(.caption).foregroundStyle(Theme.textSecondary)
                }
            }
            .padding()
            .frame(maxWidth: 760)
            .frame(maxWidth: .infinity)
        }
        .navigationBarTitleDisplayMode(.inline)
        .screenBackground()
        .sheet(isPresented: $showMap) {
            NavigationStack {
                LeonidaMapView(focusID: entry.locationID)
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) { Button("Fertig") { showMap = false } }
                    }
            }
        }
    }
}
