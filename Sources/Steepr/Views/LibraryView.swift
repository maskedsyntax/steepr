import SwiftUI

struct LibraryView: View {
    @EnvironmentObject private var teaStore: TeaStore
    @ObservedObject var timerCoordinator: TimerCoordinator
    @Binding var selectedTab: Int
    @Binding var path: NavigationPath

    @State private var showingAddTea = false
    @State private var showingPaywall = false
    @State private var showingFavoriteLimit = false
    @State private var pendingTeaDeleteIDs: [Tea.ID] = []

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
                            pendingTeaDeleteIDs = offsets.map { teaStore.customTeas[$0].id }
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
                AddTeaSheet(defaultSteepSeconds: teaStore.preferences.defaultSteepSeconds)
            }
            .sheet(isPresented: $showingPaywall) {
                PaywallView(trigger: "Custom teas")
            }
            .alert("Favorite limit reached", isPresented: $showingFavoriteLimit) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Keep up to six favorites for quick brewing.")
            }
            .alert(deleteConfirmationTitle, isPresented: deleteConfirmationBinding) {
                Button(deleteConfirmationButtonTitle, role: .destructive) {
                    deletePendingTeas()
                }
                Button("Cancel", role: .cancel) {
                    pendingTeaDeleteIDs = []
                }
            } message: {
                Text(deleteConfirmationMessage)
            }
        }
    }

    private var deleteConfirmationBinding: Binding<Bool> {
        Binding(
            get: { !pendingTeaDeleteIDs.isEmpty },
            set: { if !$0 { pendingTeaDeleteIDs = [] } }
        )
    }

    private var deleteConfirmationTitle: String {
        pendingTeaDeleteIDs.count == 1 ? "Delete Tea?" : "Delete Teas?"
    }

    private var deleteConfirmationButtonTitle: String {
        pendingTeaDeleteIDs.count == 1 ? "Delete Tea" : "Delete Teas"
    }

    private var deleteConfirmationMessage: String {
        if pendingTeaDeleteIDs.count == 1,
           let tea = teaStore.customTeas.first(where: { $0.id == pendingTeaDeleteIDs[0] }) {
            return "\(tea.name) will be permanently removed."
        }
        return "The selected tea profiles will be permanently removed."
    }

    private func deletePendingTeas() {
        let ids = pendingTeaDeleteIDs
        pendingTeaDeleteIDs = []
        for id in ids {
            if let tea = teaStore.customTeas.first(where: { $0.id == id }) {
                teaStore.deleteTea(tea)
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
