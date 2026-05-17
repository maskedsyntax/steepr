import Foundation
import Combine
import SwiftData

final class TeaStore: ObservableObject {
    @Published private(set) var teas: [Tea] = []
    @Published var preferences: UserPreferences = .defaults {
        didSet {
            savePreferences()
            publishSharedState()
        }
    }
    @Published private(set) var isCloudSyncEnabled = false

    private let fileManager = FileManager.default
    private var modelContext: ModelContext
    private let legacyDirectory: URL?
    private let teasFileName = "teas.json"
    private let preferencesFileName = "preferences.json"

    init(modelContainer: ModelContainer = SteeprModelContainer.shared, legacyDirectory: URL? = nil) {
        self.modelContext = ModelContext(modelContainer)
        self.legacyDirectory = legacyDirectory
        migrateLegacyJSONIfNeeded()
        loadTeas()
        loadPreferences()
        seedBuiltInsIfNeeded()
        normalizeFavoriteRanks()
        publishSharedState()
    }

    var favoriteTeas: [Tea] {
        teas
            .filter(\.isFavorite)
            .sorted { ($0.favoriteRank ?? Int.max, $0.name) < ($1.favoriteRank ?? Int.max, $1.name) }
            .prefix(6)
            .map { $0 }
    }

    var customTeas: [Tea] {
        teas.filter { !$0.isBuiltIn }.sorted { $0.createdAt < $1.createdAt }
    }

    var builtInTeas: [Tea] {
        teas.filter(\.isBuiltIn).sorted { $0.name < $1.name }
    }

    var canAddCustomTea: Bool {
        preferences.proPurchased || customTeas.count < 3
    }

    func tea(with id: Tea.ID) -> Tea? {
        teas.first { $0.id == id }
    }

    func addCustomTea(_ tea: Tea) {
        var newTea = tea
        newTea.isBuiltIn = false
        newTea.createdAt = Date()
        newTea.updatedAt = Date()
        teas.append(newTea)
        saveTeas()
        publishSharedState()
    }

    func updateTea(_ tea: Tea) {
        guard let index = teas.firstIndex(where: { $0.id == tea.id }) else { return }
        var updatedTea = tea
        updatedTea.updatedAt = Date()
        teas[index] = updatedTea
        saveTeas()
        publishSharedState()
    }

    func deleteTea(_ tea: Tea) {
        guard !tea.isBuiltIn else { return }
        teas.removeAll { $0.id == tea.id }
        normalizeFavoriteRanks()
        saveTeas()
        publishSharedState()
    }

    func duplicateBuiltIn(_ tea: Tea) -> Tea {
        Tea(
            name: "\(tea.name) Copy",
            symbolName: tea.symbolName,
            colorSlot: tea.colorSlot,
            steepSeconds: tea.steepSeconds,
            temperatureCelsius: tea.temperatureCelsius,
            caffeineMilligrams: tea.caffeineMilligrams,
            notes: tea.notes,
            isBuiltIn: false
        )
    }

    func toggleFavorite(_ tea: Tea) {
        guard let index = teas.firstIndex(where: { $0.id == tea.id }) else { return }
        if teas[index].isFavorite {
            teas[index].isFavorite = false
            teas[index].favoriteRank = nil
        } else {
            guard favoriteTeas.count < 6 else { return }
            teas[index].isFavorite = true
            teas[index].favoriteRank = nextFavoriteRank()
        }
        normalizeFavoriteRanks()
        saveTeas()
        publishSharedState()
    }

    func moveFavorite(from offsets: IndexSet, to destination: Int) {
        var favorites = favoriteTeas
        favorites.moveItems(fromOffsets: offsets, toOffset: destination)
        for (rank, tea) in favorites.enumerated() {
            guard let index = teas.firstIndex(where: { $0.id == tea.id }) else { continue }
            teas[index].favoriteRank = rank
        }
        saveTeas()
        publishSharedState()
    }

    func setOnboardingComplete(_ complete: Bool) {
        preferences.onboardingComplete = complete
    }

    func save() {
        saveTeas()
        savePreferences()
        publishSharedState()
    }

    func enableCloudSyncIfNeeded() {
        guard !isCloudSyncEnabled else { return }
        let localTeas = teas
        let localPreferences = preferences
        let cloudContainer = SteeprModelContainer.make(cloudKitEnabled: true)

        modelContext = ModelContext(cloudContainer)
        isCloudSyncEnabled = true
        loadTeas()

        let mergedTeas = merge(current: teas, incoming: localTeas)
        teas = mergedTeas
        preferences = localPreferences
        saveTeas()
        savePreferences()
        publishSharedState()
    }

    private func seedBuiltInsIfNeeded() {
        var changed = false
        for builtIn in Tea.builtIns where !teas.contains(where: { $0.isBuiltIn && $0.name == builtIn.name }) {
            teas.append(builtIn)
            changed = true
        }

        if changed {
            saveTeas()
        }
    }

    private func normalizeFavoriteRanks() {
        let favorites = teas
            .filter(\.isFavorite)
            .sorted { ($0.favoriteRank ?? Int.max, $0.name) < ($1.favoriteRank ?? Int.max, $1.name) }

        for (rank, tea) in favorites.enumerated() {
            guard let index = teas.firstIndex(where: { $0.id == tea.id }) else { continue }
            teas[index].favoriteRank = rank
        }
    }

