import SwiftUI

struct PaywallView: View {
    @EnvironmentObject private var teaStore: TeaStore
    @EnvironmentObject private var brewSessionStore: BrewSessionStore
    @EnvironmentObject private var purchaseCoordinator: PurchaseCoordinator
    @Environment(\.dismiss) private var dismiss

    let trigger: String

    var body: some View {
        NavigationStack {
            GeometryReader { proxy in
                let compact = proxy.size.height < 720
                let columns = [
                    GridItem(.flexible(), spacing: compact ? 10 : 12),
                    GridItem(.flexible(), spacing: compact ? 10 : 12)
                ]

                VStack(spacing: compact ? 12 : 18) {
                    Spacer(minLength: 0)

                    VStack(spacing: compact ? 10 : 14) {
                        ZStack {
                            Circle()
                                .fill(TeaColorSlot.green.color.opacity(0.13))
                                .frame(width: compact ? 70 : 88, height: compact ? 70 : 88)
                            Image(systemName: "sparkles")
                                .font(.system(size: compact ? 30 : 38, weight: .semibold))
                                .foregroundStyle(TeaColorSlot.green.color)
                        }

                        VStack(spacing: 6) {
                            Text("Steepr Pro")
                                .font((compact ? Font.title : .largeTitle).bold())
                                .multilineTextAlignment(.center)
                            Text("Save, sync, and repeat your best tea routines.")
                                .font(compact ? .subheadline : .title3)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }

                    LazyVGrid(columns: columns, spacing: compact ? 10 : 12) {
                        PaywallFeatureCard(symbol: "plus.circle.fill", title: "Unlimited teas", detail: "Save every loose leaf and recipe.")
                        PaywallFeatureCard(symbol: "clock.arrow.circlepath", title: "Brew journal", detail: "Keep tasting notes and history.")
                        PaywallFeatureCard(symbol: "arrow.clockwise", title: "Guided re-steeps", detail: "Later infusions adjust for you.")
                        PaywallFeatureCard(symbol: "icloud.fill", title: "iCloud sync", detail: "Carry your shelf across devices.")
                    }

                    Spacer(minLength: 0)

                    VStack(spacing: compact ? 9 : 12) {
                        HStack(alignment: .firstTextBaseline) {
                            VStack(alignment: .leading, spacing: 3) {
                                Text("One-time purchase")
                                    .font(compact ? .headline : .title3.bold())
                                Text("No subscription. Family Sharing supported.")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Text(purchaseCoordinator.priceText)
                                .font((compact ? Font.title3 : .title).bold())
                                .foregroundStyle(TeaColorSlot.green.color)
                        }

                        Button {
                            Task {
                                await purchaseCoordinator.purchasePro(store: teaStore, brewSessionStore: brewSessionStore)
                                if teaStore.preferences.proPurchased {
                                    dismiss()
                                }
                            }
                        } label: {
                            if purchaseCoordinator.isLoading {
                                ProgressView()
                                    .frame(maxWidth: .infinity)
                            } else {
                                Text("Unlock forever - \(purchaseCoordinator.priceText)")
                                    .frame(maxWidth: .infinity)
                            }
                        }
                        .disabled(purchaseCoordinator.isLoading)
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)

                        Button("Restore purchase") {
                            Task {
                                await purchaseCoordinator.restorePurchases(store: teaStore, brewSessionStore: brewSessionStore)
                                if teaStore.preferences.proPurchased {
                                    dismiss()
                                }
                            }
                        }
                        .font(.subheadline.weight(.medium))
                        .frame(maxWidth: .infinity)

                        if let errorMessage = purchaseCoordinator.errorMessage {
                            Text(errorMessage)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding(compact ? 14 : 16)
                    .background(.thinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .padding(.horizontal, compact ? 20 : 28)
                    .padding(.bottom, compact ? 10 : 16)
                }
                .padding(.horizontal, compact ? 16 : 24)
            }
            .navigationTitle(trigger)
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .task {
                await purchaseCoordinator.loadProducts()
            }
        }
    }
}

private struct PaywallFeatureCard: View {
    let symbol: String
    let title: String
    let detail: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: symbol)
                .font(.system(size: 23, weight: .semibold))
                .foregroundStyle(TeaColorSlot.green.color)
                .frame(width: 42, height: 42)
                .background(TeaColorSlot.green.color.opacity(0.12))
                .clipShape(Circle())

            VStack(spacing: 4) {
                Text(title)
                    .font(.headline)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
                Text(detail)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.82)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .frame(height: 126)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color.secondary.opacity(0.14), lineWidth: 1)
        }
    }
}
