import SwiftUI

struct CurrencyStoreView: View {
    @StateObject private var ledger = CurrencyLedger.shared
    @ObservedObject var redemption = RedemptionEngine.shared
    @Environment(\.dismiss) private var dismiss
    @State private var showingInsufficientFunds = false
    @State private var failedItem: StoreItem?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    balanceHeader

                    ForEach(StoreSection.allCases) { section in
                        storeSection(section)
                    }
                }
                .padding(16)
            }
            .background(GamingDesignTokens.background.ignoresSafeArea())
            .navigationTitle("Currency Store")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(GamingDesignTokens.cardSurface, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(GamingDesignTokens.accentNeon)
                }
            }
        }
    }

    private var balanceHeader: some View {
        HStack(spacing: 20) {
            CurrencyBadgeView(icon: "dollarsign.circle.fill", value: ledger.profile.coins, color: GamingDesignTokens.accentGold)
            CurrencyBadgeView(icon: "diamond.fill", value: ledger.profile.gems, color: GamingDesignTokens.accentPurple)
        }
        .padding()
        .gamingCard()
    }

    private func storeSection(_ section: StoreSection) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(section.rawValue)
                .font(GamingDesignTokens.fontPrimary)
                .foregroundColor(.white)

            ForEach(StoreItem.items(in: section)) { item in
                storeItemRow(item)
            }
        }
    }

    private func storeItemRow(_ item: StoreItem) -> some View {
        HStack(spacing: 12) {
            Image(systemName: item.icon)
                .font(.title2)
                .foregroundColor(GamingDesignTokens.accentGold)
                .frame(width: 44, height: 44)
                .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
                Text(item.description)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
            }

            Spacer()

            if redemption.hasPurchased(item.id) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(GamingDesignTokens.successGreen)
            } else {
                Button {
                    attemptPurchase(item)
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: item.currency == .coins ? "dollarsign.circle.fill" : "diamond.fill")
                            .font(.caption)
                        Text("\(item.cost)")
                            .font(.caption.bold())
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(GamingDesignTokens.accentGold, in: Capsule())
                    .foregroundColor(.black)
                }
            }
        }
        .padding(12)
        .background(GamingDesignTokens.cardSurface, in: RoundedRectangle(cornerRadius: 12))
        .overlay {
            if showingInsufficientFunds, failedItem?.id == item.id {
                insufficientFundsOverlay(item)
            }
        }
    }

    private func insufficientFundsOverlay(_ item: StoreItem) -> some View {
        VStack(spacing: 8) {
            Text("Insufficient Funds")
                .font(.caption.bold())
                .foregroundColor(GamingDesignTokens.dangerRed)
            HStack {
                Text("Need: \(item.cost)")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.7))
                Text("Have: \(item.currency == .coins ? ledger.profile.coins : ledger.profile.gems)")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.7))
            }
            Button("Earn More") {
                showingInsufficientFunds = false
                dismiss()
            }
            .font(.caption.bold())
            .foregroundColor(.black)
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
            .background(GamingDesignTokens.accentNeon, in: Capsule())
        }
        .padding(12)
        .background(GamingDesignTokens.cardSurface.opacity(0.95), in: RoundedRectangle(cornerRadius: 12))
    }

    private func attemptPurchase(_ item: StoreItem) {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()

        let success = redemption.purchase(item: item)
        if !success {
            failedItem = item
            showingInsufficientFunds = true
        } else {
            ledger.reload()
        }
    }
}
