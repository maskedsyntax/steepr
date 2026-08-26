import AppIntents
import ActivityKit
import Foundation
import SwiftUI
import UIKit
import UserNotifications
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
        .contentMarginsDisabled()
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
        .contentMarginsDisabled()
    }
}

struct BrewLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: SteeprLiveActivityAttributes.self) { context in
            BrewLiveActivityView(
                sessionID: context.attributes.sessionID,
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
                        secondsRemaining: context.state.secondsRemaining,
                        sessionID: context.attributes.sessionID
                    )
                    .font(.title3.monospacedDigit().weight(.semibold))
                }

                DynamicIslandExpandedRegion(.bottom) {
                    HStack(spacing: 10) {
                        ProgressView(value: context.state.progress)

                        Link(destination: WidgetTimerControlURL.pause) {
                            Image(systemName: "pause.fill")
                        }

                        Link(destination: WidgetTimerControlURL.stop) {
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
                    secondsRemaining: context.state.secondsRemaining,
                    sessionID: context.attributes.sessionID
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
        VStack(alignment: .leading, spacing: 7) {
            WidgetHeader(title: "Quick Brew", subtitle: "Tap to start")

            if visibleTeas.isEmpty {
                EmptyWidgetState(
                    imageName: "star",
                    title: "Pick favorites",
                    subtitle: "Then start them here"
                )
            } else {
                quickBrewGrid
            }
        }
        .padding(14)
    }

    private var quickBrewGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 7), GridItem(.flexible(), spacing: 7)], spacing: 7) {
            ForEach(visibleTeas) { tea in
                Link(destination: tea.quickBrewURL) {
                    QuickBrewCard(tea: tea, isCompact: family == .systemSmall)
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
        VStack(alignment: .leading, spacing: 9) {
            WidgetHeader(title: "Current Brew", subtitle: entry.snapshot?.statusText ?? "Idle")

            if let snapshot = entry.snapshot, snapshot.isActive {
                activeBrewContent(snapshot)
                if snapshot.state == .running || snapshot.state == .paused {
                    HStack(spacing: 7) {
                        if snapshot.state == .running {
                            Link(destination: WidgetTimerControlURL.pause) {
                                Label("Pause", systemImage: "pause.fill")
                                    .font(.caption.weight(.semibold))
                                    .frame(maxWidth: .infinity, minHeight: 30)
                                    .background(.thinMaterial, in: Capsule())
                            }
                        } else {
                            Label("Paused", systemImage: "pause")
                                .font(.caption.weight(.semibold))
                                .frame(maxWidth: .infinity, minHeight: 30)
                                .background(.thinMaterial, in: Capsule())
                        }

                        Link(destination: WidgetTimerControlURL.stop) {
                            Label("Stop", systemImage: "xmark")
                                .font(.caption.weight(.semibold))
                                .frame(maxWidth: .infinity, minHeight: 30)
                                .background(Color.red.opacity(0.18), in: Capsule())
                        }
                    }
                }
            } else {
                EmptyWidgetState(
                    imageName: "cup.and.saucer.fill",
                    title: "No active brew",
                    subtitle: "Use Quick Brew to start"
                )
            }
        }
        .padding(14)
    }

    private func activeBrewContent(_ snapshot: WidgetActiveTimerSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Label(snapshot.tea.name, systemImage: snapshot.tea.symbolName)
                    .font(.headline.weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)

                Spacer(minLength: 4)
            }

            timerText(for: snapshot)
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .monospacedDigit()
                .contentTransition(.numericText())
                .minimumScaleFactor(0.72)

            ProgressView(value: snapshot.progress)
                .tint(snapshot.tea.tintColor)
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

    @ViewBuilder
    private func timerText(for snapshot: WidgetActiveTimerSnapshot) -> some View {
        if snapshot.state == .running, let interval = snapshot.timerInterval {
            Text(timerInterval: interval, countsDown: true)
        } else {
            Text(snapshot.compactTimeText)
        }
    }
}

private struct WidgetHeader: View {
    let title: String
    let subtitle: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Image(systemName: "leaf.fill")
                .font(.caption.weight(.bold))
            Text(title)
                .font(.caption.weight(.bold))
                .lineLimit(1)
            Spacer(minLength: 4)
            Text(subtitle)
                .font(.caption2.weight(.medium))
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .foregroundStyle(.secondary)
    }
}

private struct EmptyWidgetState: View {
    let imageName: String
    let title: String
    let subtitle: String

