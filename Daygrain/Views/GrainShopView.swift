import SwiftUI

@MainActor
struct GrainShopView: View {
    @ObservedObject private var ledger = GrainLedger.shared
    @ObservedObject private var shop = GrainShop.shared
    @State private var confirmOffer: GrainOffer?
    @State private var busyId: String?
    @State private var notice: String?
    @State private var error: String?

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 22) {
                balanceHeader
                Text("Buy \(GrainCatalog.currencyName.lowercased()) for cloud AI shaping. Packs are consumable and used only inside Daygrain.")
                    .font(.subheadline)
                    .foregroundColor(Palette.secondary)
                ForEach(GrainCatalog.grouped, id: \.title) { group in
                    VStack(alignment: .leading, spacing: 12) {
                        Text(group.title.uppercased())
                            .font(.system(size: 10, weight: .semibold, design: .rounded))
                            .tracking(1.4)
                            .foregroundColor(Palette.secondary)
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            ForEach(group.items) { offer in
                                offerCard(offer)
                            }
                        }
                    }
                }
            }
            .padding(22)
            .frame(maxWidth: 760)
            .frame(maxWidth: .infinity)
        }
        .pageBackground()
        .navigationTitle("Grain Shop")
        .navigationBarTitleDisplayMode(.inline)
        .task { await shop.prepareIfNeeded() }
        .confirmationDialog("Confirm purchase", isPresented: Binding(
            get: { confirmOffer != nil },
            set: { if !$0 { confirmOffer = nil } }
        ), titleVisibility: .visible) {
            if let offer = confirmOffer {
                Button("Buy \(shop.displayPrice(for: offer))") {
                    Task { await buy(offer) }
                }
                Button("Cancel", role: .cancel) { confirmOffer = nil }
            }
        } message: {
            if let offer = confirmOffer {
                Text("Add \(offer.grainCount) \(GrainCatalog.currencyName.lowercased()) to your balance.")
            }
        }
        .alert("All set", isPresented: Binding(get: { notice != nil }, set: { if !$0 { notice = nil } })) {
            Button("OK", role: .cancel) { notice = nil }
        } message: { Text(notice ?? "") }
        .alert("Could not finish", isPresented: Binding(get: { error != nil }, set: { if !$0 { error = nil } })) {
            Button("OK", role: .cancel) { error = nil }
        } message: { Text(error ?? "") }
    }

    private var balanceHeader: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle().fill(Palette.gold.opacity(0.22))
                Image(systemName: "leaf.fill").foregroundColor(Palette.accent)
            }
            .frame(width: 48, height: 48)
            VStack(alignment: .leading, spacing: 4) {
                Text("Your balance").font(.caption).foregroundColor(Palette.secondary)
                Text("\(ledger.balance) \(GrainCatalog.currencyName)")
                    .font(.system(size: 28, weight: .medium, design: .serif))
                    .foregroundColor(Palette.text)
            }
            Spacer()
        }
        .padding(16)
        .surface(tint: Palette.gold)
    }

    private func offerCard(_ offer: GrainOffer) -> some View {
        let busy = busyId != nil
        let thisBusy = busyId == offer.productId
        return Button {
            confirmOffer = offer
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(LinearGradient(colors: [Palette.pageApricot, Palette.hero], startPoint: .topLeading, endPoint: .bottomTrailing))
                    Image(systemName: offer.categoryKey == GrainCatalog.bloomBundleKey ? "sparkles" : "leaf.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(Palette.accent)
                }
                .frame(height: 72)
                Text("\(offer.grainCount)")
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                    .foregroundColor(Palette.text)
                Text(GrainCatalog.currencyName)
                    .font(.caption)
                    .foregroundColor(Palette.secondary)
                Text(shop.displayPrice(for: offer))
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(Palette.accent)
                if thisBusy {
                    ProgressView().frame(maxWidth: .infinity)
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .surface()
            .opacity(busy && !thisBusy ? 0.45 : 1)
        }
        .buttonStyle(.plain)
        .disabled(busy)
    }

    private func buy(_ offer: GrainOffer) async {
        confirmOffer = nil
        busyId = offer.productId
        defer { busyId = nil }
        let outcome = await shop.purchase(offer)
        switch outcome {
        case .success(let grains):
            notice = "Added \(grains) \(GrainCatalog.currencyName.lowercased())."
        case .cancelled:
            break
        case .pending:
            notice = "Purchase is pending approval."
        case .failed(let message):
            error = message
        }
    }
}

@MainActor
struct GrainBalanceChip: View {
    @ObservedObject private var ledger = GrainLedger.shared

    var body: some View {
        NavigationLink {
            GrainShopView()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "leaf.fill")
                Text("\(ledger.balance)")
            }
            .font(.system(size: 13, weight: .semibold, design: .rounded))
            .foregroundColor(Palette.accent)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Capsule().fill(Palette.gold.opacity(0.18)))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(ledger.balance) grains. Open grain shop.")
    }
}
