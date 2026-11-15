import SwiftUI

@main
struct PlanoEmagrecerApp: App {
    @State private var store = Store()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(store)
                .environment(\.locale, Locale(identifier: "pt_PT"))
        }
        .onChange(of: scenePhase) { _, phase in
            if phase != .active { store.save() }
        }
    }
}

struct ContentView: View {
    var body: some View {
        TabView {
            TodayView()
                .tabItem { Label("Hoje", systemImage: "checkmark.circle") }
            ProgressTab()
                .tabItem { Label("Progresso", systemImage: "chart.line.downtrend.xyaxis") }
            MenuTab()
                .tabItem { Label("Ementa", systemImage: "fork.knife") }
            ShoppingTab()
                .tabItem { Label("Compras", systemImage: "cart") }
            MoreTab()
                .tabItem { Label("Mais", systemImage: "list.bullet.rectangle") }
        }
    }
}
