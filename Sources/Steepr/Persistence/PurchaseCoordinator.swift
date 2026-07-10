import Combine
import Foundation
import StoreKit

@MainActor
final class PurchaseCoordinator: ObservableObject {
    static let proProductID = "com.maskedsyntax.steepr.pro"

    @Published private(set) var proProduct: Product?
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    private var transactionUpdatesTask: Task<Void, Never>?

    deinit {
        transactionUpdatesTask?.cancel()
    }

    func startTransactionUpdatesListener(store: TeaStore, brewSessionStore: BrewSessionStore? = nil) {
        guard transactionUpdatesTask == nil else { return }

        transactionUpdatesTask = Task { [weak self, weak store, weak brewSessionStore] in
            for await result in Transaction.updates {
                guard !Task.isCancelled else { return }
                await self?.handle(transactionResult: result, store: store, brewSessionStore: brewSessionStore)
            }
        }
    }

    func refreshEntitlements(store: TeaStore, brewSessionStore: BrewSessionStore? = nil) async {
        var hasPro = false
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }
            if transaction.productID == Self.proProductID {
                hasPro = true
            }
        }
        store.preferences.proPurchased = hasPro
        if hasPro {
            store.enableCloudSyncIfNeeded()
            brewSessionStore?.enableCloudSyncIfNeeded()
        }
    }

    func loadProducts() async {
        guard proProduct == nil else { return }
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }

        do {
            proProduct = try await Product.products(for: [Self.proProductID]).first
        } catch {
            errorMessage = "Could not load Steepr Pro."
        }
    }

    func purchasePro(store: TeaStore, brewSessionStore: BrewSessionStore? = nil) async {
        errorMessage = nil
        await loadProducts()
        guard let proProduct else {
            errorMessage = "Steepr Pro is not available right now."
            return
        }

        do {
            let result = try await proProduct.purchase()
            switch result {
            case .success(let verification):
                guard case .verified(let transaction) = verification else {
                    errorMessage = "The purchase could not be verified."
                    return
                }
                await unlockPro(for: transaction, store: store, brewSessionStore: brewSessionStore)
            case .pending:
                errorMessage = "The purchase is pending approval."
            case .userCancelled:
                break
            @unknown default:
                errorMessage = "The purchase could not be completed."
            }
        } catch {
            errorMessage = "The purchase could not be completed."
        }
    }

    func restorePurchases(store: TeaStore, brewSessionStore: BrewSessionStore? = nil) async {
        do {
            try await AppStore.sync()
            await refreshEntitlements(store: store, brewSessionStore: brewSessionStore)
        } catch {
            errorMessage = "Could not restore purchases."
        }
    }

    var priceText: String {
        proProduct?.displayPrice ?? "$2.99"
    }

    private func handle(
        transactionResult result: VerificationResult<Transaction>,
        store: TeaStore?,
        brewSessionStore: BrewSessionStore?
    ) async {
        guard let store else { return }

        switch result {
        case .verified(let transaction):
            guard transaction.productID == Self.proProductID else {
                await transaction.finish()
                return
            }
            await unlockPro(for: transaction, store: store, brewSessionStore: brewSessionStore)
        case .unverified:
            errorMessage = "A purchase update could not be verified."
        }
    }

    private func unlockPro(
        for transaction: Transaction,
        store: TeaStore,
        brewSessionStore: BrewSessionStore?
    ) async {
        store.preferences.proPurchased = true
        store.enableCloudSyncIfNeeded()
        brewSessionStore?.enableCloudSyncIfNeeded()
        await transaction.finish()
    }
}
