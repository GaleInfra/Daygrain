import Foundation

@main
struct GrainAFRouteCheck {
    static func main() {
        expect(GrainAFRoute.nativeRegistration(httpStatus: 200)?.source == .native, "http 200 registers native")
        expect(GrainAFRoute.nativeRegistration(httpStatus: 480) == nil, "activity status is not native registration")
        expect(GrainAFRoute.nativeRegistration(httpStatus: 0) == nil, "transport failure is not native registration")
        expect(GrainAFRoute.nativeRegistration(httpStatus: 500) == nil, "server error is not native registration")

        let regist = URL(string: "daygrain-local://tilem1flig?ps1g199=regist")!
        let buySmall = URL(string: "daygrain-local://tilem1flig?ps1g199=buy&pfkiry3=1.50&p0h3vme=usd&podvilk=order-a&p7b76q1=sku-1")!
        let buyLarge = URL(string: "daygrain-local://tilem1flig?ps1g199=buy&pfkiry3=12.00&p0h3vme=EUR&podvilk=order-b&p7b76q1=sku-2")!
        let buyBare = URL(string: "daygrain-local://tilem1flig?ps1g199=buy&pfkiry3=4.00&p0h3vme=USD")!
        let other = URL(string: "daygrain-local://page?url=https://example.test")!
        let grainbook = URL(string: "grainbook://browser?url=https://example.test")!

        let registSignal = GrainAFRoute.decodeActivityURL(regist)
        expect(registSignal?.kind == .registration && registSignal?.source == .activity, "activity regist")
        let small = GrainAFRoute.decodeActivityURL(buySmall)
        let large = GrainAFRoute.decodeActivityURL(buyLarge)
        expect(small?.amount == Decimal(string: "1.50") && small?.currency == "USD" && small?.transactionId == "order-a", "amount 1.50")
        expect(large?.amount == Decimal(string: "12.00") && large?.currency == "EUR" && large?.productId == "sku-2", "amount 12.00")
        expect(small?.transactionId != large?.transactionId, "distinct transactions")
        expect(GrainAFRoute.decodeActivityURL(buyBare) == nil, "buy without transaction is not success")
        expect(GrainAFRoute.decodeActivityURL(other) == nil, "page open is not an event")
        expect(GrainAFRoute.decodeActivityURL(grainbook) == nil, "grainbook is not the attribution scheme")

        let login = URL(string: "daygrain-local://tilem1flig?ps1g199=login")!
        let order = URL(string: "daygrain-local://tilem1flig?ps1g199=order")!
        expect(GrainAFRoute.decodeActivityURL(login) == nil, "login is consumed and not sent")
        expect(GrainAFRoute.decodeActivityURL(order) == nil, "order is consumed and not sent")
        expect(GrainAFRoute.isActivityAction(login) && GrainAFRoute.isActivityAction(order), "login and order stay on the protocol")

        let nativePurchase = GrainAFRoute.purchaseURL(amount: "4.99", currency: "USD", transaction: "1001", product: "daygrain.pack")
        expect(
            nativePurchase?.absoluteString == "daygrain-local://tilem1flig?ps1g199=buy&pfkiry3=4.99&p0h3vme=USD&podvilk=1001&p7b76q1=daygrain.pack",
            "native purchase uses the protocol fields"
        )
        let nativePurchaseSignal = GrainAFRoute.decodeActivityURL(nativePurchase!)
        expect(nativePurchaseSignal?.source == .activity && nativePurchaseSignal?.kind == .purchase, "native purchase is a protocol buy")
        let protocolBuy = GrainAFRoute.token(for: nativePurchaseSignal!, nativeRegistration: "tp2iar", nativePurchase: "4clegu", nativeEnabled: false)
        expect(protocolBuy.sends && protocolBuy.token == GrainAFRoute.activityPurchaseToken, "protocol buy uses the ledger purchase token while native stays pending")

        let stay = GrainAFRoute.token(for: GrainAFRoute.nativeRegistration(httpStatus: 200)!, nativeRegistration: "tp2iar", nativePurchase: "4clegu", nativeEnabled: false)
        expect(stay.sends && stay.token == GrainAFRoute.loginEvent, "A-side stay logs af_login without the native switch")
        expect(GrainAFRoute.loggedEvent(for: GrainAFRoute.nativeRegistration(httpStatus: 200)!) == GrainAFRoute.loginEvent, "registration logs af_login")
        expect(GrainAFRoute.shouldMark(sends: stay.sends, alreadyMarked: true) == false, "second stay does not mark again")

        let heldPurchase = GrainSignal(source: .native, kind: .purchase, amount: Decimal(string: "4.99"), currency: "USD", transactionId: "1001", productId: "daygrain.pack")
        let held = GrainAFRoute.token(for: heldPurchase, nativeRegistration: "tp2iar", nativePurchase: "4clegu", nativeEnabled: false)
        expect(held.sends == false, "pending native purchase does not send")
        expect(GrainAFRoute.shouldMark(sends: held.sends, alreadyMarked: false) == false, "pending purchase does not consume the first mark")

        let activityReg = GrainAFRoute.token(for: registSignal!, nativeRegistration: "tp2iar", nativePurchase: "4clegu", nativeEnabled: false)
        expect(activityReg.sends, "activity regist still sends")
        expect(GrainAFRoute.loggedEvent(for: registSignal!) == GrainAFRoute.loginEvent, "activity regist logs af_login")
        let activityBuy = GrainAFRoute.token(for: small!, nativeRegistration: "tp2iar", nativePurchase: "4clegu", nativeEnabled: false)
        expect(activityBuy.sends && GrainAFRoute.loggedEvent(for: small!) == GrainAFRoute.purchaseEvent, "protocol buy logs af_purchase while native stays pending")

        let nativeKey = GrainAFRoute.purchaseMark(source: .native, transactionId: "order-a")
        let activityKey = GrainAFRoute.purchaseMark(source: .activity, transactionId: "order-a")
        expect(nativeKey == "studio|order-a" && activityKey == "vessel|order-a", "purchase marks are studio and vessel")
        expect(GrainAFRoute.purchaseAlreadyCovered(source: .native, transactionId: "order-a", seen: [activityKey]), "vessel purchase blocks a later studio report")
        expect(GrainAFRoute.settledPurchaseMark("daygrain.adjust.purchase.activity.order-a") == activityKey, "old activity mark settles to vessel")
        expect(GrainAFRoute.shouldMark(sends: true, alreadyMarked: true) == false, "second success does not mark again")
        expect(GrainAFRoute.registrationMark(.native) != GrainAFRoute.registrationMark(.activity), "registration marks are per source")
        print("grain-af-route ok")
    }
}

private func expect(_ condition: Bool, _ label: String) {
    if !condition {
        fputs("FAIL \(label)\n", stderr)
        exit(1)
    }
}
