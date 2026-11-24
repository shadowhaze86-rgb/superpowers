import ActivityKit
import SwiftUI
import WidgetKit

@main
struct LeonidaWidgetsBundle: WidgetBundle {
    var body: some Widget {
        ProgressWidget()
        MissionLiveActivity()
    }
}

// MARK: - Fortschritts-Widget

struct ProgressEntry: TimelineEntry {
    let date: Date
    let snapshot: ProgressSnapshot
}

struct ProgressProvider: TimelineProvider {
    func placeholder(in context: Context) -> ProgressEntry {
        ProgressEntry(date: .now, snapshot: ProgressSnapshot(
            overall: 0.42, storyDone: 21, storyTotal: 50, goldDone: 12, goldTotal: 40,
            collectiblesDone: 30, collectiblesTotal: 100, nextMission: "Nächste Mission"))
    }

    func getSnapshot(in context: Context, completion: @escaping (ProgressEntry) -> Void) {
        completion(context.isPreview ? placeholder(in: context) : ProgressEntry(date: .now, snapshot: .load()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ProgressEntry>) -> Void) {
        // Die App stößt Aktualisierungen selbst an (WidgetCenter.reloadAllTimelines)
        completion(Timeline(entries: [ProgressEntry(date: .now, snapshot: .load())], policy: .never))
    }
}

struct ProgressWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "LeonidaProgress", provider: ProgressProvider()) { entry in
            ProgressWidgetView(entry: entry)
                .containerBackground(for: .widget) { Theme.backdrop }
        }
        .configurationDisplayName("Leonida-Fortschritt")
        .description("Gesamtfortschritt und nächste Mission.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryCircular, .accessoryRectangular])
    }
}

struct ProgressWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: ProgressEntry

    private var s: ProgressSnapshot { entry.snapshot }
    private var percent: Text { Text(s.overall, format: .percent.precision(.fractionLength(0))) }

    var body: some View {
        switch family {
        case .accessoryCircular:
            Gauge(value: s.overall) { Text("GTA") } currentValueLabel: { percent }
                .gaugeStyle(.accessoryCircular)
        case .accessoryRectangular:
            VStack(alignment: .leading) {
                Text("Leonida ").bold() + percent
                Text("Story \(s.storyDone)/\(s.storyTotal)").font(.caption)
                if let next = s.nextMission { Text(next).font(.caption2).lineLimit(1) }
            }
        case .systemMedium:
            HStack(spacing: 16) {
                ring.frame(width: 96, height: 96)
                VStack(alignment: .leading, spacing: 6) {
                    row("Story", s.storyDone, s.storyTotal, Theme.pink)
                    row("Gold", s.goldDone, s.goldTotal, Theme.gold)
                    row("Sammeln", s.collectiblesDone, s.collectiblesTotal, Theme.teal)
                    if let next = s.nextMission {
                        Text("Weiter: \(next)").font(.caption2).foregroundStyle(.white.opacity(0.7)).lineLimit(1)
                    }
                }
            }
        default:
            VStack(spacing: 8) {
                ring.frame(width: 84, height: 84)
                Text("LEONIDA").font(Theme.title(13)).italic().foregroundStyle(Theme.sunset)
            }
        }
    }

    private var ring: some View {
        ZStack {
            ProgressRing(value: s.overall, lineWidth: 10)
            percent.font(Theme.title(20)).foregroundStyle(.white)
        }
    }

    private func row(_ title: String, _ done: Int, _ total: Int, _ color: Color) -> some View {
        HStack {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(title).font(.caption.weight(.semibold)).foregroundStyle(.white)
            Spacer()
            Text("\(done)/\(total)").font(.caption.monospacedDigit()).foregroundStyle(.white.opacity(0.8))
        }
    }
}

// MARK: - Live-Aktivität (Sperrbildschirm + Dynamic Island)

struct MissionLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: MissionActivityAttributes.self) { context in
            LockScreenMissionView(attributes: context.attributes, state: context.state)
                .activityBackgroundTint(Theme.night)
                .activitySystemActionForegroundColor(Theme.pink)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: "flag.checkered").foregroundStyle(Theme.pink)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("\(context.state.done)/\(context.state.total)").font(.headline.monospacedDigit())
                }
                DynamicIslandExpandedRegion(.center) {
                    Text(context.attributes.missionTitle).font(.headline).lineLimit(1)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(alignment: .leading, spacing: 6) {
                        ProgressView(value: Double(context.state.done), total: Double(max(context.state.total, 1)))
                            .tint(Theme.pink)
                        if let current = context.state.currentObjective {
                            Text("→ \(current)").font(.caption).lineLimit(1)
                        }
                    }
                }
            } compactLeading: {
                Image(systemName: "flag.checkered").foregroundStyle(Theme.pink)
            } compactTrailing: {
                Text("\(context.state.done)/\(context.state.total)").monospacedDigit().foregroundStyle(Theme.orange)
            } minimal: {
                Image(systemName: "flag.checkered").foregroundStyle(Theme.pink)
            }
            .keylineTint(Theme.pink)
        }
    }
}

struct LockScreenMissionView: View {
    let attributes: MissionActivityAttributes
    let state: MissionActivityAttributes.ContentState

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("\(attributes.chapter.uppercased()) · \(attributes.character.uppercased())")
                    .font(.caption2.weight(.heavy))
                    .foregroundStyle(Theme.orange)
                Spacer()
                if state.goldTotal > 0 {
                    Label("\(state.goldDone)/\(state.goldTotal)", systemImage: "medal.fill")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Theme.gold)
                }
            }
            Text(attributes.missionTitle.uppercased())
                .font(Theme.title(20)).italic()
                .foregroundStyle(Theme.sunset)
            ProgressView(value: Double(state.done), total: Double(max(state.total, 1)))
                .tint(Theme.pink)
            Text(state.currentObjective.map { "Nächstes Ziel: \($0)" } ?? "Alle Pflichtziele erledigt ✓")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.85))
        }
        .padding()
    }
}