    private func publishSharedState() {
        let generatedAt = Date()
        let favoritesSnapshot = FavoriteTeasSnapshot(generatedAt: generatedAt, teas: favoriteTeas)
        let preferencesSnapshot = UserPreferencesSnapshot(generatedAt: generatedAt, preferences: preferences)

        if let favoritesData = try? JSONEncoder().encode(favoritesSnapshot) {
            AppGroup.userDefaults.set(favoritesData, forKey: FavoriteTeasSnapshot.storageKey)
        }

        if let preferencesData = try? JSONEncoder().encode(preferencesSnapshot) {
            AppGroup.userDefaults.set(preferencesData, forKey: UserPreferencesSnapshot.storageKey)
        }

        WatchSyncService.sync(favorites: favoritesSnapshot, preferences: preferencesSnapshot)
    }

    private func nextFavoriteRank() -> Int {
        (teas.compactMap(\.favoriteRank).max() ?? -1) + 1
    }

    private var appDirectory: URL {
        if let legacyDirectory {
            if !fileManager.fileExists(atPath: legacyDirectory.path) {
                try? fileManager.createDirectory(at: legacyDirectory, withIntermediateDirectories: true)
            }
            return legacyDirectory
        }

        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let directory = appSupport.appendingPathComponent("Steepr", isDirectory: true)
        if !fileManager.fileExists(atPath: directory.path) {
            try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        }
        return directory
    }

    private var teasURL: URL {
        appDirectory.appendingPathComponent(teasFileName)
    }

    private var preferencesURL: URL {
        appDirectory.appendingPathComponent(preferencesFileName)
    }

    private func loadTeas() {
        do {
            let models = try modelContext.fetch(FetchDescriptor<PersistentTea>())
            teas = models.map(\.tea)
        } catch {
            print("Failed to load teas: \(error)")
        }
    }

    private func saveTeas() {
        do {
            let existing = try modelContext.fetch(FetchDescriptor<PersistentTea>())
            var existingByID = Dictionary(uniqueKeysWithValues: existing.map { ($0.id, $0) })
            let currentIDs = Set(teas.map(\.id))

            for tea in teas {
                if let model = existingByID[tea.id] {
                    model.apply(tea)
                } else {
                    modelContext.insert(PersistentTea(tea: tea))
                }
            }

            for model in existing where !currentIDs.contains(model.id) {
                modelContext.delete(model)
            }
            existingByID.removeAll()
            try modelContext.save()
        } catch {
            print("Failed to save teas: \(error)")
        }
    }

    private func loadPreferences() {
        do {
            var descriptor = FetchDescriptor<PersistentUserPreferences>()
            descriptor.fetchLimit = 1
            if let model = try modelContext.fetch(descriptor).first {
                preferences = model.preferences
            }
        } catch {
            print("Failed to load preferences: \(error)")
        }
    }

    private func savePreferences() {
        do {
            let existing = try modelContext.fetch(FetchDescriptor<PersistentUserPreferences>())
            if let model = existing.first {
                model.apply(preferences)
                for duplicate in existing.dropFirst() {
                    modelContext.delete(duplicate)
                }
            } else {
                modelContext.insert(PersistentUserPreferences(preferences: preferences))
            }
            try modelContext.save()
        } catch {
            print("Failed to save preferences: \(error)")
        }
    }

    private func migrateLegacyJSONIfNeeded() {
        do {
            let existingTeaCount = try modelContext.fetchCount(FetchDescriptor<PersistentTea>())
            let existingPreferencesCount = try modelContext.fetchCount(FetchDescriptor<PersistentUserPreferences>())

            if existingTeaCount == 0, fileManager.fileExists(atPath: teasURL.path) {
                let data = try Data(contentsOf: teasURL)
                let legacyTeas = try JSONDecoder().decode([Tea].self, from: data)
                for tea in legacyTeas {
                    modelContext.insert(PersistentTea(tea: tea))
                }
            }

            if existingPreferencesCount == 0, fileManager.fileExists(atPath: preferencesURL.path) {
                let data = try Data(contentsOf: preferencesURL)
                let legacyPreferences = try JSONDecoder().decode(UserPreferences.self, from: data)
                modelContext.insert(PersistentUserPreferences(preferences: legacyPreferences))
            }

            if modelContext.hasChanges {
                try modelContext.save()
            }
        } catch {
            print("Failed to migrate legacy tea data: \(error)")
        }
    }

    private func merge(current: [Tea], incoming: [Tea]) -> [Tea] {
        var mergedByID = Dictionary(uniqueKeysWithValues: current.map { ($0.id, $0) })
        for tea in incoming {
            mergedByID[tea.id] = tea
        }
        return Array(mergedByID.values)
    }
}

private extension Array {
    mutating func moveItems(fromOffsets offsets: IndexSet, toOffset destination: Int) {
        let movingItems = offsets.map { self[$0] }
        remove(atOffsets: offsets)

        let removedBeforeDestination = offsets.filter { $0 < destination }.count
        let adjustedDestination = Swift.max(0, destination - removedBeforeDestination)
        insert(contentsOf: movingItems, at: Swift.min(adjustedDestination, count))
    }

    mutating func remove(atOffsets offsets: IndexSet) {
        for offset in offsets.sorted(by: >) {
            remove(at: offset)
        }
    }
}
