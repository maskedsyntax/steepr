import SwiftUI

struct TeaDetailView: View {
    @EnvironmentObject private var teaStore: TeaStore
    @Environment(\.dismiss) private var dismiss

    let tea: Tea
    @ObservedObject var timerCoordinator: TimerCoordinator
    @Binding var selectedTab: Int

    @State private var showingEdit = false
    @State private var showingPaywall = false
    @State private var showingFavoriteLimit = false
    @State private var showingDeleteConfirmation = false

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
                        .foregroundStyle(SteeprPalette.ink)
                        .multilineTextAlignment(.center)

                    TeaMetaLine(tea: currentTea, useCelsius: teaStore.preferences.useCelsius)

                    if !currentTea.notes.isEmpty {
                        Text(currentTea.notes)
                            .font(.body)
                            .foregroundStyle(SteeprPalette.inkSecondary)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: 420)
                    }
                }

                brewStepsPreview

                VStack(spacing: 12) {
                    Button {
                        timerCoordinator.start(currentTea, preferences: teaStore.preferences)
                        selectedTab = 0
                    } label: {
                        Label("Brew now", systemImage: "play.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(SteeprPalette.accentSolid)
                    .controlSize(.large)

                    Button {
                        showingEdit = true
                    } label: {
                        Label("Edit Tea Profile", systemImage: "slider.horizontal.3")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .tint(SteeprPalette.accent)

                    Button {
                        if !currentTea.isFavorite && teaStore.favoriteTeas.count >= 6 {
                            showingFavoriteLimit = true
                            return
                        }
                        teaStore.toggleFavorite(currentTea)
                    } label: {
                        Label(
                            currentTea.isFavorite ? "Remove from Favorites" : "Add to Favorites",
                            systemImage: currentTea.isFavorite ? "star.slash" : "star"
                        )
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)

                    if !currentTea.isBuiltIn {
                        Button(role: .destructive) {
                            showingDeleteConfirmation = true
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
        .background(SteeprPalette.background.ignoresSafeArea())
        .navigationTitle(currentTea.name)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .sheet(isPresented: $showingEdit) {
            EditTeaProfileView(
                editingTea: currentTea,
                defaultSteepSeconds: teaStore.preferences.defaultSteepSeconds
            )
        }
        .sheet(isPresented: $showingPaywall) {
            PaywallView(trigger: "Custom teas")
        }
        .alert("Favorite limit reached", isPresented: $showingFavoriteLimit) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Keep up to six favorites for quick brewing.")
        }
        .alert("Delete \(currentTea.name)?", isPresented: $showingDeleteConfirmation) {
            Button("Delete Tea", role: .destructive) {
                teaStore.deleteTea(currentTea)
                dismiss()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This tea profile will be permanently removed.")
        }
    }

    private var brewStepsPreview: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("BREW STEPS")
                .font(.caption.weight(.semibold))
                .tracking(0.8)
                .foregroundStyle(SteeprPalette.inkSecondary)

            ForEach(Array(currentTea.brewSteps.enumerated()), id: \.element.id) { index, step in
                HStack(spacing: 12) {
                    Text("\(index + 1)")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(SteeprPalette.inkSecondary)
                        .frame(width: 24, height: 24)
                        .background(Circle().fill(SteeprPalette.controlFill))

                    Image(systemName: step.symbolName)
                        .foregroundStyle(currentTea.colorSlot.color)
                        .frame(width: 22)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(step.name)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(SteeprPalette.ink)
                        if !step.detail.isEmpty {
                            Text(step.detail)
                                .font(.caption)
                                .foregroundStyle(SteeprPalette.inkSecondary)
                        }
                    }

                    Spacer()

                    if let seconds = step.durationSeconds, seconds > 0 {
                        Text(String(format: "%d:%02d", seconds / 60, seconds % 60))
                            .font(.subheadline.weight(.semibold).monospacedDigit())
                            .foregroundStyle(SteeprPalette.ink)
                    } else {
                        Text("—")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(SteeprPalette.inkSecondary)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(SteeprPalette.surface)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(SteeprPalette.controlStroke.opacity(0.7), lineWidth: 1)
                }
            }
        }
        .frame(maxWidth: 420)
    }
}
