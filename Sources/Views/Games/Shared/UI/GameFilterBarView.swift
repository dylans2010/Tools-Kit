import SwiftUI

struct GameFilterBarView: View {
    @Binding var selectedCategory: GameCategory?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                filterPill(label: "All", isSelected: selectedCategory == nil) {
                    selectedCategory = nil
                }
                ForEach(GameCategory.allCases) { cat in
                    filterPill(label: cat.filterLabel, isSelected: selectedCategory == cat) {
                        selectedCategory = cat
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }

    private func filterPill(label: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            withAnimation(.easeInOut(duration: 0.2)) { action() }
        }) {
            Text(label)
                .font(.caption.bold())
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .foregroundColor(isSelected ? .black : .white.opacity(0.8))
                .background(
                    Capsule().fill(isSelected ? GamingDesignTokens.accentNeon : Color.white.opacity(0.12))
                )
        }
        .buttonStyle(.plain)
    }
}
