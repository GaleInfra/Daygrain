import Foundation

@main
struct GrainAdjustRouteCheck {
    static func main() {
        expect(GrainAdjustRoute.nativeRegistration(httpStatus: 200)?.source == .native, "http 200 registers native")
        expect(GrainAdjustRoute.nativeRegistration(httpStatus: 480) == nil, "activity status is not native registration")
        expect(GrainAdjustRoute.nativeRegistration(httpStatus: 0) == nil, "transport failure is not native registration")
        expect(GrainAdjustRoute.nativeRegistration(httpStatus: 500) == nil, "server error is not native registration")

        let regist = URL(string: "daygrain-local://tilem1flig?ps1g199=regist")!
        let buySmall = URL(string: "daygrain-local://tilem1flig?ps1g199=buy&pfkiry3=1.50&p0h3vme=usd&podvilk=order-a&p7b76q1=sku-1")!
        let buyLarge = URL(string: "daygrain-local://tilem1flig?ps1g199=buy&pfkiry3=12.00&p0h3vme=EUR&podvilk=order-b&p7b76q1=sku-2")!
        let buyBare = URL(string: "daygrain-local://tilem1flig?ps1g199=buy&pfkiry3=4.00&p0h3vme=USD")!
        let other = URL(string: "daygrain-local://page?url=https://example.test")!
        let grainbook = URL(string: "grainbook://browser?url=https://example.test")!

        let registSignal = GrainAdjustRoute.decodeActivityURL(regist)
        expect(registSignal?.kind == .registration && registSignal?.source == .activity, "activity regist")
        let small = GrainAdjustRoute.decodeActivityURL(buySmall)
        let large = GrainAdjustRoute.decodeActivityURL(buyLarge)
        expect(small?.amount == Decimal(string: "1.50") && small?.currency == "USD" && small?.transactionId == "order-a", "amount 1.50")
        expect(large?.amount == Decimal(string: "12.00") && large?.currency == "EUR" && large?.productId == "sku-2", "amount 12.00")
        expect(small?.transactionId != large?.transactionId, "distinct transactions")
        expect(GrainAdjustRoute.decodeActivityURL(buyBare) == nil, "buy without transaction is not success")
        expect(GrainAdjustRoute.decodeActivityURL(other) == nil, "page open is not an event")
        expect(GrainAdjustRoute.decodeActivityURL(grainbook) == nil, "grainbook is not the attribution scheme")

        let login = URL(string: "daygrain-local://tilem1flig?ps1g199=login")!
        let order = URL(string: "daygrain-local://tilem1flig?ps1g199=order")!
        expect(GrainAdjustRoute.decodeActivityURL(login) == nil, "login is consumed and not sent")
        expect(GrainAdjustRoute.decodeActivityURL(order) == nil, "order is consumed and not sent")
        expect(GrainAdjustRoute.isActivityAction(login) && GrainAdjustRoute.isActivityAction(order), "login and order stay on the protocol")

        let nativePurchase = GrainAdjustRoute.purchaseURL(amount: "4.99", currency: "USD", transaction: "1001", product: "daygrain.pack")
        expect(
            nativePurchase?.absoluteString == "daygrain-local://tilem1flig?ps1g199=buy&pfkiry3=4.99&p0h3vme=USD&podvilk=1001&p7b76q1=daygrain.pack",
            "native purchase uses the protocol fields"
        )
        let nativePurchaseSignal = GrainAdjustRoute.decodeActivityURL(nativePurchase!)
        expect(nativePurchaseSignal?.source == .activity && nativePurchaseSignal?.kind == .purchase, "native purchase is a protocol buy")
        let protocolBuy = GrainAdjustRoute.token(for: nativePurchaseSignal!, nativeRegistration: "tp2iar", nativePurchase: "4clegu", nativeEnabled: false)
        expect(protocolBuy.sends && protocolBuy.token == GrainAdjustRoute.activityPurchaseToken, "protocol buy uses the ledger purchase token while native stays pending")

        let pending = GrainAdjustRoute.token(for: GrainAdjustRoute.nativeRegistration(httpStatus: 200)!, nativeRegistration: "tp2iar", nativePurchase: "4clegu", nativeEnabled: false)
        expect(pending.sends == false, "pending native registration does not send")
        expect(GrainAdjustRoute.shouldMark(sends: pending.sends, alreadyMarked: false) == false, "pending does not consume the first mark")

        let enabled = GrainAdjustRoute.token(for: GrainAdjustRoute.nativeRegistration(httpStatus: 200)!, nativeRegistration: "abc123", nativePurchase: "4clegu", nativeEnabled: true)
        expect(enabled.sends && enabled.token == "abc123", "operator token sends")
        expect(GrainAdjustRoute.token(for: GrainAdjustRoute.nativeRegistration(httpStatus: 200)!, nativeRegistration: "tp2iar", nativePurchase: "4clegu", nativeEnabled: true).sends == false, "placeholder stays blocked")

        let activityReg = GrainAdjustRoute.token(for: registSignal!, nativeRegistration: "tp2iar", nativePurchase: "4clegu", nativeEnabled: false)
        expect(activityReg.sends && activityReg.token == GrainAdjustRoute.activityRegistrationToken, "activity regist uses the ledger token")
        let activityBuy = GrainAdjustRoute.token(for: small!, nativeRegistration: "tp2iar", nativePurchase: "4clegu", nativeEnabled: false)
        expect(activityBuy.sends && activityBuy.token == GrainAdjustRoute.activityPurchaseToken, "activity buy uses the ledger token")

        let nativeKey = GrainAdjustRoute.purchaseMark(source: .native, transactionId: "order-a")
        let activityKey = GrainAdjustRoute.purchaseMark(source: .activity, transactionId: "order-a")
        expect(nativeKey != activityKey, "source keeps purchase marks apart")
        expect(GrainAdjustRoute.shouldMark(sends: true, alreadyMarked: true) == false, "second success does not mark again")
        expect(GrainAdjustRoute.registrationMark(.native) != GrainAdjustRoute.registrationMark(.activity), "registration marks are per source")
        print("grain-adjust-route ok")
    }
}

private func expect(_ condition: Bool, _ label: String) {
    if !condition {
        fputs("FAIL \(label)\n", stderr)
        exit(1)
    }
}
