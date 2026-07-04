import SwiftUI

struct BrewHistoryView: View {
    @EnvironmentObject private var brewSessionStore: BrewSessionStore
    @EnvironmentObject private var teaStore: TeaStore
    @State private var showingPaywall = false
    @State private var journalSession: BrewSession?

    private var visibleSessions: [BrewSession] {
        if teaStore.preferences.proPurchased {
            return brewSessionStore.recentSessions
        }
        return Array(brewSessionStore.recentSessions.prefix(5))
    }

    var body: some View {
        List {
            if brewSessionStore.recentSessions.isEmpty {
                Section {
                    VStack(spacing: 10) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 36, weight: .medium))
                            .foregroundStyle(.secondary)
                        Text("No brews yet")
                            .font(.headline)
                        Text("Completed and cancelled timers will appear here.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 28)
                }
            } else {
                Section("Recent Brews") {
                    ForEach(visibleSessions) { session in
                        BrewSessionRow(session: session) {
                            journalSession = session
                        }
                    }
                    .onDelete(perform: brewSessionStore.deleteSessions)
                }

                if !teaStore.preferences.proPurchased && brewSessionStore.recentSessions.count > visibleSessions.count {
                    Section {
                        Button {
                            showingPaywall = true
                        } label: {
                            Label("Unlock full brew history", systemImage: "sparkles")
                        }
                        Text("Free shows the five most recent brews. Pro keeps your full journal.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle("Brew History")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .sheet(isPresented: $showingPaywall) {
            PaywallView(trigger: "Brew journal")
        }
        .sheet(item: $journalSession) { session in
            NavigationStack {
                BrewJournalPrompt(sessionID: session.id)
                    .environmentObject(brewSessionStore)
                    .padding()
                    .navigationTitle("Brew Journal")
                    #if os(iOS)
                    .navigationBarTitleDisplayMode(.inline)
                    #endif
            }
            .presentationDetents([.medium, .large])
        }
    }
}

private struct BrewSessionRow: View {
    let session: BrewSession
    let onJournal: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(session.teaSnapshotName)
                    .font(.headline)
                Spacer()
                Text(statusText)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(statusColor)
            }

            HStack(spacing: 8) {
                Text("Infusion \(session.infusionNumber)")
                Text("•")
                Label(formatDuration(session.actualSteepSeconds), systemImage: "clock")
                Text("•")
                Text(session.startedAt, style: .date)
                Text(session.startedAt, style: .time)
            }
            .font(.footnote)
            .foregroundStyle(.secondary)

            if let rating = session.rating {
                HStack(spacing: 2) {
                    ForEach(1...5, id: \.self) { value in
                        Image(systemName: value <= rating ? "star.fill" : "star")
                    }
                }
                .font(.caption)
                .foregroundStyle(.yellow)
                .accessibilityLabel("\(rating) star\(rating == 1 ? "" : "s")")
            }

            if let outcome = session.outcome {
                Text(outcome.label)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
            }

            if !session.note.isEmpty {
                Text(session.note)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            if session.completedAt != nil {
                Button {
                    onJournal()
                } label: {
                    Label(hasJournalEntry ? "Edit tasting notes" : "Add tasting notes", systemImage: "square.and.pencil")
                }
                .font(.footnote.weight(.medium))
                .buttonStyle(.bordered)
            }
        }
        .padding(.vertical, 4)
    }

    private var statusText: String {
        session.completedAt == nil ? "Cancelled" : "Done"
    }

    private var statusColor: Color {
        session.completedAt == nil ? .secondary : TeaColorSlot.green.color
    }

    private var hasJournalEntry: Bool {
        session.rating != nil || session.outcome != nil || !session.note.isEmpty
    }
}
