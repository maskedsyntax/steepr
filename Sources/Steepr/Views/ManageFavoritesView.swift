import SwiftUI

struct ManageFavoritesView: View {
    @EnvironmentObject private var teaStore: TeaStore

    var body: some View {
        List {
            Section("Favorites") {
                ForEach(teaStore.favoriteTeas) { tea in
                    HStack {
                        TeaIconView(tea: tea, size: 36)
                        Text(tea.name)
                    }
                }
                .onMove(perform: teaStore.moveFavorite)
            }

            Section {
                Text("The first six favorites appear on Brew and Apple Watch.")
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Favorites")
        #if os(iOS)
        .toolbar {
            EditButton()
        }
        #endif
    }
}
