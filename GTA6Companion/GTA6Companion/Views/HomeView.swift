import SwiftUI

struct HomeView: View {
    @Environment(ContentStore.self) private var content
    @Environment(ProgressStore.self) private var progress

    private var nextMission: Mission? {
        content.missions.first { !progress.isDone($0) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Willkommen in")
                            .font(.headline)
                            .foregroundStyle(Theme.textSecondary)
                        GradientTitle(text: "Leonida", size: 46)
                    }

                    if content.containsPlaceholders { DemoBanner() }
                    ForEach(content.loadErrors, id: \.self) { error in
                        Label(error, systemImage: "xmark.octagon.fill")
                            .font(.footnote).foregroundStyle(.red)
                    }

                    overallCard

                    ViewThatFits(in: .horizontal) {
                        HStack(spacing: 12) { statCards }
                        VStack(spacing: 12) { statCards }
                    }

                    if let mission = nextMission {
                        Text("Nächste Mission").font(.title3.bold())
                        NavigationLink(value: mission) {
                            MissionRow(mission: mission).neonCard()
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
                .frame(maxWidth: 900)
                .frame(maxWidth: .infinity)
            }
            .navigationDestination(for: Mission.self) { MissionDetailView(mission: $0) }
            .screenBackground()
        }
    }

    private var overallCard: some View {
        let value = progress.overall(content: content)
        return HStack(spacing: 20) {
            ZStack {
                ProgressRing(value: value, lineWidth: 14)
                Text(value, format: .percent.precision(.fractionLength(0)))
                    .font(Theme.title(26))
            }
            .frame(width: 120, height: 120)

            VStack(alignment: .leading, spacing: 6) {
                Text("Gesamtfortschritt").font(.title3.bold())
                Text("Story 60 % · Gold-Ziele 20 % · Sammelobjekte 20 %")
                    .font(.footnote).foregroundStyle(Theme.textSecondary)
            }
            Spacer(minLength: 0)
        }
        .neonCard(padding: 20)
    }

    @ViewBuilder private var statCards: some View {
        StatCard(title: "Story", icon: "flag.checkered",
                 done: content.missions.filter { progress.isDone($0) }.count,
                 total: content.missions.count, color: Theme.pink)
        StatCard(title: "Gold-Ziele", icon: "medal.fill",
                 done: content.goldObjectives.filter { progress.isDone($0) }.count,
                 total: content.goldObjectives.count, color: Theme.gold)
        NavigationLink {
            CollectiblesView()
        } label: {
            StatCard(title: "Sammelobjekte", icon: "star.fill",
                     done: content.collectibles.filter { progress.isFound($0) }.count,
                     total: content.collectibles.count, color: Theme.teal,
                     showsChevron: true)
        }
        .buttonStyle(.plain)
    }
}

struct StatCard: View {
    let title: String
    let icon: String
    let done: Int
    let total: Int
    let color: Color
    var showsChevron = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label(title, systemImage: icon)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(color)
                Spacer()
                if showsChevron {
                    Image(systemName: "chevron.right").font(.caption.bold()).foregroundStyle(Theme.textSecondary)
                }
            }
            Text("\(done) / \(total)").font(Theme.title(24))
            ProgressView(value: total == 0 ? 0 : Double(done), total: Double(max(total, 1)))
                .tint(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .neonCard()
    }
}