    var body: some View {
        Spacer(minLength: 0)
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: imageName)
                .font(.title2.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(title)
                .font(.headline.weight(.semibold))
                .lineLimit(2)
                .minimumScaleFactor(0.82)
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        Spacer(minLength: 0)
    }
}

private struct QuickBrewCard: View {
    let tea: WidgetTea
    let isCompact: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: tea.symbolName)
                    .font(.caption.weight(.bold))
                Spacer(minLength: 0)
                Text(tea.compactDuration)
                    .font(.caption2.monospacedDigit().weight(.semibold))
                    .lineLimit(1)
            }

            Text(tea.name)
                .font(.caption.weight(.bold))
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
        .foregroundStyle(tea.tintColor)
        .padding(.horizontal, 9)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity, minHeight: isCompact ? 42 : 46, alignment: .leading)
        .background(
            LinearGradient(
                colors: [tea.tintColor.opacity(0.22), tea.tintColor.opacity(0.09)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 18, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(tea.tintColor.opacity(0.28), lineWidth: 1)
        )
    }
}

private struct BrewLiveActivityView: View {
    let sessionID: UUID
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
                    secondsRemaining: secondsRemaining,
                    sessionID: sessionID
                )
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .monospacedDigit()
            }

            ProgressView(value: progress)

            HStack(spacing: 10) {
                Link(destination: WidgetTimerControlURL.pause) {
                    Label("Pause", systemImage: "pause.fill")
                }

                Link(destination: WidgetTimerControlURL.stop) {
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
private func liveActivityTimeText(state: String, endDate: Date?, secondsRemaining: Int, sessionID: UUID) -> some View {
    let snapshot = WidgetActiveTimerSnapshot.load().flatMap { $0.sessionID == sessionID ? $0 : nil }
    let resolvedState = snapshot?.state.rawValue ?? state
    let resolvedEndDate = snapshot?.endDate ?? endDate
    let resolvedSecondsRemaining = snapshot?.currentSecondsRemaining ?? secondsRemaining

    if resolvedState == "running", let resolvedEndDate {
        Text(timerInterval: Date()...resolvedEndDate, countsDown: true)
    } else {
        let value = max(0, resolvedSecondsRemaining)
        Text(String(format: "%d:%02d", value / 60, value % 60))
    }
}

private struct WidgetActiveTimerSnapshot: Codable, Equatable {
    static let storageKey = "steepr.activeTimer"
    private static let sharedTimerDidChangeNotification = "com.maskedsyntax.steepr.sharedTimerDidChange"

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
    var infusionNumber: Int = 1

    private enum CodingKeys: String, CodingKey {
        case sessionID
        case tea
        case state
        case startedAt
        case hapticStyle
        case soundEnabled
        case durationSeconds
        case secondsRemaining
        case endDate
        case pausedRemainingSeconds
        case infusionNumber
    }

    // Written by hand because the synthesized decoder ignores the default above and would
    // reject snapshots saved before `infusionNumber` existed. Mirrors `ActiveTimerSnapshot`.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        sessionID = try container.decode(UUID.self, forKey: .sessionID)
        tea = try container.decode(WidgetTea.self, forKey: .tea)
        state = try container.decode(WidgetActiveTimerState.self, forKey: .state)
        startedAt = try container.decode(Date.self, forKey: .startedAt)
        hapticStyle = try container.decode(WidgetHapticStyle.self, forKey: .hapticStyle)
        soundEnabled = try container.decode(Bool.self, forKey: .soundEnabled)
        durationSeconds = try container.decode(Int.self, forKey: .durationSeconds)
        secondsRemaining = try container.decode(Int.self, forKey: .secondsRemaining)
        endDate = try container.decodeIfPresent(Date.self, forKey: .endDate)
        pausedRemainingSeconds = try container.decode(Int.self, forKey: .pausedRemainingSeconds)
        infusionNumber = max(1, try container.decodeIfPresent(Int.self, forKey: .infusionNumber) ?? 1)
    }

    init(
        sessionID: UUID,
        tea: WidgetTea,
        state: WidgetActiveTimerState,
        startedAt: Date,
        hapticStyle: WidgetHapticStyle,
        soundEnabled: Bool,
        durationSeconds: Int,
        secondsRemaining: Int,
        endDate: Date?,
        pausedRemainingSeconds: Int,
        infusionNumber: Int = 1
    ) {
        self.sessionID = sessionID
        self.tea = tea
        self.state = state
        self.startedAt = startedAt
        self.hapticStyle = hapticStyle
        self.soundEnabled = soundEnabled
        self.durationSeconds = durationSeconds
        self.secondsRemaining = secondsRemaining
        self.endDate = endDate
        self.pausedRemainingSeconds = pausedRemainingSeconds
        self.infusionNumber = max(1, infusionNumber)
    }

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
            let data = UserDefaults(suiteName: "group.com.maskedsyntax.steepr")?.data(forKey: storageKey),
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
        UserDefaults(suiteName: "group.com.maskedsyntax.steepr")?.removeObject(forKey: storageKey)
        notifySharedTimerDidChange()
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
        UserDefaults(suiteName: "group.com.maskedsyntax.steepr")?.set(data, forKey: storageKey)
        notifySharedTimerDidChange()
    }

    private static func notifySharedTimerDidChange() {
        CFNotificationCenterPostNotification(
            CFNotificationCenterGetDarwinNotifyCenter(),
            CFNotificationName(sharedTimerDidChangeNotification as CFString),
            nil,
            nil,
            true
        )
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
            let data = UserDefaults(suiteName: "group.com.maskedsyntax.steepr")?.data(forKey: storageKey),
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
            let data = UserDefaults(suiteName: "group.com.maskedsyntax.steepr")?.data(forKey: storageKey),
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

    var tintColor: Color {
        switch colorSlot {
        case .green:
            return Color(red: 0.25, green: 0.62, blue: 0.36)
        case .black:
            return Color(red: 0.60, green: 0.42, blue: 0.25)
        case .oolong:
            return Color(red: 0.85, green: 0.45, blue: 0.18)
        case .white:
            return Color(red: 0.72, green: 0.62, blue: 0.42)
        case .herbal:
            return Color(red: 0.66, green: 0.35, blue: 0.68)
        case .chai:
            return Color(red: 0.78, green: 0.31, blue: 0.18)
        case .puerh:
            return Color(red: 0.45, green: 0.25, blue: 0.16)
        case .matcha:
            return Color(red: 0.47, green: 0.70, blue: 0.22)
        case .customA:
            return Color(red: 0.24, green: 0.50, blue: 0.84)
        case .customB:
            return Color(red: 0.75, green: 0.38, blue: 0.50)
        }
    }

    var quickBrewURL: URL {
        URL(string: "steepr://quick-brew/\(id.uuidString)")!
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

private enum WidgetTimerControlURL {
    static let pause = URL(string: "steepr://timer/pause")!
    static let stop = URL(string: "steepr://timer/stop")!
}

struct PauseBrewTimerIntent: AppIntent {
    static var title: LocalizedStringResource = "Pause Brew Timer"
    static var description = IntentDescription("Pauses the active Steepr timer.")
    static var openAppWhenRun = false

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard let snapshot = WidgetActiveTimerSnapshot.pause() else {
            return .result(dialog: "No running tea timer.")
        }

        removePendingTimerNotifications()
        await updateLiveActivity(snapshot: snapshot)
        WidgetCenter.shared.reloadAllTimelines()
        return .result(dialog: "\(snapshot.tea.name) paused.")
    }
}

struct CancelBrewTimerIntent: AppIntent {
    static var title: LocalizedStringResource = "Cancel Brew Timer"
    static var description = IntentDescription("Cancels the active Steepr timer.")
    static var openAppWhenRun = false

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let teaName = WidgetActiveTimerSnapshot.load()?.tea.name
        WidgetActiveTimerSnapshot.cancel()
        removePendingTimerNotifications()
        await endLiveActivities()
        WidgetCenter.shared.reloadAllTimelines()

        if let teaName {
            return .result(dialog: "\(teaName) stopped.")
        }
        return .result(dialog: "No active tea timer.")
    }
}

private func removePendingTimerNotifications() {
    UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [
        "steepr.brew.complete",
        "steepr.brew.pre-alert"
    ])
}

private func updateLiveActivity(snapshot: WidgetActiveTimerSnapshot) async {
    let state = SteeprLiveActivityAttributes.ContentState(
        state: snapshot.state.rawValue,
        endDate: snapshot.endDate,
        secondsRemaining: snapshot.currentSecondsRemaining,
        progress: snapshot.progress
    )
    let content = ActivityContent(state: state, staleDate: snapshot.endDate)

    let matchingActivities = Activity<SteeprLiveActivityAttributes>.activities.filter {
        $0.attributes.sessionID == snapshot.sessionID
    }
    let activities = matchingActivities.isEmpty ? Activity<SteeprLiveActivityAttributes>.activities : matchingActivities

    for activity in activities {
        await activity.update(content)
    }
}

private func endLiveActivities() async {
    for activity in Activity<SteeprLiveActivityAttributes>.activities {
        await activity.end(nil, dismissalPolicy: .immediate)
    }
}
