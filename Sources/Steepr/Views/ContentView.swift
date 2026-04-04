import SwiftUI

struct ContentView: View {
    @EnvironmentObject var store: ProfileStore
    @StateObject private var sessionViewModel = SessionViewModel()
    @State private var selectedProfile: Profile?
    @State private var showingAddProfile = false
    
    var body: some View {
        NavigationView {
            VStack {
                ProfileListView(selectedProfile: $selectedProfile)
                
                Divider()
                
                Button(action: { showingAddProfile = true }) {
                    Label("Add Profile", systemImage: "plus")
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
                    .onAppear {
                        sessionViewModel.start(with: profile)
                    }
                } else {
                    VStack(spacing: 20) {
                        Image(systemName: "timer")
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
        .sheet(isPresented: $showingAddProfile) {
            ProfileEditView(profile: Profile(name: "", steps: []))
        }
    }
}
