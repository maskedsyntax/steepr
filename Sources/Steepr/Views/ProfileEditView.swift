import SwiftUI

#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

struct ProfileEditView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var store: ProfileStore
    
    @State var profile: Profile
    @State private var showingAddStep = false
    @State private var newStepName = ""
    @State private var newStepDuration: TimeInterval = 60
    @State private var newStepTemperature: Double?
    @State private var newStepTemperatureUnit: TemperatureUnit = .celsius
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Form {
                    Section {
                        TextField("Profile Name", text: $profile.name)
                            #if os(macOS)
                            .textFieldStyle(.roundedBorder)
                            #endif
                    } header: {
                        Text("Profile Details")
                    }
                    
                    Section {
                        List {
                            ForEach($profile.steps) { $step in
                                VStack(alignment: .leading, spacing: 8) {
                                    TextField("Step Name", text: $step.name)
                                        .textFieldStyle(.plain)
                                        .font(.body.bold())
                                    
                                    HStack {
                                        Text("Duration")
                                            .foregroundColor(.secondary)
                                        Spacer()
                                        TextField("Seconds", value: $step.duration, format: .number)
                                            #if os(macOS)
                                            .textFieldStyle(.roundedBorder)
                                            #endif
                                            .frame(width: 60)
                                        Text("sec")
                                    }
                                    
                                    HStack {
                                        Text("Temperature")
                                            .foregroundColor(.secondary)
                                        Spacer()
                                        if let _ = step.temperature {
                                            TextField("Temp", value: $step.temperature, format: .number)
                                                #if os(macOS)
                                                .textFieldStyle(.roundedBorder)
                                                #endif
                                                .frame(width: 60)
                                            Picker("", selection: $step.temperatureUnit) {
                                                ForEach(TemperatureUnit.allCases, id: \.self) { unit in
                                                    Text(unit.rawValue).tag(unit)
                                                }
                                            }
                                            .pickerStyle(.segmented)
                                            .frame(width: 80)
                                            
                                            Button {
                                                step.temperature = nil
                                            } label: {
                                                Image(systemName: "xmark.circle.fill")
                                                    .foregroundColor(.secondary)
                                            }
                                            .buttonStyle(.plain)
                                        } else {
                                            Button("Add Temperature") {
                                                step.temperature = 90
                                            }
                                            .buttonStyle(.borderless)
                                        }
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                            .onDelete { indices in
                                profile.steps.remove(atOffsets: indices)
                            }
                            .onMove { from, to in
                                profile.steps.move(fromOffsets: from, toOffset: to)
                            }
                            
                            Button(action: { showingAddStep = true }) {
                                Label("Add Step", systemImage: "plus.circle")
                            }
                            .buttonStyle(.plain)
                            .padding(.vertical, 8)
                            .foregroundColor(.blue)
                        }
                        .frame(minHeight: 200)
                    } header: {
                        Text("Steps")
                    }
                }
                .formStyle(.grouped)
                
                #if os(macOS)
                HStack {
                    Button("Cancel") {
                        dismiss()
                    }
                    .keyboardShortcut(.cancelAction)
                    
                    Spacer()
                    
                    Button("Save") {
                        save()
                    }
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.defaultAction)
                    .disabled(profile.name.isEmpty || profile.steps.isEmpty)
                }
                .padding()
                #if os(macOS)
                .background(Color(NSColor.windowBackgroundColor))
                #else
                .background(Color(UIColor.systemBackground))
                #endif
                #endif
            }
            .navigationTitle(profile.name.isEmpty ? "New Profile" : "Edit Profile")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                    .disabled(profile.name.isEmpty || profile.steps.isEmpty)
                }
            }
            #endif
            #if os(macOS)
            .frame(width: 450, height: 600)
            #endif
        }
        .sheet(isPresented: $showingAddStep) {
            NavigationStack {
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Step Name")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextField("e.g., Steep, Cool Down", text: $newStepName)
                            #if os(macOS)
                            .textFieldStyle(.roundedBorder)
                            #endif
                    }
                    
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Duration")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        HStack {
                            Stepper(value: $newStepDuration, in: 0...3600, step: 10) {
                                Text("\(Int(newStepDuration)) seconds")
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 5) {
                        Text("Temperature (Optional)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        HStack {
                            if let _ = newStepTemperature {
                                TextField("Temp", value: $newStepTemperature, format: .number)
                                    #if os(macOS)
                                    .textFieldStyle(.roundedBorder)
                                    #endif
                                    .frame(width: 60)
                                Picker("", selection: $newStepTemperatureUnit) {
                                    ForEach(TemperatureUnit.allCases, id: \.self) { unit in
                                        Text(unit.rawValue).tag(unit)
                                    }
                                }
                                .pickerStyle(.segmented)
                                .frame(width: 100)
                                
                                Button {
                                    newStepTemperature = nil
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.secondary)
                                }
                                .buttonStyle(.plain)
                            } else {
                                Button("Add Temperature") {
                                    newStepTemperature = 90
                                }
                                .buttonStyle(.borderless)
                            }
                        }
                    }
                    
                    #if os(macOS)
                    HStack {
                        Button("Cancel") {
                            showingAddStep = false
                        }
                        Spacer()
                        Button("Add") {
                            addStep()
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(newStepName.isEmpty)
                    }
                    #endif
                    
                    Spacer()
                }
                .padding()
                .navigationTitle("Add New Step")
                #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { showingAddStep = false }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Add") { addStep() }
                        .disabled(newStepName.isEmpty)
                    }
                }
                #endif
                #if os(macOS)
                .frame(width: 300, height: 250)
                #endif
            }
        }
    }
    
    private func save() {
        if store.profiles.contains(where: { $0.id == profile.id }) {
            store.updateProfile(profile)
        } else {
            store.addProfile(profile)
        }
        dismiss()
    }
    
    private func addStep() {
        let step = Step(name: newStepName, duration: newStepDuration, temperature: newStepTemperature, temperatureUnit: newStepTemperatureUnit)
        profile.steps.append(step)
        newStepName = ""
        newStepDuration = 60
        newStepTemperature = nil
        showingAddStep = false
    }
}

#if os(macOS)
typealias UIColor = NSColor
#endif
