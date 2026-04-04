import SwiftUI

struct ContentView: View {
    @EnvironmentObject var store: ProfileStore
    @StateObject private var sessionViewModel = SessionViewModel()
    @State private var selectedProfile: Profile?
    @State private var showingAddProfile = false
    @State private var pendingProfile: Profile?
    @State private var showingSwitchAlert = false
    
    var body: some View {
        NavigationView {
            VStack {
                ProfileListView(selectedProfile: Binding(
                    get: { selectedProfile },
                    set: { newProfile in
                        if let _ = selectedProfile, (sessionViewModel.state == .running || sessionViewModel.state == .paused) {
                            pendingProfile = newProfile
                            showingSwitchAlert = true
                        } else {
                            selectedProfile = newProfile
                            if let profile = newProfile {
                                sessionViewModel.start(with: profile)
                            }
                        }
                    }
                ))
                
                Divider()
                
                Button(action: { showingAddProfile = true }) {
                    Label("Add Profile", systemImage: "plus.circle")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
                .padding(10)
            }
            .frame(minWidth: 200)
            
            Group {
                if let profile = selectedProfile {
                    TimerView(viewModel: sessionViewModel, onDismiss: {
                        sessionViewModel.stop()
                        selectedProfile = nil
                    })
                } else {
                    VStack(spacing: 20) {
                        Image(systemName: "cup.and.saucer.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.secondary)
                        Text("Select a profile to start steeping")
                            .font(.title2)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
        .frame(minWidth: 700, minHeight: 500)
        .alert("Stop current session?", isPresented: $showingSwitchAlert) {
            Button("Stop and Start New", role: .destructive) {
                selectedProfile = pendingProfile
                if let profile = selectedProfile {
                    sessionViewModel.start(with: profile)
                }
                pendingProfile = nil
            }
            Button("Cancel", role: .cancel) {
                pendingProfile = nil
            }
        } message: {
            Text("A timer is already running. Do you want to stop it and start the new one?")
        }
        .sheet(isPresented: $showingAddProfile) {
            ProfileEditView(profile: Profile(name: "", steps: []))
        }
    }
}
