import SwiftUI

struct HistoryView: View {
    @EnvironmentObject var historyStore: HistoryStore
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // Custom Header for consistency
            HStack {
                Text("Brewing History")
                    .font(.headline)
                Spacer()
                Button("Done") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                #if os(macOS)
                .controlSize(.small)
                #endif
            }
            .padding()
            
            Divider()
            
            ZStack {
                if historyStore.entries.isEmpty {
                    VStack(spacing: 15) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary)
                        Text("No History Yet")
                            .font(.headline)
                        Text("Your completed steeps will appear here.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxHeight: .infinity)
                } else {
                    List {
                        ForEach(historyStore.entries) { entry in
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(entry.profileName)
                                        .font(.headline)
                                    Spacer()
                                    Text(entry.date, style: .date)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                HStack(spacing: 2) {
                                    ForEach(1...5, id: \.self) { star in
                                        Image(systemName: star <= entry.rating ? "star.fill" : "star")
                                            .foregroundColor(star <= entry.rating ? .yellow : .gray.opacity(0.3))
                                            .font(.caption2)
                                    }
                                }
                                
                                if let notes = entry.notes, !notes.isEmpty {
                                    Text(notes)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .lineLimit(2)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        .onDelete(perform: historyStore.deleteEntries)
                    }
                    .listStyle(.plain)
                }
            }
        }
        #if os(macOS)
        .frame(width: 450, height: 500)
        #endif
    }
}
