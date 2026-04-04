import SwiftUI

struct ProfileEditView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var store: ProfileStore
    
    @State var profile: Profile
    @State private var showingAddStep = false
    @State private var newStepName = ""
    @State private var newStepDuration: TimeInterval = 60
    
    var body: some View {
        VStack(spacing: 0) {
            Text(profile.name.isEmpty ? "New Profile" : "Edit Profile")
                .font(.headline)
                .padding()
            
            Form {
                Section {
                    TextField("Profile Name", text: $profile.name)
                        .textFieldStyle(.roundedBorder)
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
                                        .textFieldStyle(.roundedBorder)
                                        .frame(width: 60)
                                    Text("sec")
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
                    .listStyle(.plain)
                    .frame(minHeight: 200)
                } header: {
                    Text("Steps")
                }
            }
            .formStyle(.grouped)
            
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
                
                Spacer()
                
                Button("Save") {
                    if store.profiles.contains(where: { $0.id == profile.id }) {
                        store.updateProfile(profile)
                    } else {
                        store.addProfile(profile)
                    }
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
                .disabled(profile.name.isEmpty || profile.steps.isEmpty)
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))
        }
        .frame(width: 450, height: 600)
        .sheet(isPresented: $showingAddStep) {
            VStack(spacing: 20) {
                Text("Add New Step")
                    .font(.headline)
                
                VStack(alignment: .leading, spacing: 5) {
                    Text("Step Name")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    TextField("e.g., Steep, Cool Down", text: $newStepName)
                        .textFieldStyle(.roundedBorder)
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
