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
    @State private var caffeineMilligrams: Int
    @State private var includesCaffeine: Bool
    @State private var notes: String

    private let symbols = [
        "leaf.fill", "cup.and.saucer.fill", "flame.fill", "cloud.fill",
        "camera.macro", "sparkles", "mountain.2.fill", "circle.hexagongrid.fill",
        "drop.fill", "sun.max.fill", "moon.fill", "heart.fill",
        "seal.fill", "mug.fill", "thermometer.medium", "timer"
    ]

    init(editingTea: Tea? = nil) {
        self.editingTea = editingTea
        _name = State(initialValue: editingTea?.name ?? "")
        _symbolName = State(initialValue: editingTea?.symbolName ?? "leaf.fill")
        _colorSlot = State(initialValue: editingTea?.colorSlot ?? .customA)
        _steepSeconds = State(initialValue: editingTea?.steepSeconds ?? 180)
        _temperatureCelsius = State(initialValue: editingTea?.temperatureCelsius ?? 85)
        _caffeineMilligrams = State(initialValue: editingTea?.caffeineMilligrams ?? 0)
        _includesCaffeine = State(initialValue: editingTea?.caffeineMilligrams != nil)
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
                        ForEach(symbols, id: \.self) { symbol in
                            Label(symbol, systemImage: symbol).tag(symbol)
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

                    Toggle("Caffeine estimate", isOn: $includesCaffeine)

                    if includesCaffeine {
                        Stepper(value: $caffeineMilligrams, in: 0...150, step: 5) {
                            LabeledContent("Caffeine", value: "\(caffeineMilligrams) mg")
                        }
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
        tea.caffeineMilligrams = includesCaffeine ? caffeineMilligrams : nil
        tea.notes = notes

        if editingTea == nil {
            teaStore.addCustomTea(tea)
        } else {
            teaStore.updateTea(tea)
        }
        dismiss()
    }
}
