import SwiftUI

/// Multi-step tea profile editor matching the product mock (light + dark).
struct EditTeaProfileView: View {
    @EnvironmentObject private var teaStore: TeaStore
    @Environment(\.dismiss) private var dismiss

    var editingTea: Tea?

    @State private var name: String
    @State private var symbolName: String
    @State private var colorSlot: TeaColorSlot
    @State private var notes: String
    @State private var steps: [BrewStep]
    @State private var selectedStepID: BrewStep.ID?
    @State private var pendingStepDeleteID: BrewStep.ID?
    /// Steps that existed when the editor opened — these cannot be deleted.
    @State private var protectedStepIDs: Set<BrewStep.ID>
    @State private var isEditingName = false
    @State private var isEditingNotes = false
    @FocusState private var focusedField: Field?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private enum Field {
        case name
        case notes
        case stepName
        case stepDetail
    }

    private let symbolOptions = [
        "leaf.fill", "cup.and.saucer.fill", "flame.fill", "cloud.fill",
        "camera.macro", "sparkles", "mountain.2.fill", "circle.hexagongrid.fill",
        "drop.fill", "sun.max.fill", "moon.fill", "heart.fill",
        "seal.fill", "thermometer.medium", "timer"
    ]

    init(editingTea: Tea? = nil, defaultSteepSeconds: Int = 180) {
        self.editingTea = editingTea
        let steep = editingTea?.steepSeconds ?? defaultSteepSeconds
        let temp = editingTea?.temperatureCelsius ?? 85
        let slot = editingTea?.colorSlot ?? .customA
        _name = State(initialValue: editingTea?.name ?? "")
        _symbolName = State(initialValue: editingTea?.symbolName ?? "leaf.fill")
        _colorSlot = State(initialValue: slot)
        _notes = State(initialValue: editingTea?.notes ?? "")
        let initialSteps = editingTea?.brewSteps
            ?? Tea.defaultSteps(steepSeconds: steep, temperatureCelsius: temp, colorSlot: slot)
        _steps = State(initialValue: initialSteps)
        _protectedStepIDs = State(initialValue: Set(initialSteps.map(\.id)))
        // Don't auto-select a step on open — avoids an expanded panel on first paint.
        _selectedStepID = State(initialValue: nil)
    }

    private var selectionAnimation: Animation? {
        reduceMotion ? nil : .smooth(duration: 0.28)
    }

    private func canDeleteStep(_ step: BrewStep) -> Bool {
        !protectedStepIDs.contains(step.id)
    }

    private var useCelsius: Bool {
        teaStore.preferences.useCelsius
    }

    private var totalSeconds: Int {
        steps.compactMap(\.durationSeconds).reduce(0, +)
    }

    private var isValid: Bool {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return (1...40).contains(trimmed.count) && !steps.isEmpty
    }

