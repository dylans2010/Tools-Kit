import SwiftUI

struct SpreadsheetToolbarView: View {
    let onAddRow: () -> Void
    let onAddColumn: () -> Void
    let onDeleteRow: () -> Void
    let onDeleteColumn: () -> Void
    let onAI: () -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                toolbarButton("Add Row", icon: "plus.rectangle", action: onAddRow)
                toolbarButton("Add Column", icon: "rectangle.badge.plus", action: onAddColumn)
                Divider().frame(height: 22)
                toolbarButton("Del Row", icon: "minus.rectangle", action: onDeleteRow)
                toolbarButton("Del Column", icon: "rectangle.badge.minus", action: onDeleteColumn)
                Divider().frame(height: 22)
                toolbarButton("AI Tools", icon: "sparkles", action: onAI, color: .purple)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
        }
        .background(Color(.systemGray6))
        .overlay(Divider(), alignment: .bottom)
    }

    private func toolbarButton(_ title: String, icon: String, action: @escaping () -> Void, color: Color = .primary) -> some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                Text(title).font(.caption)
            }
            .foregroundColor(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color(.systemBackground))
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}
