import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var teaStore: TeaStore
    @StateObject private var timerCoordinator = TimerCoordinator()
    @State private var selectedTab = 0
    @State private var libraryPath = NavigationPath()

    var body: some View {
        TabView(selection: $selectedTab) {
            BrewView(
                timerCoordinator: timerCoordinator,
                selectedTab: $selectedTab
            )
            .tabItem {
                Label("Brew", systemImage: "cup.and.saucer.fill")
            }
            .tag(0)

            LibraryView(
                timerCoordinator: timerCoordinator,
                selectedTab: $selectedTab,
                path: $libraryPath
            )
            .tabItem {
                Label("Library", systemImage: "books.vertical.fill")
            }
            .tag(1)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(2)
        }
        .tint(TeaColorSlot.green.color)
        .sheet(isPresented: Binding(
            get: { !teaStore.preferences.onboardingComplete },
            set: { if !$0 { teaStore.setOnboardingComplete(true) } }
        )) {
            OnboardingView()
                .interactiveDismissDisabled()
        }
    }
}
