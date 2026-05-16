import AppIntents
import Foundation

struct TeaEntity: AppEntity, Identifiable {
    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Tea")
    static var defaultQuery = TeaEntityQuery()

    var id: String
    var name: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)")
    }

    var uuid: UUID? {
        UUID(uuidString: id)
    }

    init(id: String, name: String) {
        self.id = id
        self.name = name
    }

    init(tea: Tea) {
        self.id = tea.id.uuidString
        self.name = tea.name
    }
}

struct TeaEntityQuery: EntityStringQuery {
    @MainActor
    func entities(for identifiers: [TeaEntity.ID]) async throws -> [TeaEntity] {
        let store = TeaStore()
        return store.teas
            .filter { identifiers.contains($0.id.uuidString) }
            .map(TeaEntity.init)
    }

    @MainActor
    func entities(matching string: String) async throws -> [TeaEntity] {
        let store = TeaStore()
        guard !string.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return store.favoriteTeas.map(TeaEntity.init)
        }

        return store.teas
            .filter { $0.name.localizedCaseInsensitiveContains(string) }
            .sorted { $0.name < $1.name }
            .map(TeaEntity.init)
    }

    @MainActor
    func suggestedEntities() async throws -> [TeaEntity] {
        TeaStore().favoriteTeas.map(TeaEntity.init)
    }

    @MainActor
    func defaultResult() async -> TeaEntity? {
        TeaStore().favoriteTeas.first.map(TeaEntity.init)
    }
}
