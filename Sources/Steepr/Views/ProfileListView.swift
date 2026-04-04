import SwiftUI

struct ProfileListView: View {
    @EnvironmentObject var store: ProfileStore
    @Binding var selectedProfile: Profile?
    
    @State private var profileToEdit: Profile?
    
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
                                Text("\(formattedTotalDuration(profile.totalDuration))")
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
        .sheet(item: $profileToEdit) { profile in
            ProfileEditView(profile: profile)
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
