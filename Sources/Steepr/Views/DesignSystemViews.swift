import SwiftUI

// MARK: - Palette (light + dark)

enum SteeprPalette {
    /// Warm cream / deep forest charcoal — page backdrop.
    static let background = Color(light: "#F6F3EB", dark: "#121411")

    /// Elevated cards and pill surfaces.
    static let surface = Color(light: "#FFFEFA", dark: "#1C1F1A")

    /// Soft secondary surfaces (idle cards, control wells).
    static let surfaceMuted = Color(light: "#EFEBE2", dark: "#262A24")

    /// Circular progress track.
    static let ringTrack = Color(light: "#E2DDD2", dark: "#3A3F38")

    /// Primary body text.
    static let ink = Color(light: "#1A1C18", dark: "#F2F0E8")

    /// Secondary / caption text.
    static let inkSecondary = Color(light: "#6B7066", dark: "#A3A89E")

    /// Brand green for status, accents, progress.
    static let accent = Color(light: "#3F5F42", dark: "#7BA87E")

    /// Solid green for primary filled controls (pause).
    static let accentSolid = Color(light: "#2F4A32", dark: "#3F5F42")

    /// Soft control circle fill for secondary actions.
    static let controlFill = Color(light: "#EFEBE2", dark: "#2A2F29")

    /// Soft control stroke.
    static let controlStroke = Color(light: "#E0DBD0", dark: "#3E443C")

    /// Temperature icon accent.
    static let temperature = Color(light: "#D4783A", dark: "#E8914F")

    /// Hairline dividers.
    static let divider = Color(light: "#D9D4C8", dark: "#343930")
}

// MARK: - Tea icon

struct TeaIconView: View {
    let tea: Tea
    var size: CGFloat = 44

    var body: some View {
        ZStack {
            Circle()
                .fill(tea.colorSlot.color.opacity(0.16))
            Image(systemName: tea.symbolName)
                .font(.system(size: size * 0.42, weight: .medium))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(tea.colorSlot.color)
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

// MARK: - Timer ring

struct TimerRingView: View {
    let progress: Double
    let timeText: String
    let statusText: String
    let color: Color
    var showsLeafAccents: Bool = true

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let lineWidth: CGFloat = 14

    var body: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)
            let radius = side / 2
            // Sit just inside the ring stroke (inner edge of the track).
            let leafSize = max(11, side * 0.045)
            let leafOffset = radius - lineWidth - leafSize * 0.55

            ZStack {
                Circle()
                    .stroke(SteeprPalette.ringTrack, lineWidth: lineWidth)

                Circle()
                    .trim(from: 0, to: max(0, min(1, progress)))
                    .stroke(
                        color,
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(reduceMotion ? nil : .linear(duration: 1), value: progress)

                if showsLeafAccents {
                    leafAccent(size: leafSize)
                        .offset(y: -leafOffset)
                        .rotationEffect(.degrees(-28))
                    leafAccent(size: leafSize)
                        .offset(y: -leafOffset)
                        .rotationEffect(.degrees(28))
                }

                VStack(spacing: 6) {
                    Text(statusText)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(color)
                        .lineLimit(1)

                    Text(timeText)
                        .font(.system(size: min(64, side * 0.22), weight: .bold, design: .serif).monospacedDigit())
                        .foregroundStyle(SteeprPalette.ink)
                        .minimumScaleFactor(0.55)
                        .lineLimit(1)
                        .padding(.horizontal, 20)

                    Text("REMAINING")
                        .font(.caption.weight(.semibold))
                        .tracking(1.6)
                        .foregroundStyle(SteeprPalette.inkSecondary)
                }
                .padding(28)
            }
            .frame(width: side, height: side)
            .clipShape(Circle())
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(statusText), \(timeText) remaining")
    }

    private func leafAccent(size: CGFloat) -> some View {
        Image(systemName: "leaf.fill")
            .font(.system(size: size, weight: .semibold))
            .foregroundStyle(color.opacity(0.85))
            .rotationEffect(.degrees(-20))
    }
}

// MARK: - Meta info cards

struct BrewMetaCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.14))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(iconColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(SteeprPalette.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(SteeprPalette.inkSecondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(SteeprPalette.surface)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(SteeprPalette.controlStroke.opacity(0.7), lineWidth: 1)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title), \(subtitle)")
    }
}

