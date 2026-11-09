import Foundation

struct GrainOffer: Identifiable, Equatable {
    let productId: String
    let grainCount: Int
    let referencePrice: String
    let categoryKey: String
    let categoryTitle: String
    var id: String { productId }
}

enum GrainCatalog {
    static let currencyName = "Grains"
    static let spendCost = 10
    static let initialBalance = 100
    static let fieldPackKey = "field_packs"
    static let bloomBundleKey = "bloom_bundles"
    static let spendNotice = "Shaping an entry with cloud AI uses \(spendCost) \(currencyName.lowercased()) each time."

    /// Delivery coin table (Daygrain.xlsx): 4 standard + 4 double packs.
    static let offers: [GrainOffer] = [
        GrainOffer(productId: "407903400", grainCount: 100, referencePrice: "$5.00", categoryKey: fieldPackKey, categoryTitle: "Field Packs"),
        GrainOffer(productId: "407903401", grainCount: 200, referencePrice: "$10.00", categoryKey: fieldPackKey, categoryTitle: "Field Packs"),
        GrainOffer(productId: "407903402", grainCount: 400, referencePrice: "$20.00", categoryKey: fieldPackKey, categoryTitle: "Field Packs"),
        GrainOffer(productId: "407903403", grainCount: 1000, referencePrice: "$50.00", categoryKey: fieldPackKey, categoryTitle: "Field Packs"),
        GrainOffer(productId: "407903404", grainCount: 200, referencePrice: "$5.00", categoryKey: bloomBundleKey, categoryTitle: "Double Blooms"),
        GrainOffer(productId: "407903405", grainCount: 400, referencePrice: "$10.00", categoryKey: bloomBundleKey, categoryTitle: "Double Blooms"),
        GrainOffer(productId: "407903406", grainCount: 800, referencePrice: "$20.00", categoryKey: bloomBundleKey, categoryTitle: "Double Blooms"),
        GrainOffer(productId: "407903407", grainCount: 2000, referencePrice: "$50.00", categoryKey: bloomBundleKey, categoryTitle: "Double Blooms")
    ]

    static var productIds: Set<String> { Set(offers.map(\.productId)) }

    static func offer(for productId: String) -> GrainOffer? {
        offers.first { $0.productId == productId }
    }

    static var grouped: [(title: String, items: [GrainOffer])] {
        [
            (title: "Field Packs", items: offers.filter { $0.categoryKey == fieldPackKey }),
            (title: "Double Blooms", items: offers.filter { $0.categoryKey == bloomBundleKey })
        ]
    }
}
