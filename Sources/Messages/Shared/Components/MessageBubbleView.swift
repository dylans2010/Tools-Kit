import SwiftUI

struct MessageBubbleView: View {
    let text: String
    let isFromMe: Bool

    var body: some View {
        HStack {
            if isFromMe { Spacer() }

            Text(text)
                .padding(10)
                .background(isFromMe ? Color.blue : Color.gray.opacity(0.2))
                .foregroundColor(isFromMe ? .white : .primary)
                .cornerRadius(15)

            if !isFromMe { Spacer() }
        }
        .padding(.horizontal)
    }
}
