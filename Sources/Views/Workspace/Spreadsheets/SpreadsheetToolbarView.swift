import SwiftUI

struct SpreadsheetToolbarView: View {
    let onAddRow: () -> Void
    let onAddColumn: () -> Void
    let onAI: () -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                toolbarButton(title: "Add Row", icon: "plus.row.fill", action: onAddRow)
                toolbarButton(title: "Add Col", icon: "plus.column.fill", action: onAddColumn)
                Divider().frame(height: 24).background(Color.white.opacity(0.1))
                toolbarButton(title: "AI Analysis", icon: "sparkles", action: onAI, color: .purple)
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.03))
    }

    private func toolbarButton(title: String, icon: String, action: @escaping () -> Void, color: Color = .blue) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                Text(title).font(.caption.bold())
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(color.opacity(0.1), in: Capsule())
            .foregroundStyle(color)
        }
        .buttonStyle(.plain)
    }
}
