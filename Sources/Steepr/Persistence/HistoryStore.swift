import Foundation
import Combine

class HistoryStore: ObservableObject {
    @Published var entries: [HistoryEntry] = []
    
    private let fileManager = FileManager.default
    private let fileName = "history.json"
    
    init() {
        loadEntries()
    }
    
    private var historyURL: URL {
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appDirectory = appSupport.appendingPathComponent("Steepr", isDirectory: true)
        
        if !fileManager.fileExists(atPath: appDirectory.path) {
            try? fileManager.createDirectory(at: appDirectory, withIntermediateDirectories: true)
        }
        
        return appDirectory.appendingPathComponent(fileName)
    }
    
    func addEntry(_ entry: HistoryEntry) {
        entries.insert(entry, at: 0) // Newest first
        saveEntries()
    }
    
    func saveEntries() {
        do {
            let data = try JSONEncoder().encode(entries)
            try data.write(to: historyURL, options: .atomic)
        } catch {
            print("Failed to save history: \(error)")
        }
    }
    
    func loadEntries() {
        let url = historyURL
        guard fileManager.fileExists(atPath: url.path) else { return }
        
        do {
            let data = try Data(contentsOf: url)
            entries = try JSONDecoder().decode([HistoryEntry].self, from: data)
        } catch {
            print("Failed to load history: \(error)")
        }
    }
    
    func deleteEntries(at offsets: IndexSet) {
        entries.remove(atOffsets: offsets)
        saveEntries()
    }
}
