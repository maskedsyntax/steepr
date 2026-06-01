import AppIntents
import ActivityKit
import Foundation
import SwiftUI
import UIKit
import WidgetKit

@main
struct SteeprWidgets: WidgetBundle {
    var body: some Widget {
        QuickBrewWidget()
        CurrentBrewWidget()
        BrewLiveActivityWidget()
    }
}

struct QuickBrewWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "com.steepr.quick-brew", provider: QuickBrewProvider()) { entry in
            QuickBrewWidgetView(entry: entry)
                .containerBackground(.background, for: .widget)
        }
        .configurationDisplayName("Quick Brew")
        .description("Start a favorite tea timer from the Home Screen.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct CurrentBrewWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "com.steepr.current-brew", provider: CurrentBrewProvider()) { entry in
            CurrentBrewWidgetView(entry: entry)
                .containerBackground(.background, for: .widget)
        }
        .configurationDisplayName("Current Brew")
        .description("See the active tea timer at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryCircular, .accessoryRectangular])
    }
}

struct BrewLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: SteeprLiveActivityAttributes.self) { context in
            BrewLiveActivityView(
                teaName: context.attributes.teaName,
                symbolName: context.attributes.symbolName,
                state: context.state.state,
                endDate: context.state.endDate,
                secondsRemaining: context.state.secondsRemaining,
                progress: context.state.progress
            )
            .activityBackgroundTint(Color(uiColor: .systemBackground))
            .activitySystemActionForegroundColor(.primary)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Label(context.attributes.teaName, systemImage: context.attributes.symbolName)
                        .font(.headline)
                        .lineLimit(1)
                }

                DynamicIslandExpandedRegion(.trailing) {
                    liveActivityTimeText(
                        state: context.state.state,
                        endDate: context.state.endDate,
                        secondsRemaining: context.state.secondsRemaining
                    )
                    .font(.title3.monospacedDigit().weight(.semibold))
                }

                DynamicIslandExpandedRegion(.bottom) {
                    HStack(spacing: 10) {
                        ProgressView(value: context.state.progress)

                        Button(intent: PauseBrewTimerIntent()) {
                            Image(systemName: "pause.fill")
                        }
                        .disabled(context.state.state != "running")

                        Button(intent: CancelBrewTimerIntent()) {
                            Image(systemName: "xmark")
                        }
                    }
                    .tint(.primary)
                }
            } compactLeading: {
                Image(systemName: context.attributes.symbolName)
            } compactTrailing: {
                liveActivityTimeText(
                    state: context.state.state,
                    endDate: context.state.endDate,
                    secondsRemaining: context.state.secondsRemaining
                )
                .font(.caption2.monospacedDigit())
            } minimal: {
                Image(systemName: "cup.and.saucer.fill")
            }
        }
    }
}

private struct QuickBrewProvider: TimelineProvider {
    func placeholder(in context: Context) -> QuickBrewEntry {
        QuickBrewEntry(date: Date(), teas: WidgetTea.builtIns)
    }

    func getSnapshot(in context: Context, completion: @escaping (QuickBrewEntry) -> Void) {
        completion(QuickBrewEntry(date: Date(), teas: WidgetFavoriteTeasSnapshot.loadFavorites()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<QuickBrewEntry>) -> Void) {
        let entry = QuickBrewEntry(date: Date(), teas: WidgetFavoriteTeasSnapshot.loadFavorites())
        completion(Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(15 * 60))))
    }
}

private struct QuickBrewEntry: TimelineEntry {
    let date: Date
    let teas: [WidgetTea]
}

private struct QuickBrewWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: QuickBrewEntry

    private var visibleTeas: [WidgetTea] {
        Array(entry.teas.prefix(family == .systemSmall ? 2 : 4))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "leaf.fill")
                Text("Quick Brew")
                    .font(.caption.weight(.semibold))
                Spacer(minLength: 0)
            }
            .foregroundStyle(.secondary)

            if visibleTeas.isEmpty {
                Spacer(minLength: 0)
                Image(systemName: "star")
                    .font(.title2)
                    .foregroundStyle(.secondary)
                Text("Pick favorites")
                    .font(.headline)
                    .lineLimit(2)
                Text("Open Steepr")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    ForEach(visibleTeas) { tea in
                        Button(intent: StartQuickBrewIntent(teaID: tea.id.uuidString)) {
                            VStack(alignment: .leading, spacing: 5) {
                                Image(systemName: tea.symbolName)
                                    .font(.headline)
                                Text(tea.name)
                                    .font(.caption.weight(.semibold))
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.76)
                                Text(tea.compactDuration)
                                    .font(.caption2.monospacedDigit())
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity, minHeight: 52, alignment: .leading)
                            .padding(8)
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }
        }
    }
}

