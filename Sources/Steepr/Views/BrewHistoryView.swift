import SwiftUI

struct BrewHistoryView: View {
    @EnvironmentObject private var brewSessionStore: BrewSessionStore

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
                    ForEach(brewSessionStore.recentSessions) { session in
                        BrewSessionRow(session: session)
                    }
                    .onDelete(perform: brewSessionStore.deleteSessions)
                }
            }
        }
        .navigationTitle("Brew History")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}

private struct BrewSessionRow: View {
    let session: BrewSession

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
                Label(formatDuration(session.actualSteepSeconds), systemImage: "clock")
                Text("•")
                Text(session.startedAt, style: .date)
                Text(session.startedAt, style: .time)
            }
            .font(.footnote)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }

    private var statusText: String {
        session.completedAt == nil ? "Cancelled" : "Done"
    }

    private var statusColor: Color {
        session.completedAt == nil ? .secondary : TeaColorSlot.green.color
    }
}
