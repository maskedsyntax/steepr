import SwiftUI

struct ProfileEditView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var store: ProfileStore
    
    @State var profile: Profile
    @State private var showingAddStep = false
    @State private var newStepName = ""
    @State private var newStepDuration: TimeInterval = 60
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Profile Name") {
                    TextField("Name", text: $profile.name)
                }
                
                Section("Steps") {
                    ForEach($profile.steps) { $step in
                        VStack(alignment: .leading) {
                            TextField("Step Name", text: $step.name)
                                .font(.headline)
                            HStack {
                                Text("Duration:")
                                TextField("Seconds", value: $step.duration, format: .number)
                                    .textFieldStyle(.roundedBorder)
                                    .frame(width: 60)
                                Text("sec")
                                Spacer()
                            }
                        }
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
                }
            }
            .navigationTitle(profile.name.isEmpty ? "New Profile" : "Edit Profile")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if store.profiles.contains(where: { $0.id == profile.id }) {
                            store.updateProfile(profile)
                        } else {
                            store.addProfile(profile)
                        }
                        dismiss()
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingAddStep) {
                VStack(spacing: 20) {
                    Text("Add New Step")
                        .font(.headline)
                    
                    TextField("Step Name", text: $newStepName)
                        .textFieldStyle(.roundedBorder)
                    
                    Stepper(value: $newStepDuration, in: 0...3600, step: 10) {
                        Text("Duration: \(Int(newStepDuration))s")
                    }
                    
                    HStack {
                        Button("Cancel") {
                            showingAddStep = false
                        }
                        Spacer()
                        Button("Add") {
                            let step = Step(name: newStepName, duration: newStepDuration)
                            profile.steps.append(step)
                            newStepName = ""
                            newStepDuration = 60
                            showingAddStep = false
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(newStepName.isEmpty)
                    }
                }
                .padding()
                .frame(width: 300)
            }
        }
    }
}
