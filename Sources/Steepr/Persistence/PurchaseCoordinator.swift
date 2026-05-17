import Combine
import Foundation
import StoreKit

@MainActor
final class PurchaseCoordinator: ObservableObject {
    static let proProductID = "com.steepr.app.pro"

    @Published private(set) var proProduct: Product?
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    func refreshEntitlements(store: TeaStore) async {
        var hasPro = false
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }
            if transaction.productID == Self.proProductID {
                hasPro = true
            }
        }
        store.preferences.proPurchased = hasPro
    }

    func loadProducts() async {
        guard proProduct == nil else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            proProduct = try await Product.products(for: [Self.proProductID]).first
        } catch {
            errorMessage = "Could not load Steepr Pro."
        }
    }

    func purchasePro(store: TeaStore) async {
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
                store.preferences.proPurchased = true
                await transaction.finish()
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

    func restorePurchases(store: TeaStore) async {
        do {
            try await AppStore.sync()
            await refreshEntitlements(store: store)
        } catch {
            errorMessage = "Could not restore purchases."
        }
    }

    var priceText: String {
        proProduct?.displayPrice ?? "$4.99"
    }
}
