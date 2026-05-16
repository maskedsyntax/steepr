import SwiftUI

struct TeaDetailView: View {
    @EnvironmentObject private var teaStore: TeaStore
    @Environment(\.dismiss) private var dismiss

    let tea: Tea
    @ObservedObject var timerCoordinator: TimerCoordinator
    @Binding var selectedTab: Int

    @State private var showingEdit = false
    @State private var showingPaywall = false
    @State private var teaToEdit: Tea?

    private var currentTea: Tea {
        teaStore.tea(with: tea.id) ?? tea
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                TeaIconView(tea: currentTea, size: 104)

                VStack(spacing: 8) {
                    Text(currentTea.name)
                        .font(.largeTitle.bold())
                        .multilineTextAlignment(.center)

                    TeaMetaLine(tea: currentTea, useCelsius: teaStore.preferences.useCelsius)
                }

                if !currentTea.notes.isEmpty {
                    Text(currentTea.notes)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 420)
                }

                VStack(spacing: 12) {
                    Button {
                        timerCoordinator.start(currentTea, preferences: teaStore.preferences)
                        selectedTab = 0
                    } label: {
                        Label("Brew now", systemImage: "play.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)

                    Button {
                        teaStore.toggleFavorite(currentTea)
                    } label: {
                        Label(currentTea.isFavorite ? "Remove from Watch favorites" : "Add to Watch favorites", systemImage: currentTea.isFavorite ? "star.slash" : "star")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)

                    if currentTea.isBuiltIn {
                        Button {
                            guard teaStore.canAddCustomTea else {
                                showingPaywall = true
                                return
                            }
                            let duplicate = teaStore.duplicateBuiltIn(currentTea)
                            teaStore.addCustomTea(duplicate)
                            teaToEdit = duplicate
                            showingEdit = true
                        } label: {
                            Label("Duplicate to My Teas", systemImage: "doc.on.doc")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                    } else {
                        Button {
                            teaToEdit = currentTea
                            showingEdit = true
                        } label: {
                            Label("Edit Tea", systemImage: "pencil")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)

                        Button(role: .destructive) {
                            teaStore.deleteTea(currentTea)
                            dismiss()
                        } label: {
                            Label("Delete Tea", systemImage: "trash")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .frame(maxWidth: 420)
            }
            .padding()
            .frame(maxWidth: .infinity)
        }
        .navigationTitle(currentTea.name)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .sheet(isPresented: $showingEdit) {
            AddTeaSheet(editingTea: teaToEdit)
        }
        .sheet(isPresented: $showingPaywall) {
            PaywallView(trigger: "Custom teas")
        }
    }
}