// MARK: - Session control buttons

struct SessionControlButton: View {
    enum Style {
        case secondary
        case primary
    }

    let systemImage: String
    let label: String
    var style: Style = .secondary
    var isEnabled: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(fillColor)
                        .frame(width: diameter, height: diameter)
                        .overlay {
                            if style == .secondary {
                                Circle()
                                    .stroke(SteeprPalette.controlStroke, lineWidth: 1)
                            }
                        }
                        .shadow(
                            color: style == .primary ? SteeprPalette.accentSolid.opacity(0.28) : .clear,
                            radius: 10,
                            y: 4
                        )

                    Image(systemName: systemImage)
                        .font(.system(size: iconSize, weight: .semibold))
                        .foregroundStyle(iconColor)
                }

                Text(label)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(SteeprPalette.inkSecondary)
            }
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.45)
        .accessibilityLabel(label)
    }

    private var diameter: CGFloat {
        style == .primary ? 72 : 56
    }

    private var iconSize: CGFloat {
        style == .primary ? 24 : 18
    }

    private var fillColor: Color {
        switch style {
        case .primary: return SteeprPalette.accentSolid
        case .secondary: return SteeprPalette.controlFill
        }
    }

    private var iconColor: Color {
        switch style {
        case .primary: return Color(light: "#F6F3EB", dark: "#F2F0E8")
        case .secondary: return SteeprPalette.ink
        }
    }
}

struct SessionControlBar: View {
    let isRunning: Bool
    let onCancel: () -> Void
    let onTogglePause: () -> Void
    let onNext: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 28) {
            SessionControlButton(
                systemImage: "xmark",
                label: "Cancel",
                style: .secondary,
                action: onCancel
            )

            SessionControlButton(
                systemImage: isRunning ? "pause.fill" : "play.fill",
                label: isRunning ? "Pause" : "Resume",
                style: .primary,
                action: onTogglePause
            )

            SessionControlButton(
                systemImage: "chevron.right",
                label: "Next",
                style: .secondary,
                action: onNext
            )
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Active session header

struct ActiveSessionHeader: View {
    let tea: Tea
    let statusLine: String

    var body: some View {
        VStack(spacing: 14) {
            TeaIconView(tea: tea, size: 64)

            VStack(spacing: 8) {
                Text(tea.name)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(SteeprPalette.ink)
                    .multilineTextAlignment(.center)

                Capsule()
                    .fill(SteeprPalette.accent.opacity(0.55))
                    .frame(width: 36, height: 2)

                Text(statusLine)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(SteeprPalette.accent)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Shared helpers

struct TeaMetaLine: View {
    let tea: Tea
    let useCelsius: Bool

    var body: some View {
        HStack(spacing: 8) {
            Label(formatDuration(tea.steepSeconds), systemImage: "clock")
            Text("•")
            Label(formatTemperature(tea.temperatureCelsius, useCelsius: useCelsius), systemImage: "thermometer.medium")
        }
        .font(.footnote.weight(.medium))
        .foregroundStyle(.secondary)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(formatDuration(tea.steepSeconds)), \(formatTemperature(tea.temperatureCelsius, useCelsius: useCelsius))")
    }
}

func formatDuration(_ seconds: Int) -> String {
    let minutes = seconds / 60
    let remainingSeconds = seconds % 60
    if minutes == 0 {
        return "\(remainingSeconds)s"
    }
    if remainingSeconds == 0 {
        return "\(minutes)m"
    }
    return "\(minutes)m \(remainingSeconds)s"
}

func formatTemperature(_ celsius: Int, useCelsius: Bool) -> String {
    if useCelsius {
        return "\(celsius)°C"
    }
    let fahrenheit = Int((Double(celsius) * 9 / 5 + 32).rounded())
    return "\(fahrenheit)°F"
}
