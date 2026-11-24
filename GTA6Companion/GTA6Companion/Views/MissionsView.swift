import SwiftUI

struct MissionsView: View {
    @Environment(ContentStore.self) private var content
    @Environment(ProgressStore.self) private var progress

    enum StatusFilter: String, CaseIterable, Identifiable {
        case all = "Alle", open = "Offen", done = "Erledigt"
        var id: String { rawValue }
    }

    @State private var search = ""
    @State private var status: StatusFilter = .all
    @State private var character: Protagonist? = nil

    private var filtered: [Mission] {
        content.missions.filter { mission in
            let matchesSearch = search.isEmpty
                || mission.title.localizedCaseInsensitiveContains(search)
                || mission.summary.localizedCaseInsensitiveContains(search)
                || (mission.giver?.localizedCaseInsensitiveContains(search) ?? false)
            let matchesStatus: Bool = switch status {
            case .all: true
            case .open: !progress.isDone(mission)
            case .done: progress.isDone(mission)
            }
            let matchesCharacter = character == nil || mission.character == character
            return matchesSearch && matchesStatus && matchesCharacter
        }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Picker("Status", selection: $status) {
                        ForEach(StatusFilter.allCases) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    .listRowBackground(Color.clear)
                }

                ForEach(content.chapters(from: filtered)) { chapter in
                    Section {
                        ForEach(chapter.missions) { mission in
                            NavigationLink(value: mission) { MissionRow(mission: mission) }
                                .listRowBackground(Theme.card)
                        }
                    } header: {
                        HStack {
                            Text("Kapitel \(chapter.number) · \(chapter.title)")
                            Spacer()
                            Text(progress.missionRatio(chapter.missions), format: .percent.precision(.fractionLength(0)))
                                .foregroundStyle(Theme.orange)
                        }
                        .font(.subheadline.weight(.heavy))
                    }
                }

                if filtered.isEmpty {
                    ContentUnavailableView.search(text: search)
                        .listRowBackground(Color.clear)
                }
            }
            .navigationTitle("Missionen")
            .searchable(text: $search, prompt: "Mission, Auftraggeber …")
            .toolbar {
                Menu {
                    Picker("Charakter", selection: $character) {
                        Text("Alle").tag(Protagonist?.none)
                        ForEach(Protagonist.allCases) { Text($0.label).tag(Protagonist?.some($0)) }
                    }
                } label: {
                    Image(systemName: character == nil
                          ? "line.3.horizontal.decrease.circle"
                          : "line.3.horizontal.decrease.circle.fill")
                }
            }
            .navigationDestination(for: Mission.self) { MissionDetailView(mission: $0) }
            .screenBackground()
        }
    }
}

struct MissionRow: View {
    @Environment(ProgressStore.self) private var progress
    let mission: Mission

    var body: some View {
        HStack(spacing: 12) {
            Button {
                withAnimation(.snappy) { progress.toggle(mission) }
            } label: {
                Image(systemName: progress.isDone(mission) ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(progress.isDone(mission) ? Theme.teal : Theme.textSecondary)
            }
            .buttonStyle(.plain)
            .sensoryFeedback(.success, trigger: progress.isDone(mission))

            VStack(alignment: .leading, spacing: 4) {
                Text(mission.title)
                    .font(.headline)
                    .strikethrough(progress.isDone(mission), color: Theme.textSecondary)
                HStack(spacing: 6) {
                    Pill(text: mission.character.label, color: mission.character.color)
                    let gold = mission.objectives.filter(\.isGold)
                    if !gold.isEmpty {
                        Label("\(gold.filter { progress.isDone($0) }.count)/\(gold.count)", systemImage: "medal.fill")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(Theme.gold)
                    }
                    if mission.isPlaceholder { Pill(text: "Demo", color: Theme.sun) }
                }
            }
            Spacer(minLength: 0)
        }
        .contentShape(Rectangle())
    }
}
