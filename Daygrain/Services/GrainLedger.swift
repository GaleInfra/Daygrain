import Combine
import Foundation

@MainActor
final class GrainLedger: ObservableObject {
    static let shared = GrainLedger()

    @Published private(set) var balance: Int

    private let balanceKey = "daygrain.grain.balance"
    private let seededKey = "daygrain.grain.seeded"
    private let deliveredKey = "daygrain.grain.delivered"

    private init() {
        let defaults = UserDefaults.standard
        if defaults.bool(forKey: seededKey) {
            balance = defaults.integer(forKey: balanceKey)
        } else {
            balance = GrainCatalog.initialBalance
            defaults.set(balance, forKey: balanceKey)
            defaults.set(true, forKey: seededKey)
        }
    }

    @discardableResult
    func credit(grains: Int, deliveryKey: String) -> Bool {
        guard grains > 0 else { return false }
        var delivered = Set(UserDefaults.standard.stringArray(forKey: deliveredKey) ?? [])
        if delivered.contains(deliveryKey) {
            return false
        }
        delivered.insert(deliveryKey)
        balance += grains
        let defaults = UserDefaults.standard
        defaults.set(balance, forKey: balanceKey)
        defaults.set(Array(delivered), forKey: deliveredKey)
        return true
    }

    @discardableResult
    func spend(cost: Int = GrainCatalog.spendCost) -> Bool {
        guard balance >= cost else { return false }
        balance -= cost
        UserDefaults.standard.set(balance, forKey: balanceKey)
        return true
    }

    func hasDelivered(_ deliveryKey: String) -> Bool {
        let delivered = Set(UserDefaults.standard.stringArray(forKey: deliveredKey) ?? [])
        return delivered.contains(deliveryKey)
    }
}
