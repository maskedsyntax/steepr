import Foundation

#if os(iOS)
import WatchConnectivity
#endif

enum WatchSyncService {
    static func configure() {
        #if os(iOS)
        WatchSyncSession.shared.configure()
        #endif
    }

    static func sync(favorites: FavoriteTeasSnapshot, preferences: UserPreferencesSnapshot) {
        #if os(iOS)
        WatchSyncSession.shared.sync(favorites: favorites, preferences: preferences)
        #endif
    }
}

#if os(iOS)
private final class WatchSyncSession: NSObject, WCSessionDelegate {
    static let shared = WatchSyncSession()

    private var isConfigured = false

    func configure() {
        guard WCSession.isSupported(), !isConfigured else { return }
        isConfigured = true
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    func sync(favorites: FavoriteTeasSnapshot, preferences: UserPreferencesSnapshot) {
        configure()
        guard WCSession.isSupported() else { return }

        var payload: [String: Any] = [:]
        if let favoritesData = try? JSONEncoder().encode(favorites) {
            payload[FavoriteTeasSnapshot.storageKey] = favoritesData
        }
        if let preferencesData = try? JSONEncoder().encode(preferences) {
            payload[UserPreferencesSnapshot.storageKey] = preferencesData
        }

        guard !payload.isEmpty else { return }
        try? WCSession.default.updateApplicationContext(payload)
    }

    func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {}

    func sessionDidBecomeInactive(_ session: WCSession) {}

    func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }
}
#endif
