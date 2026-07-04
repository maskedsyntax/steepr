import SwiftUI

struct BrewJournalPrompt: View {
    @EnvironmentObject private var brewSessionStore: BrewSessionStore
    @Environment(\.dismiss) private var dismiss

    let sessionID: UUID

    @State private var rating: Int?
    @State private var note = ""
    @State private var outcome: BrewOutcome?
    @State private var loadedSessionID: UUID?
    @State private var saved = false

    private var session: BrewSession? {
        brewSessionStore.session(with: sessionID)
    }

    private var hasJournalEntry: Bool {
        rating != nil || outcome != nil || !note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Tasting notes")
                    .font(.headline)
                Spacer()
                if saved || session?.rating != nil || session?.outcome != nil || !(session?.note ?? "").isEmpty {
                    Text("Saved")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(TeaColorSlot.green.color)
                }
            }

            HStack(spacing: 8) {
                ForEach(1...5, id: \.self) { value in
                    Button {
                        rating = value
                        saved = false
                    } label: {
                        Image(systemName: (rating ?? 0) >= value ? "star.fill" : "star")
                            .font(.title3)
                            .foregroundStyle((rating ?? 0) >= value ? .yellow : .secondary)
                            .frame(width: 32, height: 32)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(value) star\(value == 1 ? "" : "s")")
                }
            }

            HStack(spacing: 8) {
                ForEach(BrewOutcome.allCases) { value in
                    outcomeButton(value)
                }
            }

            if let suggestion = outcome?.suggestion {
                Text(suggestion)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            TextField("Add a tasting note", text: $note, axis: .vertical)
                .lineLimit(2...4)
                .textFieldStyle(.roundedBorder)
                .onChange(of: note) { _, _ in
                    saved = false
                }

            Button {
                brewSessionStore.updateJournal(sessionID: sessionID, rating: rating, note: note, outcome: outcome)
                saved = true
                dismiss()
            } label: {
                Label("Save journal entry", systemImage: "square.and.pencil")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .disabled(!hasJournalEntry)
        }
        .padding(14)
        .frame(maxWidth: 420, alignment: .leading)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(.quaternary, lineWidth: 1)
        }
        .onAppear(perform: loadSessionIfNeeded)
        .onChange(of: sessionID) { _, _ in
            loadedSessionID = nil
            loadSessionIfNeeded()
        }
    }

    private func loadSessionIfNeeded() {
        guard loadedSessionID != sessionID else { return }
        loadedSessionID = sessionID
        rating = session?.rating
        note = session?.note ?? ""
        outcome = session?.outcome
        saved = session?.rating != nil || session?.outcome != nil || !(session?.note ?? "").isEmpty
    }

    @ViewBuilder
    private func outcomeButton(_ value: BrewOutcome) -> some View {
        if value == outcome {
            Button {
                outcome = value
                saved = false
            } label: {
                outcomeLabel(value)
            }
            .buttonStyle(.borderedProminent)
        } else {
            Button {
                outcome = value
                saved = false
            } label: {
                outcomeLabel(value)
            }
            .buttonStyle(.bordered)
        }
    }

    private func outcomeLabel(_ value: BrewOutcome) -> some View {
        Text(value.label)
            .font(.footnote.weight(.medium))
            .frame(maxWidth: .infinity)
    }
}
