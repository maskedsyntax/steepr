import Foundation
import Combine

final class TeaStore: ObservableObject {
    @Published private(set) var teas: [Tea] = []
    @Published var preferences: UserPreferences = .defaults {
        didSet {
            savePreferences()
            publishSharedState()
        }
    }

    private let fileManager = FileManager.default
    private let teasFileName = "teas.json"
    private let preferencesFileName = "preferences.json"

    init() {
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
        guard fileManager.fileExists(atPath: teasURL.path) else { return }
        do {
            let data = try Data(contentsOf: teasURL)
            teas = try JSONDecoder().decode([Tea].self, from: data)
        } catch {
            print("Failed to load teas: \(error)")
        }
    }

    private func saveTeas() {
        do {
            let data = try JSONEncoder().encode(teas)
            try data.write(to: teasURL, options: .atomic)
        } catch {
            print("Failed to save teas: \(error)")
        }
    }

    private func loadPreferences() {
        guard fileManager.fileExists(atPath: preferencesURL.path) else { return }
        do {
            let data = try Data(contentsOf: preferencesURL)
            preferences = try JSONDecoder().decode(UserPreferences.self, from: data)
        } catch {
            print("Failed to load preferences: \(error)")
        }
    }

    private func savePreferences() {
        do {
            let data = try JSONEncoder().encode(preferences)
            try data.write(to: preferencesURL, options: .atomic)
        } catch {
            print("Failed to save preferences: \(error)")
        }
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
