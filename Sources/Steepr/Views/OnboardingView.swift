import SwiftUI
import UserNotifications

struct OnboardingView: View {
    @EnvironmentObject private var teaStore: TeaStore
    @EnvironmentObject private var brewSessionStore: BrewSessionStore
    @EnvironmentObject private var purchaseCoordinator: PurchaseCoordinator
    @Environment(\.dismiss) private var dismiss
    @State private var page = 0

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        NavigationStack {
            TabView(selection: $page) {
                welcomePage.tag(0)
                favoritesPage.tag(1)
                proPage.tag(2)
                notificationsPage.tag(3)
            }
            #if os(iOS)
            .tabViewStyle(.page(indexDisplayMode: .never))
            #endif
            .safeAreaInset(edge: .bottom) {
                PageDots(count: 4, currentPage: page)
                    .padding(.bottom, 8)
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Skip") { finish() }
                }
            }
            .task {
                await purchaseCoordinator.loadProducts()
            }
        }
    }

    // MARK: - Pages

    private var welcomePage: some View {
        GeometryReader { proxy in
            let compact = proxy.size.height < 720

            VStack(spacing: compact ? 14 : 22) {
                Spacer(minLength: 0)

                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(TeaColorSlot.green.color.opacity(0.12))
                            .frame(width: compact ? 96 : 120, height: compact ? 96 : 120)
                        Image("SteeprLogo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: compact ? 62 : 78, height: compact ? 62 : 78)
                            .clipShape(RoundedRectangle(cornerRadius: compact ? 14 : 18, style: .continuous))
                    }

                    VStack(spacing: 8) {
                        Text("Steepr")
                            .font((compact ? Font.title : .largeTitle).bold())
                        Text("A calmer way to make tea.")
                            .font(compact ? .body : .title3)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .frame(maxWidth: .infinity)

                LazyVGrid(columns: columns, spacing: compact ? 10 : 12) {
                    OnboardingFeatureCard(title: "Heat", detail: "Use the right temperature", symbol: "thermometer.medium")
                    OnboardingFeatureCard(title: "Steep", detail: "Let the timer hold the moment", symbol: "timer")
                    OnboardingFeatureCard(title: "Sip", detail: "Get a gentle alert", symbol: "cup.and.saucer.fill")
                    OnboardingFeatureCard(title: "Repeat", detail: "Guide second cups", symbol: "arrow.clockwise")
                }
                .padding(.horizontal)
                .environment(\.onboardingCompactLayout, compact)

                Spacer(minLength: 0)

                Button("Get started") {
                    page = 1
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .frame(maxWidth: .infinity)
                .padding(.horizontal)
                .padding(.bottom, compact ? 20 : 30)
            }
        }
    }

    private var favoritesPage: some View {
        GeometryReader { proxy in
            let compact = proxy.size.height < 720

            VStack(spacing: 0) {
                Spacer(minLength: 0)

                VStack(spacing: compact ? 14 : 20) {
                    VStack(spacing: 6) {
                        Text("Choose your first shelf.")
                            .font((compact ? Font.title2 : .largeTitle).bold())
                            .multilineTextAlignment(.center)
                        Text("Favorites stay close on Brew and Apple Watch, so your usual cup is always one tap away.")
                            .font(compact ? .subheadline : .body)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    LazyVGrid(columns: columns, spacing: compact ? 8 : 12) {
                        ForEach(teaStore.builtInTeas) { tea in
                            Button {
                                teaStore.toggleFavorite(tea)
                            } label: {
                                OnboardingTeaSelectionRow(tea: tea, isSelected: tea.isFavorite)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .environment(\.onboardingCompactLayout, compact)
                }
                .padding(compact ? 14 : 16)

                Spacer(minLength: 0)

                Button("Continue") {
                    page = 2
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(teaStore.favoriteTeas.isEmpty)
                .frame(maxWidth: .infinity)
                .padding(compact ? 14 : 16)
            }
        }
    }

    private var proPage: some View {
        GeometryReader { proxy in
            let compact = proxy.size.height < 720

            VStack(spacing: compact ? 14 : 20) {
                Spacer(minLength: 0)

                VStack(spacing: compact ? 14 : 20) {
                    VStack(spacing: 8) {
                        Text("Make Steepr yours.")
                            .font((compact ? Font.title2 : .largeTitle).bold())
                            .multilineTextAlignment(.center)
                        Text("Pro is a one-time unlock for people who brew often and want their tea routine to stay effortless.")
                            .font(compact ? .subheadline : .title3)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    LazyVGrid(columns: columns, spacing: compact ? 10 : 12) {
                        OnboardingFeatureCard(title: "Unlimited teas", detail: "Save every loose leaf, blend, and recipe.", symbol: "plus.circle.fill")
                        OnboardingFeatureCard(title: "Brew journal", detail: "Keep tasting notes and brew history.", symbol: "clock.arrow.circlepath")
                        OnboardingFeatureCard(title: "iCloud sync", detail: "Carry your shelf across every device.", symbol: "icloud.fill")
                        OnboardingFeatureCard(title: "Guided re-steeps", detail: "Adjust later infusions automatically.", symbol: "arrow.clockwise")
                    }
                    .environment(\.onboardingCompactLayout, compact)
                }
                .padding(.horizontal, compact ? 14 : 16)

                Spacer(minLength: 0)

                VStack(spacing: compact ? 8 : 12) {
                    HStack(alignment: .firstTextBaseline) {
                        Text("Steepr Pro")
                            .font((compact ? Font.title3 : .title2).bold())
                        Spacer()
                        Text(purchaseCoordinator.priceText)
                            .font((compact ? Font.title3 : .title).bold())
                            .foregroundStyle(TeaColorSlot.green.color)
                    }
                    Text("One purchase. Family Sharing supported. No subscription.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Button {
                        Task {
                            await purchaseCoordinator.purchasePro(store: teaStore, brewSessionStore: brewSessionStore)
                            if teaStore.preferences.proPurchased {
                                page = 3
                            }
                        }
                    } label: {
                        if purchaseCoordinator.isLoading {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("Unlock Pro - \(purchaseCoordinator.priceText)")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .disabled(purchaseCoordinator.isLoading)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)

                    Button("Continue free") {
                        page = 3
                    }
                    .frame(maxWidth: .infinity)

                    if let errorMessage = purchaseCoordinator.errorMessage {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(compact ? 12 : 16)
                .background(.thinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .padding(.horizontal, compact ? 28 : 32)
                .padding(.bottom, compact ? 14 : 16)
            }
        }
    }

    private var notificationsPage: some View {
        GeometryReader { proxy in
            let compact = proxy.size.height < 720

            VStack(spacing: 0) {
                Spacer(minLength: 0)

                VStack(spacing: compact ? 18 : 24) {
                    ZStack {
                        Circle()
                            .fill(TeaColorSlot.green.color.opacity(0.12))
                            .frame(width: compact ? 88 : 112, height: compact ? 88 : 112)
                        Image(systemName: "bell.badge.fill")
                            .font(.system(size: compact ? 38 : 48, weight: .medium))
                            .foregroundStyle(TeaColorSlot.green.color)
                    }
                    .padding(.top, compact ? 18 : 36)
                    .frame(maxWidth: .infinity)

                    VStack(spacing: 8) {
                        Text("Know the moment it is ready.")
                            .font((compact ? Font.title2 : .largeTitle).bold())
                            .multilineTextAlignment(.center)
                        Text("Let Steepr alert you gently, even when your screen is locked.")
                            .font(compact ? .body : .title3)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    VStack(spacing: compact ? 12 : 16) {
                        NotificationBenefitRow(
                            title: "Step away",
                            detail: "Start a timer and leave your phone locked. Steepr will tell you when the next step needs you.",
                            symbol: "lock.fill"
                        )
                        NotificationBenefitRow(
                            title: "One alert",
                            detail: "No repeated reminders or noisy extras. Just the useful moment when your tea is ready.",
                            symbol: "speaker.wave.2.fill"
                        )
                    }
                    .frame(maxWidth: compact ? 420 : 460)
                    .padding(.horizontal, compact ? 28 : 36)
                    .environment(\.onboardingCompactLayout, compact)
                }
                .padding(compact ? 14 : 16)

                Spacer(minLength: 0)

                VStack(spacing: 12) {
                    Button("Allow notifications") {
                        requestNotifications()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .frame(maxWidth: .infinity)

                    Button("Not now") {
                        finish()
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(compact ? 14 : 16)
            }
        }
    }

    // MARK: - Actions

    private func requestNotifications() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, _ in
            DispatchQueue.main.async {
                teaStore.preferences.notificationsAuthorized = granted
                finish()
            }
        }
    }

    private func finish() {
        teaStore.setOnboardingComplete(true)
        dismiss()
    }
}

private struct OnboardingFeatureCard: View {
    @Environment(\.onboardingCompactLayout) private var compact
    let title: String
    let detail: String
    let symbol: String

    var body: some View {
        VStack(spacing: compact ? 7 : 10) {
            Image(systemName: symbol)
                .font(.system(size: compact ? 22 : 28, weight: .semibold))
                .foregroundStyle(TeaColorSlot.green.color)
                .frame(width: compact ? 40 : 48, height: compact ? 40 : 48)
                .background(TeaColorSlot.green.color.opacity(0.12))
                .clipShape(Circle())

            VStack(spacing: compact ? 3 : 5) {
                Text(title)
                    .font(compact ? .subheadline.weight(.semibold) : .headline)
                    .lineLimit(2)
                    .minimumScaleFactor(0.82)
                    .multilineTextAlignment(.center)
                Text(detail)
                    .font(compact ? .caption : .subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
                    .minimumScaleFactor(0.78)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(compact ? 10 : 14)
        .frame(maxWidth: .infinity)
        .frame(height: compact ? 132 : 156)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color.secondary.opacity(0.14), lineWidth: 1)
        }
    }
}

private struct OnboardingTeaSelectionRow: View {
    @Environment(\.onboardingCompactLayout) private var compact
    let tea: Tea
    let isSelected: Bool

    var body: some View {
        HStack(spacing: compact ? 8 : 10) {
            TeaIconView(tea: tea, size: compact ? 32 : 40)
            Text(tea.name)
                .font(compact ? .subheadline.weight(.semibold) : .headline)
                .lineLimit(1)
                .minimumScaleFactor(0.82)
            Spacer()
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .font(.body.weight(.semibold))
                .foregroundStyle(isSelected ? TeaColorSlot.green.color : .secondary)
        }
        .padding(compact ? 8 : 12)
        .frame(minHeight: compact ? 50 : 64)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(isSelected ? TeaColorSlot.green.color.opacity(0.45) : Color.secondary.opacity(0.18), lineWidth: 1)
        }
    }
}

private struct NotificationBenefitRow: View {
    @Environment(\.onboardingCompactLayout) private var compact
    let title: String
    let detail: String
    let symbol: String

    var body: some View {
        HStack(alignment: .top, spacing: compact ? 12 : 16) {
            Image(systemName: symbol)
                .font(.system(size: compact ? 22 : 26, weight: .semibold))
                .foregroundStyle(TeaColorSlot.green.color)
                .frame(width: compact ? 42 : 50, height: compact ? 42 : 50)
                .background(TeaColorSlot.green.color.opacity(0.12))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: compact ? 3 : 5) {
                Text(title)
                    .font(compact ? .headline : .title3.bold())
                Text(detail)
                    .font(compact ? .subheadline : .body)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct OnboardingCompactLayoutKey: EnvironmentKey {
    static let defaultValue = false
}

private extension EnvironmentValues {
    var onboardingCompactLayout: Bool {
        get { self[OnboardingCompactLayoutKey.self] }
        set { self[OnboardingCompactLayoutKey.self] = newValue }
    }
}

private struct PageDots: View {
    let count: Int
    let currentPage: Int

    var body: some View {
        HStack(spacing: 7) {
            ForEach(0..<count, id: \.self) { index in
                Capsule()
                    .fill(index == currentPage ? TeaColorSlot.green.color : Color.secondary.opacity(0.28))
                    .frame(width: index == currentPage ? 18 : 6, height: 6)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.thinMaterial)
        .clipShape(Capsule())
        .accessibilityHidden(true)
    }
}
