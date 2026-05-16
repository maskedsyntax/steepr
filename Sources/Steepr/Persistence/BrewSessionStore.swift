import Combine
import Foundation

final class BrewSessionStore: ObservableObject {
    @Published private(set) var sessions: [BrewSession] = []

    private let fileManager = FileManager.default
    private let fileName: String

    init(fileName: String = "brew-sessions.json") {
        self.fileName = fileName
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

    private var sessionsURL: URL {
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let directory = appSupport.appendingPathComponent("Steepr", isDirectory: true)
        if !fileManager.fileExists(atPath: directory.path) {
            try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        }
        return directory.appendingPathComponent(fileName)
    }

    private func loadSessions() {
        guard fileManager.fileExists(atPath: sessionsURL.path) else { return }
        do {
            let data = try Data(contentsOf: sessionsURL)
            sessions = try JSONDecoder().decode([BrewSession].self, from: data)
        } catch {
            print("Failed to load brew sessions: \(error)")
        }
    }

    private func saveSessions() {
        do {
            let data = try JSONEncoder().encode(sessions)
            try data.write(to: sessionsURL, options: .atomic)
        } catch {
            print("Failed to save brew sessions: \(error)")
        }
    }
}
