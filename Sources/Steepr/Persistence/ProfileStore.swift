import Foundation
import Combine

class ProfileStore: ObservableObject {
    @Published var profiles: [Profile] = []
    
    private let fileManager = FileManager.default
    private let fileName = "profiles.json"
    private let icloudKey = "steepr.profiles.sync"
    
    init() {
        loadProfiles()
        if profiles.isEmpty {
            loadDefaultProfiles()
        }
        setupICloudSync()
    }
    
    private func setupICloudSync() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(icloudDataChanged),
            name: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: NSUbiquitousKeyValueStore.default
        )
        NSUbiquitousKeyValueStore.default.synchronize()
    }
    
    @objc private func icloudDataChanged(notification: Notification) {
        DispatchQueue.main.async {
            self.pullFromICloud()
        }
    }
    
    private func pullFromICloud() {
        guard let data = NSUbiquitousKeyValueStore.default.data(forKey: icloudKey) else { return }
        do {
            let cloudProfiles = try JSONDecoder().decode([Profile].self, from: data)
            if cloudProfiles != self.profiles {
                self.profiles = cloudProfiles
                self.saveProfiles(syncToCloud: false)
            }
        } catch {
            print("Failed to decode iCloud profiles: \(error)")
        }
    }
    
    private var profilesURL: URL {
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appDirectory = appSupport.appendingPathComponent("Steepr", isDirectory: true)
        
        if !fileManager.fileExists(atPath: appDirectory.path) {
            try? fileManager.createDirectory(at: appDirectory, withIntermediateDirectories: true)
        }
        
        return appDirectory.appendingPathComponent(fileName)
    }
    
    func saveProfiles(syncToCloud: Bool = true) {
        do {
            let data = try JSONEncoder().encode(profiles)
            try data.write(to: profilesURL, options: .atomic)
            
            if syncToCloud {
                NSUbiquitousKeyValueStore.default.set(data, forKey: icloudKey)
                NSUbiquitousKeyValueStore.default.synchronize()
            }
        } catch {
            print("CRITICAL: Failed to save profiles: \(error)")
        }
    }
    
    func loadProfiles() {
        let url = profilesURL
        guard fileManager.fileExists(atPath: url.path) else { return }
        
        do {
            let data = try Data(contentsOf: url)
            profiles = try JSONDecoder().decode([Profile].self, from: data)
        } catch {
            print("ERROR: Failed to load profiles (corrupted?): \(error)")
            if profiles.isEmpty {
                loadDefaultProfiles()
            }
        }
    }
    
    private func loadDefaultProfiles() {
        profiles = [
            Profile(name: "Green Tea (Western)", steps: [
                Step(name: "Heat Water", duration: 0, temperature: 80, notes: "Don't use boiling water!"),
                Step(name: "Steep", duration: 180, temperature: 80, notes: "Wait for it...")
            ]),
            Profile(name: "Black Tea", steps: [
                Step(name: "Boil Water", duration: 0, temperature: 100),
                Step(name: "Steep", duration: 240, temperature: 100)
            ]),
            Profile(name: "Oolong (Gongfu)", steps: [
                Step(name: "Rinse", duration: 10, temperature: 90, notes: "Quickly rinse the leaves"),
                Step(name: "1st Steep", duration: 20, temperature: 90),
                Step(name: "2nd Steep", duration: 30, temperature: 90),
                Step(name: "3rd Steep", duration: 45, temperature: 90)
            ]),
            Profile(name: "White Tea", steps: [
                Step(name: "Heat Water", duration: 0, temperature: 75),
                Step(name: "Steep", duration: 300, temperature: 75)
            ]),
            Profile(name: "Coffee (French Press)", steps: [
                Step(name: "Bloom", duration: 30, temperature: 95, notes: "Wet the grounds"),
                Step(name: "Brew", duration: 240, temperature: 95)
            ])
        ]
        saveProfiles()
    }
    
    func addProfile(_ profile: Profile) {
        profiles.append(profile)
        saveProfiles()
    }
    
    func updateProfile(_ profile: Profile) {
        if let index = profiles.firstIndex(where: { $0.id == profile.id }) {
            profiles[index] = profile
            saveProfiles()
        }
    }
    
    func deleteProfile(at offsets: IndexSet) {
        profiles.remove(atOffsets: offsets)
        saveProfiles()
    }
}
