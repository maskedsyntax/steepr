import Foundation
import Combine

#if os(watchOS)
import WatchConnectivity
#endif

final class WatchDataStore: NSObject, ObservableObject {
    @Published private(set) var favoriteTeas: [Tea] = Tea.builtIns
    @Published private(set) var preferences: UserPreferences = .defaults

    private let defaults = UserDefaults.standard

    override init() {
        super.init()
        load()
        configureConnectivity()
    }

    func load() {
        if
            let data = defaults.data(forKey: FavoriteTeasSnapshot.storageKey),
            let snapshot = try? JSONDecoder().decode(FavoriteTeasSnapshot.self, from: data),
            !snapshot.teas.isEmpty
        {
            favoriteTeas = Array(snapshot.teas.prefix(6))
        }

        if
            let data = defaults.data(forKey: UserPreferencesSnapshot.storageKey),
            let snapshot = try? JSONDecoder().decode(UserPreferencesSnapshot.self, from: data)
        {
            preferences = snapshot.preferences
        }
    }

    private func configureConnectivity() {
        #if os(watchOS)
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
        apply(context: WCSession.default.applicationContext)
        #endif
    }

    private func apply(context: [String: Any]) {
        var changed = false

        if
            let data = context[FavoriteTeasSnapshot.storageKey] as? Data,
            let snapshot = try? JSONDecoder().decode(FavoriteTeasSnapshot.self, from: data)
        {
            defaults.set(data, forKey: FavoriteTeasSnapshot.storageKey)
            favoriteTeas = snapshot.teas.isEmpty ? Tea.builtIns : Array(snapshot.teas.prefix(6))
            changed = true
        }

        if
            let data = context[UserPreferencesSnapshot.storageKey] as? Data,
            let snapshot = try? JSONDecoder().decode(UserPreferencesSnapshot.self, from: data)
        {
            defaults.set(data, forKey: UserPreferencesSnapshot.storageKey)
            preferences = snapshot.preferences
            changed = true
        }

        if changed {
            defaults.synchronize()
        }
    }
}

#if os(watchOS)
extension WatchDataStore: WCSessionDelegate {
    func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {}

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        DispatchQueue.main.async {
            self.apply(context: applicationContext)
        }
    }
}
#endif
