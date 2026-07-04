import SwiftUI

struct LibraryView: View {
    @EnvironmentObject private var teaStore: TeaStore
    @ObservedObject var timerCoordinator: TimerCoordinator
    @Binding var selectedTab: Int
    @Binding var path: NavigationPath

    @State private var showingAddTea = false
    @State private var showingPaywall = false
    @State private var showingFavoriteLimit = false

    var body: some View {
        NavigationStack(path: $path) {
            List {
                Section {
                    if teaStore.customTeas.isEmpty {
                        Text("Custom teas you add will appear here.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(teaStore.customTeas) { tea in
                            TeaRow(tea: tea) {
                                showingFavoriteLimit = true
                            }
                        }
                        .onDelete { offsets in
                            for index in offsets {
                                teaStore.deleteTea(teaStore.customTeas[index])
                            }
                        }
                    }
                } header: {
                    HStack {
                        Text("My Teas")
                        Spacer()
                        Button {
                            if teaStore.canAddCustomTea {
                                showingAddTea = true
                            } else {
                                showingPaywall = true
                            }
                        } label: {
                            Image(systemName: "plus")
                        }
                        .accessibilityLabel("Add custom tea")
                    }
                }

                Section("Built-in") {
                    ForEach(teaStore.builtInTeas) { tea in
                        TeaRow(tea: tea) {
                            showingFavoriteLimit = true
                        }
                    }
                }
            }
            .navigationTitle("Library")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .navigationDestination(for: Tea.self) { tea in
                TeaDetailView(
                    tea: tea,
                    timerCoordinator: timerCoordinator,
                    selectedTab: $selectedTab
                )
            }
            .sheet(isPresented: $showingAddTea) {
                AddTeaSheet()
            }
            .sheet(isPresented: $showingPaywall) {
                PaywallView(trigger: "Custom teas")
            }
            .alert("Favorite limit reached", isPresented: $showingFavoriteLimit) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Keep up to six favorites for quick brewing.")
            }
        }
    }
}

private struct TeaRow: View {
    @EnvironmentObject private var teaStore: TeaStore
    let tea: Tea
    let onFavoriteLimitReached: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button {
                if !tea.isFavorite && teaStore.favoriteTeas.count >= 6 {
                    onFavoriteLimitReached()
                    return
                }
                teaStore.toggleFavorite(tea)
            } label: {
                Image(systemName: tea.isFavorite ? "star.fill" : "star")
                    .foregroundStyle(tea.isFavorite ? .yellow : .secondary)
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(tea.isFavorite ? "Remove \(tea.name) from favorites" : "Add \(tea.name) to favorites")

            NavigationLink(value: tea) {
                HStack(spacing: 12) {
                    TeaIconView(tea: tea, size: 40)

                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Text(tea.name)
                                .font(.headline)
                            if tea.isBuiltIn {
                                Image(systemName: "checkmark.seal.fill")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .accessibilityLabel("Built-in")
                            }
                        }

                        TeaMetaLine(tea: tea, useCelsius: teaStore.preferences.useCelsius)
                    }
                }
            }
        }
        .padding(.vertical, 3)
    }
}
