import SwiftUI

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

struct TimerRingView: View {
    let progress: Double
    let timeText: String
    let color: Color

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.16), lineWidth: 12)

            Circle()
                .trim(from: 0, to: max(0, min(1, progress)))
                .stroke(style: StrokeStyle(lineWidth: 12, lineCap: .round, lineJoin: .round))
                .foregroundStyle(color)
                .rotationEffect(.degrees(-90))
                .animation(reduceMotion ? nil : .linear(duration: 1), value: progress)

            Text(timeText)
                .font(.system(size: 72, weight: .bold, design: .rounded).monospacedDigit())
                .minimumScaleFactor(0.62)
                .lineLimit(1)
                .padding(.horizontal, 28)
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

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
