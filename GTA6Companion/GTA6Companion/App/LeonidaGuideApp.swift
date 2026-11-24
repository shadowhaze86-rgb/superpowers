import SwiftUI

@main
struct LeonidaGuideApp: App {
    @State private var content = ContentStore()
    @State private var progress = ProgressStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(content)
                .environment(progress)
        }
    }
}

struct RootView: View {
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
    }
}
