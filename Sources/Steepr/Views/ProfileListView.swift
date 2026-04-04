import SwiftUI

struct ProfileListView: View {
    @EnvironmentObject var store: ProfileStore
    @Binding var selectedProfile: Profile?
    
    @State private var profileToEdit: Profile?
    
    var body: some View {
        List {
            ForEach(store.profiles) { profile in
                HStack {
                    VStack(alignment: .leading) {
                        Text(profile.name)
                            .font(.headline)
                        Text("\(profile.steps.count) steps • \(formattedTotalDuration(profile.totalDuration))")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Button("Edit") {
                        profileToEdit = profile
                    }
                    .buttonStyle(.bordered)
                    
                    Button("Start") {
                        selectedProfile = profile
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(.vertical, 4)
            }
            .onDelete(perform: store.deleteProfile)
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
