import SwiftUI

struct GameFilterBarView: View {
    @Binding var selectedCategory: GameCategory?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                FilterPill(title: "All", isSelected: selectedCategory == nil) {
                    selectedCategory = nil
                }

                ForEach(GameCategory.allCases, id: \.self) { category in
                    FilterPill(title: category.rawValue, isSelected: selectedCategory == category) {
                        selectedCategory = category
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}

struct FilterPill: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(.subheadline, design: .rounded, weight: .bold))
                .foregroundColor(isSelected ? .white : .secondary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color(hex: "#8A2BE2") : Color.white.opacity(0.1))
                .cornerRadius(20)
        }
        .hapticTap()
    }
}
