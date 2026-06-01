import Foundation
import SwiftUI
import WidgetKit

@main
struct SteeprComplications: WidgetBundle {
    var body: some Widget {
        WatchBrewComplication()
    }
}

struct WatchBrewComplication: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "com.steepr.watch-brew", provider: WatchBrewProvider()) { entry in
            WatchBrewComplicationView(entry: entry)
                .containerBackground(.background, for: .widget)
        }
        .configurationDisplayName("Brew Timer")
        .description("Shows the active Steepr timer on Apple Watch.")
        .supportedFamilies([.accessoryCircular, .accessoryCorner, .accessoryRectangular])
    }
}

private struct WatchBrewProvider: TimelineProvider {
    func placeholder(in context: Context) -> WatchBrewEntry {
        WatchBrewEntry(date: Date(), snapshot: .placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (WatchBrewEntry) -> Void) {
        completion(WatchBrewEntry(date: Date(), snapshot: WatchActiveTimerSnapshot.load()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WatchBrewEntry>) -> Void) {
        let snapshot = WatchActiveTimerSnapshot.load()
        let entry = WatchBrewEntry(date: Date(), snapshot: snapshot)
        completion(Timeline(entries: [entry], policy: .after(snapshot?.nextRefreshDate ?? Date().addingTimeInterval(15 * 60))))
    }
}

private struct WatchBrewEntry: TimelineEntry {
    let date: Date
    let snapshot: WatchActiveTimerSnapshot?
}

private struct WatchBrewComplicationView: View {
    @Environment(\.widgetFamily) private var family
    let entry: WatchBrewEntry

    var body: some View {
        switch family {
        case .accessoryCorner:
            corner
        case .accessoryRectangular:
            rectangular
        default:
            circular
        }
    }

    private var circular: some View {
        Gauge(value: entry.snapshot?.progress ?? 0) {
            Image(systemName: "cup.and.saucer.fill")
        } currentValueLabel: {
            Text(entry.snapshot?.compactTimeText ?? "--")
                .minimumScaleFactor(0.68)
        }
        .gaugeStyle(.accessoryCircularCapacity)
    }

    private var corner: some View {
        Gauge(value: entry.snapshot?.progress ?? 0) {
            Image(systemName: "leaf.fill")
        } currentValueLabel: {
            Text(entry.snapshot?.compactTimeText ?? "--")
                .minimumScaleFactor(0.7)
        }
        .gaugeStyle(.accessoryCircular)
    }

    private var rectangular: some View {
        HStack(spacing: 8) {
            Image(systemName: "cup.and.saucer.fill")
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.snapshot?.tea.name ?? "No brew")
                    .font(.headline)
                    .lineLimit(1)
                Text(entry.snapshot?.statusLine ?? "Open Steepr")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
        }
    }
}

private struct WatchActiveTimerSnapshot: Codable, Equatable {
    static let storageKey = "steepr.watch.activeTimer"

    var tea: WatchTea
    var state: String
    var durationSeconds: Int
    var secondsRemaining: Int
    var endDate: Date?
    var pausedRemainingSeconds: Int

    var currentSecondsRemaining: Int {
        guard state == "running", let endDate else {
            return max(0, secondsRemaining)
        }

        return max(0, Int(ceil(endDate.timeIntervalSinceNow)))
    }

    var progress: Double {
        guard durationSeconds > 0 else { return 0 }
        return min(1, max(0, 1 - (Double(currentSecondsRemaining) / Double(durationSeconds))))
    }

    var compactTimeText: String {
        let seconds = currentSecondsRemaining
        return String(format: "%d:%02d", seconds / 60, seconds % 60)
    }

    var statusLine: String {
        switch state {
        case "running":
            return "\(compactTimeText) left"
        case "paused":
            return "Paused \(compactTimeText)"
        case "completed":
            return "Ready"
        default:
            return "Open Steepr"
        }
    }

    var nextRefreshDate: Date? {
        guard state == "running" else { return nil }
        return endDate
    }

    static var placeholder: WatchActiveTimerSnapshot {
        WatchActiveTimerSnapshot(
            tea: WatchTea(name: "Green"),
            state: "running",
            durationSeconds: 150,
            secondsRemaining: 72,
            endDate: Date().addingTimeInterval(72),
            pausedRemainingSeconds: 0
        )
    }

    static func load() -> WatchActiveTimerSnapshot? {
        guard
            let data = UserDefaults(suiteName: "group.com.maskedsyntax.steepr")?.data(forKey: storageKey),
            let snapshot = try? JSONDecoder().decode(WatchActiveTimerSnapshot.self, from: data)
        else {
            return nil
        }

        return snapshot
    }
}

private struct WatchTea: Codable, Equatable {
    var name: String
}
