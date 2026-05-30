import SwiftUI

struct PaywallView: View {
    @EnvironmentObject private var teaStore: TeaStore
    @EnvironmentObject private var brewSessionStore: BrewSessionStore
    @EnvironmentObject private var purchaseCoordinator: PurchaseCoordinator
    @Environment(\.dismiss) private var dismiss

    let trigger: String

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 24) {
                ZStack {
                    Circle()
                        .fill(TeaColorSlot.green.color.opacity(0.16))
                        .frame(width: 112, height: 112)
                    Image(systemName: "sparkles")
                        .font(.system(size: 46, weight: .medium))
                        .foregroundStyle(TeaColorSlot.green.color)
                }
                .frame(maxWidth: .infinity)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Steepr Pro")
                        .font(.largeTitle.bold())
                    Text("Unlock the extra room and polish for daily brewing.")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: 14) {
                    PaywallFeature(symbol: "icloud.fill", title: "iCloud sync", detail: "Keep teas, sessions, and preferences in sync.")
                    PaywallFeature(symbol: "plus.circle.fill", title: "Unlimited custom teas", detail: "Free includes three custom teas.")
                    PaywallFeature(symbol: "hand.tap.fill", title: "Advanced haptics", detail: "Use stronger completion feedback.")
                    PaywallFeature(symbol: "speaker.wave.2.fill", title: "More sounds", detail: "Choose from a wider set of calm alerts.")
                }

                Spacer()

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
                        Text("Buy Steepr Pro - \(purchaseCoordinator.priceText)")
                            .frame(maxWidth: .infinity)
                    }
                }
                .disabled(purchaseCoordinator.isLoading)
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                Button("Restore") {
                    Task {
                        await purchaseCoordinator.restorePurchases(store: teaStore, brewSessionStore: brewSessionStore)
                        if teaStore.preferences.proPurchased {
                            dismiss()
                        }
                    }
                }
                .frame(maxWidth: .infinity)

                if let errorMessage = purchaseCoordinator.errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                        .multilineTextAlignment(.center)
                }
            }
            .padding()
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

private struct PaywallFeature: View {
    let symbol: String
    let title: String
    let detail: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: symbol)
                .font(.title3)
                .foregroundStyle(TeaColorSlot.green.color)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.headline)
                Text(detail)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
