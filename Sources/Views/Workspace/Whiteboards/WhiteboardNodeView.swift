import SwiftUI

struct WhiteboardNodeView: View {
    let node: WhiteboardNode

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(node.title)
                .font(.headline)
            Text(node.content)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(4)
        }
        .padding(10)
        .frame(width: 180)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(uiColor: .secondarySystemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(.quaternary, lineWidth: 1)
        )
    }
}
