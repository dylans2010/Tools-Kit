import SwiftUI

struct CurrencyStoreView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var ledger = CurrencyLedger.shared
    @State private var showingInsufficientFunds: StoreItemModel?

    let items: [StoreItemModel] = [
        StoreItemModel(id: "cosmetic_border_1", name: "Neon Border", description: "A glowing neon border for your profile.", price: 200, currency: .coins, category: .cosmetics),
        StoreItemModel(id: "powerup_double_xp", name: "Double XP", description: "Double XP for 1 session.", price: 500, currency: .coins, category: .powerUps),
        StoreItemModel(id: "unlock_skin_1", name: "Cyber Skin", description: "Exclusive skin for Battlefield Commander.", price: 1000, currency: .coins, category: .unlockables),
        StoreItemModel(id: "gem_badge_nft", name: "Diamond Badge", description: "Exclusive badge for top players.", price: 5, currency: .gems, category: .gemRewards)
    ]

    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "#0D0D1A").ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        HUDOverlayView()

                        ForEach(StoreItemModel.StoreCategory.allCases, id: \.self) { category in
                            let categoryItems = items.filter { $0.category == category }
                            if !categoryItems.isEmpty {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text(category.rawValue)
                                        .font(.title3.bold())
                                        .foregroundColor(.white)
                                        .padding(.horizontal)

                                    ForEach(categoryItems) { item in
                                        StoreItemRow(item: item) {
                                            buy(item)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(.vertical)
                }

                if let item = showingInsufficientFunds {
                    InsufficientFundsView(item: item) {
                        showingInsufficientFunds = nil
                    }
                }
            }
            .navigationTitle("Currency Store")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func buy(_ item: StoreItemModel) {
        do {
            try RedemptionEngine.shared.purchase(item)
        } catch {
            withAnimation {
                showingInsufficientFunds = item
            }
        }
    }
}

struct StoreItemRow: View {
    let item: StoreItemModel
    let action: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name).font(.headline).foregroundColor(.white)
                Text(item.description).font(.caption).foregroundColor(.secondary)
            }
            Spacer()
            Button(action: action) {
                HStack(spacing: 4) {
                    Text("\(item.price)")
                    Image(systemName: item.currency == .coins ? "circle.fill" : "diamond.fill")
                        .foregroundColor(item.currency == .coins ? .yellow : .cyan)
                }
                .font(.system(.subheadline, design: .monospaced, weight: .bold))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color(hex: "#8A2BE2"))
                .cornerRadius(10)
            }
            .hapticTap()
        }
        .padding()
        .background(Color(hex: "#1A1A2E"))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

struct InsufficientFundsView: View {
    let item: StoreItemModel
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 50))
                .foregroundColor(.orange)

            Text("Insufficient Funds")
                .font(.title2.bold())
                .foregroundColor(.white)

            VStack(spacing: 8) {
                Text("You need \(item.price) \(item.currency == .coins ? "coins" : "gems") to buy this item.")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)

                HStack {
                    Text("Current Balance:")
                    Text("\(item.currency == .coins ? CurrencyLedger.shared.profile.coins : CurrencyLedger.shared.profile.gems)")
                        .bold()
                }
                .foregroundColor(.white)
            }

            Button {
                onDismiss()
                // Deep link logic would go here
            } label: {
                Text("Earn More")
                    .bold()
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.orange)
                    .foregroundColor(.black)
                    .cornerRadius(12)
            }

            Button("Cancel") { onDismiss() }
                .foregroundColor(.secondary)
        }
        .padding(30)
        .background(Color(hex: "#1A1A2E"))
        .cornerRadius(20)
        .padding(40)
        .transition(.scale.combined(with: .opacity))
    }
}
