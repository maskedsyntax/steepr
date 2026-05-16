import SwiftUI

struct ProfileListView: View {
    @EnvironmentObject var store: ProfileStore
    @Binding var selectedProfile: Profile?
    
    @State private var profileToEdit: Profile?
    @State private var showingGuide = false
    @State private var showingHistory = false
    
    var body: some View {
        List(selection: $selectedProfile) {
            Section("Tea Profiles") {
                ForEach(store.profiles) { profile in
                    NavigationLink(value: profile) {
                        HStack {
                            Image(systemName: "leaf.fill")
                                .foregroundColor(.green)
                                .frame(width: 20)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(profile.name)
                                    .font(.body)
                                HStack {
                                    Text("\(formattedTotalDuration(profile.totalDuration))")
                                    if let firstTemp = profile.steps.first?.formattedTemperature, !firstTemp.isEmpty {
                                        Text("•")
                                        Text(firstTemp)
                                    }
                                }
                                .font(.caption)
                                .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                    .contextMenu {
                        Button {
                            profileToEdit = profile
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                        
                        Button(role: .destructive) {
                            if let index = store.profiles.firstIndex(where: { $0.id == profile.id }) {
                                store.deleteProfile(at: IndexSet(integer: index))
                            }
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
                .onDelete(perform: store.deleteProfile)
            }
        }
        .listStyle(.sidebar)
        .toolbar {
            ToolbarItemGroup {
                Button {
                    showingGuide = true
                } label: {
                    Label("Tea Guide", systemImage: "info.circle")
                }
                
                Button {
                    showingHistory = true
                } label: {
                    Label("History", systemImage: "clock.arrow.circlepath")
                }
            }
        }
        .sheet(item: $profileToEdit) { profile in
            ProfileEditView(profile: profile)
        }
        .sheet(isPresented: $showingGuide) {
            TeaGuideView()
        }
        .sheet(isPresented: $showingHistory) {
            HistoryView()
        }
    }
    
    private func formattedTotalDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        if minutes > 0 {
            return "\(minutes)m \(seconds)s"
        } else {
            return "\(seconds)s"
        }
    }
}
