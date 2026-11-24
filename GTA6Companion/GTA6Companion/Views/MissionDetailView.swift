import SwiftUI

struct MissionDetailView: View {
    @Environment(ContentStore.self) private var content
    @Environment(ProgressStore.self) private var progress
    @Environment(UserContentStore.self) private var userContent
    @Environment(LiveActivityManager.self) private var liveActivities
    @AppStorage("spoilerProtection") private var spoilerProtection = true

    let mission: Mission

    @State private var showMap = false
    @State private var revealed = false
    @State private var noteText = ""

    /// Briefing, Ziele und Tipps verdecken, solange die Mission offen ist und nicht aufgedeckt wurde.
    private var hideSpoilers: Bool { spoilerProtection && !revealed && !progress.isDone(mission) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header

                VStack(alignment: .leading, spacing: 20) {
                    section("Briefing", icon: "doc.text.fill") {
                        Text(mission.summary).foregroundStyle(.white.opacity(0.9))
                    }

                    section("Ziele", icon: "checklist") {
                        VStack(alignment: .leading, spacing: 12) {
                            ForEach(mission.objectives) { objective in
                                ObjectiveRow(objective: objective)
                            }
                        }
                    }

                    if let tips = mission.tips, !tips.isEmpty {
                        section("Tipps", icon: "lightbulb.fill") {
                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(tips, id: \.self) { tip in
                                    Label(tip, systemImage: "sparkle").foregroundStyle(.white.opacity(0.9))
                                }
                            }
                        }
                    }
                }
                .spoiler(hidden: hideSpoilers) { withAnimation(.easeOut) { revealed = true } }

                if let reward = mission.reward {
                    section("Belohnung", icon: "dollarsign.circle.fill") { Text(reward) }
                }

                section("Meine Notizen", icon: "square.and.pencil") {
                    TextField("Eigene Notizen zur Mission …", text: $noteText, axis: .vertical)
                        .lineLimit(3...10)
                        .onChange(of: noteText) { _, text in userContent.setNote(text, for: mission.id) }
                }

                actions
            }
            .padding()
            .frame(maxWidth: 760)
            .frame(maxWidth: .infinity)
        }
        .navigationTitle(mission.title)
        .navigationBarTitleDisplayMode(.inline)
        .screenBackground()
        .onAppear { noteText = userContent.note(for: mission.id) }
        .onChange(of: progress.revision) {
            Task { await liveActivities.update(mission, progress: progress) }
        }
        .sheet(isPresented: $showMap) {
            NavigationStack {
                LeonidaMapView(focusID: mission.locationID)
                    .navigationTitle("Karte")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Fertig") { showMap = false }
                        }
                    }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("KAPITEL \(mission.chapter) · \(mission.chapterTitle.uppercased())")
                .font(.caption.weight(.heavy))
                .foregroundStyle(Theme.orange)
            GradientTitle(text: mission.title, size: 30)
            HStack {
                Pill(text: mission.character.label, color: mission.character.color)
                if let giver = mission.giver { Pill(text: "Auftrag: \(giver)", color: Theme.purple) }
                if mission.isPlaceholder { Pill(text: "Demo", color: Theme.sun) }
            }
        }
    }

    @ViewBuilder private var actions: some View {
        if let location = content.location(id: mission.locationID) {
            Button { showMap = true } label: {
                Label("Startpunkt auf Karte: \(location.name)", systemImage: "map.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .tint(Theme.teal)
        }

        if liveActivities.isEnabled {
            Button {
                Task {
                    if liveActivities.isTracking(mission) {
                        await liveActivities.stop()
                    } else {
                        await liveActivities.start(mission, progress: progress)
                    }
                }
            } label: {
                Label(liveActivities.isTracking(mission) ? "Live-Aktivität beenden" : "Auf Sperrbildschirm verfolgen",
                      systemImage: liveActivities.isTracking(mission) ? "stop.circle" : "livephoto")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .tint(Theme.orange)
        }
        if let error = liveActivities.lastError {
            Text(error).font(.caption).foregroundStyle(.red)
        }

        Button {
            withAnimation(.snappy) { progress.toggle(mission) }
        } label: {
            Label(progress.isDone(mission) ? "Als offen markieren" : "Mission abgeschlossen",
                  systemImage: progress.isDone(mission) ? "arrow.uturn.backward" : "checkmark.seal.fill")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
        }
        .buttonStyle(.borderedProminent)
        .tint(progress.isDone(mission) ? Theme.purple : Theme.pink)
        .sensoryFeedback(.success, trigger: progress.isDone(mission))
    }

    private func section<Content: View>(_ title: String, icon: String,
                                         @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: icon)
                .font(.headline)
                .foregroundStyle(Theme.pink)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .neonCard()
    }
}

struct ObjectiveRow: View {
    @Environment(ProgressStore.self) private var progress
    let objective: Objective

    var body: some View {
        Button {
            withAnimation(.snappy) { progress.toggle(objective) }
        } label: {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Image(systemName: progress.isDone(objective) ? "checkmark.square.fill" : "square")
                    .foregroundStyle(progress.isDone(objective) ? Theme.teal : Theme.textSecondary)
                Text(objective.text)
                    .foregroundStyle(.white.opacity(progress.isDone(objective) ? 0.5 : 0.95))
                    .multilineTextAlignment(.leading)
                Spacer(minLength: 0)
                if objective.isGold {
                    Image(systemName: "medal.fill").foregroundStyle(Theme.gold)
                }
            }
        }
        .buttonStyle(.plain)
    }
}
