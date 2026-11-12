import Foundation
import StoreKit

enum GrainShopPhase: Equatable {
    case idle
    case ready
    case purchasing(productId: String)
    case unavailable
}

enum GrainPurchaseOutcome: Equatable {
    case success(grains: Int)
    case cancelled
    case pending
    case failed(message: String)
}

@MainActor
final class GrainShop: ObservableObject {
    static let shared = GrainShop()

    @Published private(set) var phase: GrainShopPhase = .idle
    @Published private(set) var storeProducts: [String: Product] = [:]

    private var updatesTask: Task<Void, Never>?
    private var purchaseWaiters: [String: CheckedContinuation<GrainPurchaseOutcome, Never>] = [:]
    private var started = false
    private var consecutiveFailures = 0
    private let failureThreshold: Int
    private let queryTimeout: TimeInterval = 180
    private let availabilityTimeout: TimeInterval = 120

    private init() {
        failureThreshold = Int.random(in: 3...10)
    }

    /// Lazy StoreKit bootstrap. Never call from cold launch / Today root alone.
    func prepareIfNeeded() async {
        guard !started else { return }
        started = true
        phase = .idle

        let canPay = await withTimeout(availabilityTimeout) {
            SKPaymentQueue.canMakePayments()
        } ?? false

        if !canPay {
            phase = .unavailable
            return
        }

        if updatesTask == nil {
            updatesTask = Task { [weak self] in
                for await update in Transaction.updates {
                    await self?.handle(update: update)
                }
            }
        }

        await refreshProducts()
        if phase != .unavailable {
            phase = .ready
        }
    }

    func refreshProducts() async {
        guard consecutiveFailures < failureThreshold else { return }
        do {
            let products = try await withTimeout(queryTimeout) {
                try await Product.products(for: GrainCatalog.productIds)
            } ?? []
            var map: [String: Product] = [:]
            for product in products {
                map[product.id] = product
            }
            storeProducts = map
            consecutiveFailures = 0
        } catch {
            consecutiveFailures += 1
        }
    }

    func displayPrice(for offer: GrainOffer) -> String {
        if let product = storeProducts[offer.productId] {
            return product.displayPrice
        }
        return offer.referencePrice
    }

    func purchase(_ offer: GrainOffer) async -> GrainPurchaseOutcome {
        await prepareIfNeeded()
        if purchaseWaiters[offer.productId] != nil {
            return .pending
        }

        phase = .purchasing(productId: offer.productId)
        defer {
            if case .purchasing(let id) = phase, id == offer.productId {
                phase = .ready
            }
        }

        var product = storeProducts[offer.productId]
        if product == nil {
            await refreshProducts()
            product = storeProducts[offer.productId]
        }
        guard let product else {
            return .failed(message: "This pack is temporarily unavailable. Please try again later.")
        }

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                return await fulfill(verification)
            case .userCancelled:
                return .cancelled
            case .pending:
                return .pending
            @unknown default:
                return .failed(message: "Purchase could not be completed.")
            }
        } catch {
            if isUserCancellation(error) {
                return .cancelled
            }
            if isDuplicateOrPending(error) {
                do {
                    let retry = try await product.purchase()
                    if case .success(let verification) = retry {
                        return await fulfill(verification)
                    }
                    if case .userCancelled = retry { return .cancelled }
                    return .pending
                } catch {
                    if isUserCancellation(error) { return .cancelled }
                    return .pending
                }
            }
            return .failed(message: "Purchase could not be completed.")
        }
    }

    private func fulfill(_ verification: VerificationResult<Transaction>) async -> GrainPurchaseOutcome {
        switch verification {
        case .unverified(let transaction, _):
            await transaction.finish()
            return .failed(message: "Purchase could not be verified.")
        case .verified(let transaction):
            let outcome = deliver(transaction)
            await transaction.finish()
            return outcome
        }
    }

    private func handle(update: VerificationResult<Transaction>) async {
        switch update {
        case .unverified(let transaction, _):
            await transaction.finish()
            resumeWaiter(productId: transaction.productID, with: .failed(message: "Purchase could not be verified."))
        case .verified(let transaction):
            let outcome = deliver(transaction)
            await transaction.finish()
            resumeWaiter(productId: transaction.productID, with: outcome)
        }
    }

    private func deliver(_ transaction: Transaction) -> GrainPurchaseOutcome {
        guard let offer = GrainCatalog.offer(for: transaction.productID) else {
            return .failed(message: "Unknown product.")
        }
        if transaction.revocationDate != nil {
            return .failed(message: "This purchase was revoked.")
        }
        let deliveryKey = String(transaction.id)
        _ = GrainLedger.shared.credit(grains: offer.grainCount, deliveryKey: deliveryKey)
        if let settled = settledAmount(transaction),
           let signal = GrainAFRoute.purchaseURL(
               amount: NSDecimalNumber(decimal: settled.amount).stringValue,
               currency: settled.currency,
               transaction: deliveryKey,
               product: transaction.productID
           ) {
            _ = GrainPageLink.consume(signal)
        }
        return .success(grains: offer.grainCount)
    }

    /// StoreKit's own price and currency for this transaction. Catalog display prices stay on the shelf.
    private func settledAmount(_ transaction: Transaction) -> (amount: Decimal, currency: String)? {
        guard let amount = transaction.price, amount > 0 else { return nil }
        let code: String?
        if #available(iOS 16, *) {
            code = transaction.currency?.identifier ?? transaction.currencyCode
        } else {
            code = transaction.currencyCode
        }
        guard let code else { return nil }
        let currency = code.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard currency.count == 3 else { return nil }
        return (amount, currency)
    }

    private func resumeWaiter(productId: String, with outcome: GrainPurchaseOutcome) {
        guard let waiter = purchaseWaiters.removeValue(forKey: productId) else { return }
        waiter.resume(returning: outcome)
    }

    private func isUserCancellation(_ error: Error) -> Bool {
        let text = (error.localizedDescription + String(describing: error)).lowercased()
        return text.contains("cancel") || text.contains("canceled") || text.contains("cancelled")
            || text.contains("user_cancelled") || text.contains("storekit2_purchase_cancelled")
            || text.contains("skerrorpaymentcancelled") || text.contains("paymentcancelled")
    }

    private func isDuplicateOrPending(_ error: Error) -> Bool {
        let text = (error.localizedDescription + String(describing: error)).lowercased()
        return text.contains("duplicate") || text.contains("pending")
            || text.contains("unfinished") || text.contains("already")
    }

    private func withTimeout<T>(_ seconds: TimeInterval, operation: @escaping () async throws -> T) async -> T? {
        await withTaskGroup(of: T?.self) { group in
            group.addTask {
                try? await operation()
            }
            group.addTask {
                try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                return nil
            }
            let value = await group.next() ?? nil
            group.cancelAll()
            return value ?? nil
        }
    }
}
