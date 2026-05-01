import SwiftUI

struct ToneSelectorView: View {
    @Binding var state: KeyboardState

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                ForEach(RewriteStyle.allCases, id: \.self) { style in
                    Button {
                        state.toneMode = style
                    } label: {
                        Text(style.rawValue)
                            .font(.subheadline)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 6)
                            .background(state.toneMode == style ? Color.purple : Color.gray.opacity(0.2))
                            .foregroundColor(state.toneMode == style ? .white : .primary)
                            .cornerRadius(15)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .background(Color(uiColor: .systemBackground))
    }
}
