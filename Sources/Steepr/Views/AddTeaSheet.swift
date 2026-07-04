import SwiftUI

struct AddTeaSheet: View {
    @EnvironmentObject private var teaStore: TeaStore
    @Environment(\.dismiss) private var dismiss

    var editingTea: Tea?

    @State private var name: String
    @State private var symbolName: String
    @State private var colorSlot: TeaColorSlot
    @State private var steepSeconds: Int
    @State private var temperatureCelsius: Int
    @State private var notes: String

    private let symbolOptions = [
        TeaSymbolOption(name: "Leaf", symbolName: "leaf.fill"),
        TeaSymbolOption(name: "Cup", symbolName: "cup.and.saucer.fill"),
        TeaSymbolOption(name: "Heat", symbolName: "flame.fill"),
        TeaSymbolOption(name: "Steam", symbolName: "cloud.fill"),
        TeaSymbolOption(name: "Herbal", symbolName: "camera.macro"),
        TeaSymbolOption(name: "Aromatic", symbolName: "sparkles"),
        TeaSymbolOption(name: "Mountain", symbolName: "mountain.2.fill"),
        TeaSymbolOption(name: "Matcha", symbolName: "circle.hexagongrid.fill"),
        TeaSymbolOption(name: "Water", symbolName: "drop.fill"),
        TeaSymbolOption(name: "Morning", symbolName: "sun.max.fill"),
        TeaSymbolOption(name: "Evening", symbolName: "moon.fill"),
        TeaSymbolOption(name: "Favorite", symbolName: "heart.fill"),
        TeaSymbolOption(name: "Classic", symbolName: "seal.fill"),
        TeaSymbolOption(name: "Temperature", symbolName: "thermometer.medium"),
        TeaSymbolOption(name: "Timer", symbolName: "timer")
    ]

    init(editingTea: Tea? = nil) {
        self.editingTea = editingTea
        _name = State(initialValue: editingTea?.name ?? "")
        _symbolName = State(initialValue: editingTea?.symbolName ?? "leaf.fill")
        _colorSlot = State(initialValue: editingTea?.colorSlot ?? .customA)
        _steepSeconds = State(initialValue: editingTea?.steepSeconds ?? 180)
        _temperatureCelsius = State(initialValue: editingTea?.temperatureCelsius ?? 85)
        _notes = State(initialValue: editingTea?.notes ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Tea") {
                    TextField("Name", text: $name)
                        #if os(iOS)
                        .textInputAutocapitalization(.words)
                        #endif

                    Picker("Symbol", selection: $symbolName) {
                        ForEach(symbolOptions) { option in
                            Label(option.name, systemImage: option.symbolName)
                                .tag(option.symbolName)
                        }
                    }

                    Picker("Color", selection: $colorSlot) {
                        ForEach(TeaColorSlot.allCases) { slot in
                            HStack {
                                Circle()
                                    .fill(slot.color)
                                    .frame(width: 14, height: 14)
                                Text(slot.name)
                            }
                            .tag(slot)
                        }
                    }
                }

                Section("Brewing") {
                    Stepper(value: $steepSeconds, in: 15...900, step: 15) {
                        LabeledContent("Steep duration", value: formatDuration(steepSeconds))
                    }

                    Stepper(value: $temperatureCelsius, in: 60...100, step: 1) {
                        LabeledContent("Temperature", value: formatTemperature(temperatureCelsius, useCelsius: teaStore.preferences.useCelsius))
                    }
                }

                Section("Notes") {
                    TextField("Optional", text: $notes, axis: .vertical)
                        .lineLimit(2...4)
                }
            }
            .navigationTitle(editingTea == nil ? "Add Tea" : "Edit Tea")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(!isValid)
                }
            }
        }
    }

    private var isValid: Bool {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return (1...30).contains(trimmedName.count)
    }

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        var tea = editingTea ?? Tea(
            name: trimmedName,
            symbolName: symbolName,
            colorSlot: colorSlot,
            steepSeconds: steepSeconds,
            temperatureCelsius: temperatureCelsius
        )

        tea.name = trimmedName
        tea.symbolName = symbolName
        tea.colorSlot = colorSlot
        tea.steepSeconds = steepSeconds
        tea.temperatureCelsius = temperatureCelsius
        tea.notes = notes

        if editingTea == nil {
            teaStore.addCustomTea(tea)
        } else {
            teaStore.updateTea(tea)
        }
        dismiss()
    }
}

private struct TeaSymbolOption: Identifiable {
    let name: String
    let symbolName: String

    var id: String { symbolName }
}