    private var selectedIndex: Int? {
        guard let selectedStepID else { return nil }
        return steps.firstIndex(where: { $0.id == selectedStepID })
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 22) {
                    headerIdentity
                    brewStepsSection
                    addStepButton
                    totalBrewTimeCard
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 36)
                .frame(maxWidth: 560)
                .frame(maxWidth: .infinity)
            }
            .background(SteeprPalette.background.ignoresSafeArea())
            .navigationTitle(editingTea == nil ? "New Tea Profile" : "Edit Tea Profile")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(SteeprPalette.accent)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .fontWeight(.semibold)
                        .foregroundStyle(isValid ? SteeprPalette.accent : SteeprPalette.inkSecondary)
                        .disabled(!isValid)
                }
            }
            #if os(iOS)
            .toolbarBackground(SteeprPalette.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            #endif
            .scrollDismissesKeyboard(.interactively)
            .confirmationDialog(
                "Delete step?",
                isPresented: Binding(
                    get: { pendingStepDeleteID != nil },
                    set: { if !$0 { pendingStepDeleteID = nil } }
                ),
                titleVisibility: .visible
            ) {
                Button("Delete Step", role: .destructive) {
                    if let pendingStepDeleteID {
                        deleteStep(id: pendingStepDeleteID)
                    }
                    pendingStepDeleteID = nil
                }
                Button("Cancel", role: .cancel) {
                    pendingStepDeleteID = nil
                }
            } message: {
                Text("This removes the step from this tea profile.")
            }
        }
    }

    // MARK: - Header

    private var headerIdentity: some View {
        VStack(spacing: 12) {
            Menu {
                ForEach(symbolOptions, id: \.self) { symbol in
                    Button {
                        symbolName = symbol
                    } label: {
                        Label(symbol.replacingOccurrences(of: ".fill", with: "").capitalized, systemImage: symbol)
                    }
                }
                Divider()
                ForEach(TeaColorSlot.allCases) { slot in
                    Button {
                        colorSlot = slot
                    } label: {
                        Label(slot.name, systemImage: colorSlot == slot ? "checkmark.circle.fill" : "circle.fill")
                    }
                }
            } label: {
                ZStack {
                    Circle()
                        .fill(colorSlot.color.opacity(0.16))
                        .frame(width: 76, height: 76)
                    Image(systemName: symbolName)
                        .font(.system(size: 32, weight: .medium))
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(colorSlot.color)
                }
            }
            .accessibilityLabel("Tea icon and color")

            VStack(spacing: 6) {
                HStack(spacing: 8) {
                    if isEditingName {
                        TextField("Tea name", text: $name)
                            .font(.title2.weight(.semibold))
                            .foregroundStyle(SteeprPalette.ink)
                            .multilineTextAlignment(.center)
                            .focused($focusedField, equals: .name)
                            #if os(iOS)
                            .textInputAutocapitalization(.words)
                            #endif
                            .onSubmit {
                                isEditingName = false
                                focusedField = nil
                            }
                    } else {
                        Text(name.isEmpty ? "Tea name" : name)
                            .font(.title2.weight(.semibold))
                            .foregroundStyle(name.isEmpty ? SteeprPalette.inkSecondary : SteeprPalette.ink)
                            .multilineTextAlignment(.center)
                    }

                    Button {
                        isEditingName = true
                        focusedField = .name
                    } label: {
                        Image(systemName: "pencil")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(SteeprPalette.inkSecondary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Edit tea name")
                }

                if isEditingNotes {
                    TextField("Short description", text: $notes, axis: .vertical)
                        .font(.subheadline)
                        .foregroundStyle(SteeprPalette.inkSecondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(1...3)
                        .focused($focusedField, equals: .notes)
                        .onSubmit {
                            isEditingNotes = false
                            focusedField = nil
                        }
                } else {
                    Button {
                        isEditingNotes = true
                        focusedField = .notes
                    } label: {
                        Text(notes.isEmpty ? "Add a short description" : notes)
                            .font(.subheadline)
                            .foregroundStyle(SteeprPalette.inkSecondary)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: 320)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 4)
    }

    // MARK: - Steps

    private var brewStepsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("BREW STEPS")
                .font(.caption.weight(.semibold))
                .tracking(0.8)
                .foregroundStyle(SteeprPalette.inkSecondary)

            VStack(spacing: 10) {
                ForEach(Array(steps.enumerated()), id: \.element.id) { index, step in
                    expandableStepCard(index: index, step: step)
                }
            }
            // Animate height/layout of the list only when selection changes.
            .animation(selectionAnimation, value: selectedStepID)
        }
    }

    @ViewBuilder
    private func expandableStepCard(index: Int, step: BrewStep) -> some View {
        let isSelected = step.id == selectedStepID
        let removable = canDeleteStep(step)

        VStack(alignment: .leading, spacing: 0) {
            BrewStepRow(
                index: index + 1,
                step: step,
                isSelected: isSelected,
                useCelsius: useCelsius,
                accent: colorSlot.color,
                showsDelete: removable,
                onSelect: {
                    // Toggle closed if already open — no extra bounce from move transitions.
                    if selectedStepID == step.id {
                        selectedStepID = nil
                        focusedField = nil
                    } else {
                        selectedStepID = step.id
                    }
                },
                onDelete: removable ? { requestDeleteStep(id: step.id) } : nil
            )
            .contextMenu {
                Button("Move up", systemImage: "arrow.up") {
                    moveStep(id: step.id, by: -1)
                }
                .disabled(index == 0)

                Button("Move down", systemImage: "arrow.down") {
                    moveStep(id: step.id, by: 1)
                }
                .disabled(index >= steps.count - 1)

                if removable {
                    Button("Delete step", systemImage: "trash", role: .destructive) {
                        requestDeleteStep(id: step.id)
                    }
                }
            }

            if isSelected {
                stepEditor(at: index)
                    // Fade only — avoid slide transitions that fight layout and feel janky.
                    .transition(.opacity)
            }
        }
        .background(SteeprPalette.surface)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(
                    isSelected ? SteeprPalette.temperature.opacity(0.85) : SteeprPalette.controlStroke.opacity(0.75),
                    lineWidth: isSelected ? 1.5 : 1
                )
        }
    }

    private func stepEditor(at index: Int) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Divider()
                .background(SteeprPalette.divider)
                .padding(.horizontal, 14)

            VStack(alignment: .leading, spacing: 6) {
                Text("Step name")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(SteeprPalette.inkSecondary)
                TextField("Name", text: stepNameBinding(at: index))
                    .font(.body.weight(.medium))
                    .foregroundStyle(SteeprPalette.ink)
                    .focused($focusedField, equals: .stepName)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Detail")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(SteeprPalette.inkSecondary)
                TextField("Subtitle", text: stepDetailBinding(at: index))
                    .font(.body.weight(.medium))
                    .foregroundStyle(SteeprPalette.ink)
                    .focused($focusedField, equals: .stepDetail)
            }

            HStack {
                Text("Duration")
                    .font(.body.weight(.medium))
                    .foregroundStyle(SteeprPalette.ink)
                Spacer()
                durationControls(at: index)
            }

            HStack {
                Text("Temperature")
                    .font(.body.weight(.medium))
                    .foregroundStyle(SteeprPalette.ink)
                Spacer()
                temperatureControls(at: index)
            }

            Menu {
                ForEach(symbolOptions, id: \.self) { symbol in
                    Button {
                        steps[index].symbolName = symbol
                    } label: {
                        Label(symbol.replacingOccurrences(of: ".fill", with: "").capitalized, systemImage: symbol)
                    }
                }
            } label: {
                HStack {
                    Text("Icon")
                        .font(.body.weight(.medium))
                        .foregroundStyle(SteeprPalette.ink)
                    Spacer()
                    Image(systemName: steps[index].symbolName)
                        .foregroundStyle(colorSlot.color)
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(SteeprPalette.inkSecondary)
                }
            }

            if canDeleteStep(steps[index]) {
                Button(role: .destructive) {
                    requestDeleteStep(id: steps[index].id)
                } label: {
                    Label("Delete Step", systemImage: "trash")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.red.opacity(0.10))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
                .padding(.top, 2)
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
        .padding(.top, 4)
    }

    private func durationControls(at index: Int) -> some View {
        let seconds = steps[index].durationSeconds
        return HStack(spacing: 10) {
            Button {
                adjustDuration(at: index, delta: -15)
            } label: {
                Image(systemName: "minus")
                    .font(.system(size: 12, weight: .bold))
                    .frame(width: 30, height: 30)
                    .background(SteeprPalette.controlFill)
                    .clipShape(Circle())
                    .foregroundStyle(SteeprPalette.ink)
            }
            .buttonStyle(.plain)

            Text(formatStepClock(seconds))
                .font(.body.weight(.semibold).monospacedDigit())
                .foregroundStyle(seconds == nil ? SteeprPalette.inkSecondary : SteeprPalette.temperature)
                .frame(minWidth: 52)

            Button {
                adjustDuration(at: index, delta: 15)
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 12, weight: .bold))
                    .frame(width: 30, height: 30)
                    .background(SteeprPalette.controlFill)
                    .clipShape(Circle())
                    .foregroundStyle(SteeprPalette.ink)
            }
            .buttonStyle(.plain)

            Button(seconds == nil ? "Timed" : "Clear") {
                if seconds == nil {
                    steps[index].durationSeconds = 60
                } else {
                    steps[index].durationSeconds = nil
                }
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(SteeprPalette.accent)
        }
    }

    private func temperatureControls(at index: Int) -> some View {
        let temp = steps[index].temperatureCelsius
        return HStack(spacing: 10) {
            Button {
                adjustTemperature(at: index, delta: -5)
            } label: {
                Image(systemName: "minus")
                    .font(.system(size: 12, weight: .bold))
                    .frame(width: 30, height: 30)
                    .background(SteeprPalette.controlFill)
                    .clipShape(Circle())
                    .foregroundStyle(SteeprPalette.ink)
            }
            .buttonStyle(.plain)

            Text(temp.map { formatTemperature($0, useCelsius: useCelsius) } ?? "—")
                .font(.body.weight(.semibold).monospacedDigit())
                .foregroundStyle(temp == nil ? SteeprPalette.inkSecondary : SteeprPalette.ink)
                .frame(minWidth: 52)

            Button {
                adjustTemperature(at: index, delta: 5)
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 12, weight: .bold))
                    .frame(width: 30, height: 30)
                    .background(SteeprPalette.controlFill)
                    .clipShape(Circle())
                    .foregroundStyle(SteeprPalette.ink)
            }
            .buttonStyle(.plain)

            Button(temp == nil ? "Set" : "Clear") {
                if temp == nil {
                    steps[index].temperatureCelsius = 80
                    if steps[index].detail.isEmpty {
                        steps[index].detail = formatTemperature(80, useCelsius: useCelsius)
                    }
                } else {
                    steps[index].temperatureCelsius = nil
                }
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(SteeprPalette.accent)
        }
    }

    private var addStepButton: some View {
        Button {
            let step = BrewStep(
                name: "New Step",
                symbolName: "timer",
                detail: "Custom step",
                durationSeconds: 60,
                temperatureCelsius: nil
            )
            // New steps are intentionally not added to protectedStepIDs.
            steps.append(step)
            selectedStepID = step.id
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "plus")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(SteeprPalette.accent)
                    .frame(width: 28, height: 28)
                    .background(SteeprPalette.accent.opacity(0.14))
                    .clipShape(Circle())

                Text("Add Step")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(SteeprPalette.ink)

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(SteeprPalette.surface)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(SteeprPalette.controlStroke.opacity(0.75), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }

    private var totalBrewTimeCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                Image(systemName: "clock")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(SteeprPalette.inkSecondary)
                    .frame(width: 28, height: 28)
                    .background(SteeprPalette.controlFill)
                    .clipShape(Circle())

                Text("Total Brew Time")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(SteeprPalette.inkSecondary)

                Spacer()

                Text("~ \(formatTotal(totalSeconds))")
                    .font(.title3.weight(.semibold).monospacedDigit())
                    .foregroundStyle(SteeprPalette.temperature)
            }

            Text("Time may vary based on conditions and preference.")
                .font(.caption)
                .foregroundStyle(SteeprPalette.inkSecondary)
        }
        .padding(16)
        .background(SteeprPalette.surfaceMuted.opacity(0.85))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    // MARK: - Bindings & actions

    private func stepNameBinding(at index: Int) -> Binding<String> {
        Binding(
            get: { steps[index].name },
            set: { steps[index].name = $0 }
        )
    }

    private func stepDetailBinding(at index: Int) -> Binding<String> {
        Binding(
            get: { steps[index].detail },
            set: { steps[index].detail = $0 }
        )
    }

    private func adjustDuration(at index: Int, delta: Int) {
        let current = steps[index].durationSeconds ?? 0
        if current == 0, delta < 0 {
            steps[index].durationSeconds = nil
            return
        }
        let next = max(0, current + delta)
        steps[index].durationSeconds = next == 0 ? nil : min(900, next)
    }

    private func adjustTemperature(at index: Int, delta: Int) {
        let current = steps[index].temperatureCelsius ?? 80
        let next = min(100, max(50, current + delta))
        steps[index].temperatureCelsius = next
    }

    private func moveStep(id: BrewStep.ID, by offset: Int) {
        guard let index = steps.firstIndex(where: { $0.id == id }) else { return }
        let target = index + offset
        guard steps.indices.contains(target) else { return }
        steps.swapAt(index, target)
    }

    private func requestDeleteStep(id: BrewStep.ID) {
        guard steps.contains(where: { $0.id == id }) else { return }
        guard !protectedStepIDs.contains(id) else { return }
        guard steps.count > 1 else { return }
        pendingStepDeleteID = id
    }

    private func deleteStep(id: BrewStep.ID) {
        // Only user-added steps (not present at open) can be removed.
        guard !protectedStepIDs.contains(id) else { return }
        guard steps.count > 1 else { return }
        steps.removeAll { $0.id == id }
        if selectedStepID == id {
            selectedStepID = nil
            focusedField = nil
        }
    }

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        var tea = editingTea ?? Tea(
            name: trimmedName,
            symbolName: symbolName,
            colorSlot: colorSlot,
            steepSeconds: 180,
            temperatureCelsius: 85
        )

        tea.name = trimmedName
        tea.symbolName = symbolName
        tea.colorSlot = colorSlot
        tea.notes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        tea.steps = steps
        tea.syncTimingFromSteps()

        if editingTea == nil {
            teaStore.addCustomTea(tea)
        } else {
            // Presets and custom teas are both editable in place.
            teaStore.updateTea(tea)
        }
        dismiss()
    }

    private func formatStepClock(_ seconds: Int?) -> String {
        guard let seconds, seconds > 0 else { return "—" }
        return String(format: "%d:%02d", seconds / 60, seconds % 60)
    }

    private func formatTotal(_ seconds: Int) -> String {
        if seconds <= 0 { return "0 min" }
        let minutes = seconds / 60
        let rem = seconds % 60
        if rem == 0 {
            return "\(minutes):00 min"
        }
        return String(format: "%d:%02d min", minutes, rem)
    }
}

