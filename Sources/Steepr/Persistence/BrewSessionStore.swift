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

    /// Completed sessions ordered by when the tea finished, newest first.
    /// Cancelled sessions are deliberately excluded from repeat-brew suggestions.
    var recentCompletedSessions: [BrewSession] {
        sessions
            .filter { $0.completedAt != nil && $0.cancelledAt == nil }
            .sorted { ($0.completedAt ?? .distantPast) > ($1.completedAt ?? .distantPast) }
    }

    /// Number of sessions that ran to completion. Counts each infusion separately.
    var completedCount: Int {
        sessions.lazy.filter { $0.completedAt != nil }.count
    }

    /// Sessions that ran to completion on the given day, newest first.
    /// Caffeine is resolved by the caller against `TeaStore`, since it lives on the tea
    /// rather than on the session.
    func completedSessions(on day: Date, calendar: Calendar = .current) -> [BrewSession] {
        sessions
            .filter { $0.completedAt.map { calendar.isDate($0, inSameDayAs: day) } ?? false }
            .sorted { $0.startedAt > $1.startedAt }
    }

    func session(with id: BrewSession.ID) -> BrewSession? {
        sessions.first { $0.id == id }
    }

    func recordCompletion(
        sessionID: UUID,
        tea: Tea,
        startedAt: Date,
        durationSeconds: Int,
        infusionNumber: Int = 1
    ) {
        guard !sessions.contains(where: { $0.id == sessionID }) else { return }
        sessions.append(
            BrewSession(
                id: sessionID,
                teaID: tea.id,
                teaSnapshotName: tea.name,
                startedAt: startedAt,
                completedAt: Date(),
                actualSteepSeconds: durationSeconds,
                infusionNumber: max(1, infusionNumber)
            )
        )
        saveSessions()
    }

    func recordCancellation(
        sessionID: UUID,
        tea: Tea,
        startedAt: Date,
        elapsedSeconds: Int,
        infusionNumber: Int = 1
    ) {
        guard !sessions.contains(where: { $0.id == sessionID }) else { return }
        sessions.append(
            BrewSession(
                id: sessionID,
                teaID: tea.id,
                teaSnapshotName: tea.name,
                startedAt: startedAt,
                cancelledAt: Date(),
                actualSteepSeconds: elapsedSeconds,
                infusionNumber: max(1, infusionNumber)
            )
        )
        saveSessions()
    }

    func updateJournal(sessionID: UUID, rating: Int?, note: String, outcome: BrewOutcome? = nil) {
        guard let index = sessions.firstIndex(where: { $0.id == sessionID }) else { return }
        let cleanedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
        sessions[index].rating = rating.map { min(5, max(1, $0)) }
        sessions[index].note = cleanedNote
        sessions[index].outcome = outcome
        saveSessions()
    }

    func deleteSessions(at offsets: IndexSet) {
        let sortedSessions = recentSessions
        let idsToDelete = offsets.map { sortedSessions[$0].id }
        deleteSessions(ids: idsToDelete)
    }

    func deleteSessions(ids: [BrewSession.ID]) {
        sessions.removeAll { ids.contains($0.id) }
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
