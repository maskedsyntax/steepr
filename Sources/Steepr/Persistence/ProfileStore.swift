import Foundation
import Combine

class ProfileStore: ObservableObject {
    @Published var profiles: [Profile] = []
    
    private let fileManager = FileManager.default
    private let fileName = "profiles.json"
    
    init() {
        loadProfiles()
        if profiles.isEmpty {
            loadDefaultProfiles()
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
    
    func saveProfiles() {
        do {
            let data = try JSONEncoder().encode(profiles)
            try data.write(to: profilesURL)
        } catch {
            print("Failed to save profiles: \(error.localizedDescription)")
        }
    }
    
    func loadProfiles() {
        let url = profilesURL
        guard fileManager.fileExists(atPath: url.path) else { return }
        
        do {
            let data = try Data(contentsOf: url)
            profiles = try JSONDecoder().decode([Profile].self, from: data)
        } catch {
            print("Failed to load profiles: \(error.localizedDescription)")
        }
    }
    
    private func loadDefaultProfiles() {
        profiles = [
            Profile(name: "Green Tea", steps: [
                Step(name: "Boil Water", duration: 0, notes: "Target 80°C"),
                Step(name: "Cool Down", duration: 120, notes: "Wait for water to reach temperature"),
                Step(name: "Steep", duration: 180, notes: "Wait for it...")
            ]),
            Profile(name: "Black Tea", steps: [
                Step(name: "Boil Water", duration: 0, notes: "Target 100°C"),
                Step(name: "Steep", duration: 300, notes: "Wait for it...")
            ]),
            Profile(name: "Coffee (French Press)", steps: [
                Step(name: "Bloom", duration: 30, notes: "Pour a little water to wet the grounds"),
                Step(name: "Brew", duration: 240, notes: "Pour the rest and wait")
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