// MARK: - Step row

private struct BrewStepRow: View {
    let index: Int
    let step: BrewStep
    let isSelected: Bool
    let useCelsius: Bool
    let accent: Color
    var showsDelete: Bool = false
    let onSelect: () -> Void
    var onDelete: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onSelect) {
                HStack(spacing: 12) {
                    Text("\(index)")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(isSelected ? SteeprPalette.temperature : SteeprPalette.inkSecondary)
                        .frame(width: 26, height: 26)
                        .background(
                            Circle()
                                .fill(isSelected ? SteeprPalette.temperature.opacity(0.16) : SteeprPalette.controlFill)
                        )

                    Image(systemName: step.symbolName)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(isSelected ? SteeprPalette.temperature : accent)
                        .frame(width: 28)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(step.name)
                            .font(.body.weight(.semibold))
                            .foregroundStyle(SteeprPalette.ink)
                            .lineLimit(1)

                        Text(stepSubtitle)
                            .font(.caption)
                            .foregroundStyle(SteeprPalette.inkSecondary)
                            .lineLimit(1)
                    }

                    Spacer(minLength: 8)

                    VStack(alignment: .trailing, spacing: 2) {
                        Text(durationText)
                            .font(.body.weight(.semibold).monospacedDigit())
                            .foregroundStyle(isSelected && step.hasTimer ? SteeprPalette.temperature : SteeprPalette.ink)
                        Text("min")
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(SteeprPalette.inkSecondary)
                    }
                    .frame(minWidth: 48, alignment: .trailing)

                    if !showsDelete {
                        Image(systemName: "line.3.horizontal")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(SteeprPalette.inkSecondary.opacity(0.7))
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(step.name), step \(index)")
            .accessibilityAddTraits(isSelected ? .isSelected : [])

            if showsDelete, let onDelete {
                Button(role: .destructive, action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.red.opacity(0.85))
                        .frame(width: 28, height: 28)
                        .background(Color.red.opacity(0.10))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Delete step")
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        // Background/stroke live on the parent expandable card.
    }

    private var stepSubtitle: String {
        if !step.detail.isEmpty { return step.detail }
        if let temp = step.temperatureCelsius {
            return formatTemperature(temp, useCelsius: useCelsius)
        }
        return " "
    }

    private var durationText: String {
        guard let seconds = step.durationSeconds, seconds > 0 else { return "—" }
        return String(format: "%d:%02d", seconds / 60, seconds % 60)
    }
}
