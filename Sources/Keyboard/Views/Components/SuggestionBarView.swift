import SwiftUI

struct SuggestionBarView: View {
    @Binding var state: KeyboardState
    var onSelect: (Suggestion) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(state.suggestions) { suggestion in
                    Button {
                        onSelect(suggestion)
                    } label: {
                        HStack {
                            Image(systemName: "sparkles")
                            Text(suggestion.suggestedText)
                                .lineLimit(1)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(20)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .background(Color(uiColor: .systemBackground))
    }
}