private struct CurrentBrewProvider: TimelineProvider {
    func placeholder(in context: Context) -> CurrentBrewEntry {
        CurrentBrewEntry(date: Date(), snapshot: .placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (CurrentBrewEntry) -> Void) {
        completion(CurrentBrewEntry(date: Date(), snapshot: WidgetActiveTimerSnapshot.load()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<CurrentBrewEntry>) -> Void) {
        let snapshot = WidgetActiveTimerSnapshot.load()
        let entry = CurrentBrewEntry(date: Date(), snapshot: snapshot)
        let nextUpdate = snapshot?.nextRefreshDate ?? Date().addingTimeInterval(15 * 60)
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }
}

private struct CurrentBrewEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetActiveTimerSnapshot?
}

private struct CurrentBrewWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: CurrentBrewEntry

    var body: some View {
        switch family {
        case .accessoryCircular:
            circularContent
        case .accessoryRectangular:
            rectangularContent
        default:
            standardContent
        }
    }

    private var standardContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            header

            if let snapshot = entry.snapshot, snapshot.isActive {
                Spacer(minLength: 0)
                Text(snapshot.tea.name)
                    .font(.headline)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                timerText(for: snapshot)
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .contentTransition(.numericText())
                Text(snapshot.statusText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                if snapshot.state == .running || snapshot.state == .paused {
                    HStack(spacing: 8) {
                        Button(intent: PauseBrewTimerIntent()) {
                            Image(systemName: "pause.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .disabled(snapshot.state != .running)

                        Button(intent: CancelBrewTimerIntent()) {
                            Image(systemName: "xmark")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .buttonStyle(.bordered)
                }
            } else {
                Spacer(minLength: 0)
                Image(systemName: "cup.and.saucer.fill")
                    .font(.title)
                    .foregroundStyle(.secondary)
                Text("No active brew")
                    .font(.headline)
                    .lineLimit(2)
                Text("Start one in Steepr")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var circularContent: some View {
        Gauge(value: entry.snapshot?.progress ?? 0) {
            Image(systemName: "cup.and.saucer.fill")
        } currentValueLabel: {
            Text(entry.snapshot?.compactTimeText ?? "--")
                .minimumScaleFactor(0.72)
        }
        .gaugeStyle(.accessoryCircularCapacity)
    }

    private var rectangularContent: some View {
        HStack(spacing: 8) {
            Image(systemName: "cup.and.saucer.fill")
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.snapshot?.tea.name ?? "No active brew")
                    .font(.headline)
                    .lineLimit(1)

                if let snapshot = entry.snapshot, snapshot.isActive {
                    timerText(for: snapshot)
                        .font(.caption.monospacedDigit())
                } else {
                    Text("Open Steepr")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var header: some View {
        HStack(spacing: 6) {
            Image(systemName: "leaf.fill")
            Text("Steepr")
                .font(.caption.weight(.semibold))
            Spacer(minLength: 0)
        }
        .foregroundStyle(.secondary)
    }

    @ViewBuilder
    private func timerText(for snapshot: WidgetActiveTimerSnapshot) -> some View {
        if snapshot.state == .running, let interval = snapshot.timerInterval {
            Text(timerInterval: interval, countsDown: true)
        } else {
            Text(snapshot.compactTimeText)
        }
    }
}

private struct BrewLiveActivityView: View {
    let teaName: String
    let symbolName: String
    let state: String
    let endDate: Date?
    let secondsRemaining: Int
    let progress: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: symbolName)
                    .font(.title3)
                VStack(alignment: .leading, spacing: 2) {
                    Text(teaName)
                        .font(.headline)
                        .lineLimit(1)
                    Text(statusText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                liveActivityTimeText(
                    state: state,
                    endDate: endDate,
                    secondsRemaining: secondsRemaining
                )
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .monospacedDigit()
            }

            ProgressView(value: progress)

            HStack(spacing: 10) {
                Button(intent: PauseBrewTimerIntent()) {
                    Label("Pause", systemImage: "pause.fill")
                }
                .disabled(state != "running")

                Button(intent: CancelBrewTimerIntent()) {
                    Label("Cancel", systemImage: "xmark")
                }
            }
            .buttonStyle(.bordered)
        }
        .padding()
    }

    private var statusText: String {
        switch state {
        case "running":
            return "Brewing"
        case "paused":
            return "Paused"
        case "completed":
            return "Ready"
        default:
            return "Idle"
        }
    }
}

@ViewBuilder
private func liveActivityTimeText(state: String, endDate: Date?, secondsRemaining: Int) -> some View {
    if state == "running", let endDate {
        Text(timerInterval: Date()...endDate, countsDown: true)
    } else {
        let value = max(0, secondsRemaining)
        Text(String(format: "%d:%02d", value / 60, value % 60))
    }
}

private struct WidgetActiveTimerSnapshot: Codable, Equatable {
    static let storageKey = "steepr.activeTimer"

    var sessionID: UUID
    var tea: WidgetTea
    var state: WidgetActiveTimerState
    var startedAt: Date
    var hapticStyle: WidgetHapticStyle
    var soundEnabled: Bool
    var durationSeconds: Int
    var secondsRemaining: Int
    var endDate: Date?
    var pausedRemainingSeconds: Int

    var isActive: Bool {
        state == .running || state == .paused || state == .completed
    }

    var currentSecondsRemaining: Int {
        guard state == .running, let endDate else {
            return max(0, secondsRemaining)
        }

        return max(0, Int(ceil(endDate.timeIntervalSinceNow)))
    }

    var progress: Double {
        guard durationSeconds > 0 else { return 0 }
        return min(1, max(0, 1 - (Double(currentSecondsRemaining) / Double(durationSeconds))))
    }

    var timerInterval: ClosedRange<Date>? {
        guard state == .running, let endDate else { return nil }
        return Date()...endDate
    }

    var compactTimeText: String {
        let seconds = currentSecondsRemaining
        return String(format: "%d:%02d", seconds / 60, seconds % 60)
    }

    var statusText: String {
        switch state {
        case .running:
            return "Brewing"
        case .paused:
            return "Paused"
        case .completed:
            return "Ready"
        case .idle:
            return "Idle"
        }
    }

    var nextRefreshDate: Date? {
        guard state == .running else { return nil }
        return endDate
    }

    static var placeholder: WidgetActiveTimerSnapshot {
        WidgetActiveTimerSnapshot(
            sessionID: UUID(),
            tea: WidgetTea.builtIns[0],
            state: .running,
            startedAt: Date(),
            hapticStyle: .standard,
            soundEnabled: true,
            durationSeconds: 150,
            secondsRemaining: 72,
            endDate: Date().addingTimeInterval(72),
            pausedRemainingSeconds: 0
        )
    }

    static func load() -> WidgetActiveTimerSnapshot? {
        guard
            let data = UserDefaults(suiteName: "group.com.maskedsyntax.Steepr")?.data(forKey: storageKey),
            let snapshot = try? JSONDecoder().decode(WidgetActiveTimerSnapshot.self, from: data)
        else {
            return nil
        }

        return snapshot
    }

    static func pause() -> WidgetActiveTimerSnapshot? {
        guard var snapshot = load(), snapshot.state == .running else { return nil }
        let remaining = snapshot.currentSecondsRemaining
        snapshot.state = .paused
        snapshot.secondsRemaining = remaining
        snapshot.pausedRemainingSeconds = remaining
        snapshot.endDate = nil
        save(snapshot)
        return snapshot
    }

    static func cancel() {
        UserDefaults(suiteName: "group.com.maskedsyntax.Steepr")?.removeObject(forKey: storageKey)
    }

    static func start(tea: WidgetTea) {
        let preferences = WidgetUserPreferencesSnapshot.load()?.preferences ?? .defaults
        let now = Date()
        let snapshot = WidgetActiveTimerSnapshot(
            sessionID: UUID(),
            tea: tea,
            state: .running,
            startedAt: now,
            hapticStyle: preferences.hapticStyle,
            soundEnabled: preferences.soundEnabled,
            durationSeconds: tea.steepSeconds,
            secondsRemaining: tea.steepSeconds,
            endDate: now.addingTimeInterval(TimeInterval(tea.steepSeconds)),
            pausedRemainingSeconds: 0
        )

        save(snapshot)
    }

    private static func save(_ snapshot: WidgetActiveTimerSnapshot) {
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        UserDefaults(suiteName: "group.com.maskedsyntax.Steepr")?.set(data, forKey: storageKey)
    }
}

struct SteeprLiveActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var state: String
        var endDate: Date?
        var secondsRemaining: Int
        var progress: Double
    }

    var sessionID: UUID
    var teaName: String
    var symbolName: String
    var durationSeconds: Int
}

private enum WidgetActiveTimerState: String, Codable, Equatable {
    case idle
    case running
    case paused
    case completed
}

private enum WidgetHapticStyle: String, Codable, Equatable {
    case standard
    case soft
    case strong
}

private struct WidgetFavoriteTeasSnapshot: Codable, Equatable {
    static let storageKey = "steepr.favoriteTeas"

    var generatedAt: Date
    var teas: [WidgetTea]

    static func loadFavorites() -> [WidgetTea] {
        guard
            let data = UserDefaults(suiteName: "group.com.maskedsyntax.Steepr")?.data(forKey: storageKey),
            let snapshot = try? JSONDecoder().decode(WidgetFavoriteTeasSnapshot.self, from: data),
            !snapshot.teas.isEmpty
        else {
            return WidgetTea.builtIns
        }

        return Array(snapshot.teas.prefix(6))
    }
}

private struct WidgetUserPreferencesSnapshot: Codable, Equatable {
    static let storageKey = "steepr.preferences"

    var generatedAt: Date
    var preferences: WidgetUserPreferences

    static func load() -> WidgetUserPreferencesSnapshot? {
        guard
            let data = UserDefaults(suiteName: "group.com.maskedsyntax.Steepr")?.data(forKey: storageKey),
            let snapshot = try? JSONDecoder().decode(WidgetUserPreferencesSnapshot.self, from: data)
        else {
            return nil
        }

        return snapshot
    }
}

private struct WidgetUserPreferences: Codable, Equatable {
    var useCelsius: Bool
    var preAlertSeconds: Int?
    var hapticStyle: WidgetHapticStyle
    var soundEnabled: Bool
    var soundName: String
    var autoStartSameTea: Bool
    var notificationsAuthorized: Bool
    var onboardingComplete: Bool
    var proPurchased: Bool

    static let defaults = WidgetUserPreferences(
        useCelsius: true,
        preAlertSeconds: nil,
        hapticStyle: .standard,
        soundEnabled: true,
        soundName: "Default",
        autoStartSameTea: false,
        notificationsAuthorized: false,
        onboardingComplete: false,
        proPurchased: false
    )
}

private enum WidgetTeaColorSlot: String, Codable, Equatable {
    case green
    case black
    case oolong
    case white
    case herbal
    case chai
    case puerh
    case matcha
    case customA
    case customB
}

private struct WidgetTea: Codable, Equatable, Hashable, Identifiable {
    var id: UUID
    var name: String
    var symbolName: String
    var colorSlot: WidgetTeaColorSlot
    var steepSeconds: Int
    var temperatureCelsius: Int
    var caffeineMilligrams: Int?
    var notes: String
    var isBuiltIn: Bool
    var isFavorite: Bool
    var favoriteRank: Int?
    var createdAt: Date
    var updatedAt: Date

    var compactDuration: String {
        if steepSeconds < 60 {
            return "\(steepSeconds)s"
        }

        let minutes = steepSeconds / 60
        let seconds = steepSeconds % 60
        return seconds == 0 ? "\(minutes)m" : "\(minutes)m \(seconds)s"
    }

    static let builtIns: [WidgetTea] = {
        let now = Date(timeIntervalSince1970: 0)
        return [
            WidgetTea(id: UUID(uuidString: "2E2A25B8-1E8E-432C-B0F0-000000000001")!, name: "Green", symbolName: "leaf.fill", colorSlot: .green, steepSeconds: 150, temperatureCelsius: 80, caffeineMilligrams: 30, notes: "Lower heat keeps green tea smooth.", isBuiltIn: true, isFavorite: true, favoriteRank: 0, createdAt: now, updatedAt: now),
            WidgetTea(id: UUID(uuidString: "2E2A25B8-1E8E-432C-B0F0-000000000002")!, name: "Black", symbolName: "cup.and.saucer.fill", colorSlot: .black, steepSeconds: 240, temperatureCelsius: 95, caffeineMilligrams: 45, notes: "A full, strong steep works best near boiling.", isBuiltIn: true, isFavorite: true, favoriteRank: 1, createdAt: now, updatedAt: now),
            WidgetTea(id: UUID(uuidString: "2E2A25B8-1E8E-432C-B0F0-000000000003")!, name: "Oolong", symbolName: "flame.fill", colorSlot: .oolong, steepSeconds: 210, temperatureCelsius: 90, caffeineMilligrams: 35, notes: "Balanced heat opens darker and lighter oolongs.", isBuiltIn: true, isFavorite: true, favoriteRank: 2, createdAt: now, updatedAt: now),
            WidgetTea(id: UUID(uuidString: "2E2A25B8-1E8E-432C-B0F0-000000000004")!, name: "Herbal", symbolName: "camera.macro", colorSlot: .herbal, steepSeconds: 300, temperatureCelsius: 100, caffeineMilligrams: nil, notes: "Most herbal blends want a longer infusion.", isBuiltIn: true, isFavorite: true, favoriteRank: 3, createdAt: now, updatedAt: now)
        ]
    }()
}

private struct StartQuickBrewIntent: AppIntent {
    static var title: LocalizedStringResource = "Start Quick Brew"
    static var description = IntentDescription("Starts a Steepr timer for a favorite tea.")
    static var openAppWhenRun = false

    @Parameter(title: "Tea ID")
    var teaID: String

    init() {
        teaID = ""
    }

    init(teaID: String) {
        self.teaID = teaID
    }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let tea = WidgetFavoriteTeasSnapshot.loadFavorites().first { $0.id.uuidString == teaID }

        guard let tea else {
            return .result(dialog: "Tea not found.")
        }

        WidgetActiveTimerSnapshot.start(tea: tea)
        WidgetCenter.shared.reloadAllTimelines()

        return .result(dialog: "\(tea.name) is brewing.")
    }
}

private struct PauseBrewTimerIntent: AppIntent {
    static var title: LocalizedStringResource = "Pause Brew Timer"
    static var description = IntentDescription("Pauses the active Steepr timer.")
    static var openAppWhenRun = false

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard let snapshot = WidgetActiveTimerSnapshot.pause() else {
            return .result(dialog: "No running tea timer.")
        }

        await updateLiveActivity(snapshot: snapshot)
        WidgetCenter.shared.reloadAllTimelines()
        return .result(dialog: "\(snapshot.tea.name) paused.")
    }
}

private struct CancelBrewTimerIntent: AppIntent {
    static var title: LocalizedStringResource = "Cancel Brew Timer"
    static var description = IntentDescription("Cancels the active Steepr timer.")
    static var openAppWhenRun = false

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let teaName = WidgetActiveTimerSnapshot.load()?.tea.name
        WidgetActiveTimerSnapshot.cancel()
        await endLiveActivities()
        WidgetCenter.shared.reloadAllTimelines()

        if let teaName {
            return .result(dialog: "\(teaName) stopped.")
        }
        return .result(dialog: "No active tea timer.")
    }
}

private func updateLiveActivity(snapshot: WidgetActiveTimerSnapshot) async {
    let state = SteeprLiveActivityAttributes.ContentState(
        state: snapshot.state.rawValue,
        endDate: snapshot.endDate,
        secondsRemaining: snapshot.currentSecondsRemaining,
        progress: snapshot.progress
    )

    for activity in Activity<SteeprLiveActivityAttributes>.activities
        where activity.attributes.sessionID == snapshot.sessionID
    {
        await activity.update(ActivityContent(state: state, staleDate: snapshot.endDate))
    }
}

private func endLiveActivities() async {
    for activity in Activity<SteeprLiveActivityAttributes>.activities {
        await activity.end(nil, dismissalPolicy: .immediate)
    }
}
