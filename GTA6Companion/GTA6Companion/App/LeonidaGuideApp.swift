import SwiftUI
import WidgetKit

@main
struct LeonidaGuideApp: App {
    @State private var content = ContentStore()
    @State private var progress = ProgressStore()
    @State private var userContent = UserContentStore()
    @State private var liveActivities = LiveActivityManager()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(content)
                .environment(progress)
                .environment(userContent)
                .environment(liveActivities)
        }
    }
}

struct RootView: View {
    @Environment(ContentStore.self) private var content
    @Environment(ProgressStore.self) private var progress
    @AppStorage("contentBaseURL") private var contentBaseURL = ""

    var body: some View {
        TabView {
            Tab("Start", systemImage: "sun.horizon.fill") { HomeView() }
            Tab("Missionen", systemImage: "list.bullet.rectangle.portrait.fill") { MissionsView() }
            Tab("Karte", systemImage: "map.fill") { MapScreen() }
            Tab("Wissen", systemImage: "books.vertical.fill") { KnowledgeView() }
            Tab("Einstellungen", systemImage: "gearshape.fill") { SettingsView() }
        }
        // iPhone: Tab-Bar, iPad: einklappbare Sidebar
        .tabViewStyle(.sidebarAdaptable)
        .tint(Theme.pink)
        .preferredColorScheme(.dark)
        // Widget mit aktuellem Stand versorgen
        .onChange(of: progress.revision, initial: true) { updateWidget() }
        .onChange(of: content.missions.count) { updateWidget() }
        .onChange(of: content.locations.count) { updateWidget() }
        // Inhalte beim Start aktualisieren, falls eine Quelle eingetragen ist
        .task {
            if let url = URL(string: contentBaseURL), !contentBaseURL.isEmpty {
                await content.refresh(from: url)
            }
        }
    }

    private func updateWidget() {
        progress.snapshot(content: content).save()
        WidgetCenter.shared.reloadAllTimelines()
    }
}
