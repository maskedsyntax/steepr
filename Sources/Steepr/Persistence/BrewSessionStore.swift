import Combine
import Foundation
import SwiftData

final class BrewSessionStore: ObservableObject {
    @Published private(set) var sessions: [BrewSession] = []

    private let fileManager = FileManager.default
    private let fileName: String
    private var modelContext: ModelContext
    private let legacyDirectory: URL?
    @Published private(set) var isCloudSyncEnabled = false

    init(
        fileName: String = "brew-sessions.json",
        modelContainer: ModelContainer = SteeprModelContainer.shared,
        legacyDirectory: URL? = nil
    ) {
        self.fileName = fileName
        self.modelContext = ModelContext(modelContainer)
        self.legacyDirectory = legacyDirectory
        migrateLegacyJSONIfNeeded()
        loadSessions()
    }

    var recentSessions: [BrewSession] {
        sessions.sorted { $0.startedAt > $1.startedAt }
    }

    func recordCompletion(sessionID: UUID, tea: Tea, startedAt: Date, durationSeconds: Int) {
        guard !sessions.contains(where: { $0.id == sessionID }) else { return }
        sessions.append(
            BrewSession(
                id: sessionID,
                teaID: tea.id,
                teaSnapshotName: tea.name,
                startedAt: startedAt,
                completedAt: Date(),
                actualSteepSeconds: durationSeconds
            )
        )
        saveSessions()
    }

    func recordCancellation(sessionID: UUID, tea: Tea, startedAt: Date, elapsedSeconds: Int) {
        guard !sessions.contains(where: { $0.id == sessionID }) else { return }
        sessions.append(
            BrewSession(
                id: sessionID,
                teaID: tea.id,
                teaSnapshotName: tea.name,
                startedAt: startedAt,
                cancelledAt: Date(),
                actualSteepSeconds: elapsedSeconds
            )
        )
        saveSessions()
    }

    func deleteSessions(at offsets: IndexSet) {
        let sortedSessions = recentSessions
        let idsToDelete = offsets.map { sortedSessions[$0].id }
        sessions.removeAll { idsToDelete.contains($0.id) }
        saveSessions()
    }

    func enableCloudSyncIfNeeded() {
        guard !isCloudSyncEnabled else { return }
        let localSessions = sessions
        let cloudContainer = SteeprModelContainer.make(cloudKitEnabled: true)

        modelContext = ModelContext(cloudContainer)
        isCloudSyncEnabled = true
        loadSessions()

        sessions = merge(current: sessions, incoming: localSessions)
        saveSessions()
    }

    private var sessionsURL: URL {
        if let legacyDirectory {
            if !fileManager.fileExists(atPath: legacyDirectory.path) {
                try? fileManager.createDirectory(at: legacyDirectory, withIntermediateDirectories: true)
            }
            return legacyDirectory.appendingPathComponent(fileName)
        }

        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let directory = appSupport.appendingPathComponent("Steepr", isDirectory: true)
        if !fileManager.fileExists(atPath: directory.path) {
            try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        }
        return directory.appendingPathComponent(fileName)
    }

    private func loadSessions() {
        do {
            let models = try modelContext.fetch(FetchDescriptor<PersistentBrewSession>())
            sessions = models.map(\.session)
        } catch {
            print("Failed to load brew sessions: \(error)")
        }
    }

    private func saveSessions() {
        do {
            let existing = try modelContext.fetch(FetchDescriptor<PersistentBrewSession>())
            let currentIDs = Set(sessions.map(\.id))

            for session in sessions {
                if let model = existing.first(where: { $0.id == session.id }) {
                    model.apply(session)
                } else {
                    modelContext.insert(PersistentBrewSession(session: session))
                }
            }

            for model in existing where !currentIDs.contains(model.id) {
                modelContext.delete(model)
            }
            try modelContext.save()
        } catch {
            print("Failed to save brew sessions: \(error)")
        }
    }

    private func migrateLegacyJSONIfNeeded() {
        do {
            guard try modelContext.fetchCount(FetchDescriptor<PersistentBrewSession>()) == 0 else { return }
            guard fileManager.fileExists(atPath: sessionsURL.path) else { return }
            let data = try Data(contentsOf: sessionsURL)
            let legacySessions = try JSONDecoder().decode([BrewSession].self, from: data)
            for session in legacySessions {
                modelContext.insert(PersistentBrewSession(session: session))
            }
            try modelContext.save()
        } catch {
            print("Failed to migrate legacy brew sessions: \(error)")
        }
    }

    private func merge(current: [BrewSession], incoming: [BrewSession]) -> [BrewSession] {
        var mergedByID = Dictionary(uniqueKeysWithValues: current.map { ($0.id, $0) })
        for session in incoming {
            mergedByID[session.id] = session
        }
        return Array(mergedByID.values)
    }
}
