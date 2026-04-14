import SwiftUI

struct SpreadsheetToolbarView: View {
    // Structure
    let onAddRow: () -> Void
    let onAddColumn: () -> Void
    let onDeleteRow: () -> Void
    let onDeleteColumn: () -> Void
    // Formatting
    let onBold: () -> Void
    let onItalic: () -> Void
    // Alignment
    let onAlignLeft: () -> Void
    let onAlignCenter: () -> Void
    let onAlignRight: () -> Void
    // Number format
    let onFormatNumber: () -> Void
    let onFormatCurrency: () -> Void
    let onFormatPercentage: () -> Void
    let onFormatDate: () -> Void
    // Operations
    let onSum: () -> Void
    let onAverage: () -> Void
    let onClearCell: () -> Void
    // AI
    let onAI: () -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                Group {
                    toolbarButton("Add Row", icon: "plus.rectangle", action: onAddRow)
                    toolbarButton("Add Col", icon: "rectangle.badge.plus", action: onAddColumn)
                    toolbarButton("Del Row", icon: "minus.rectangle", action: onDeleteRow)
                    toolbarButton("Del Col", icon: "rectangle.badge.minus", action: onDeleteColumn)
                }
                Divider().frame(height: 22)
                Group {
                    toolbarButton("Bold", icon: "bold", action: onBold)
                    toolbarButton("Italic", icon: "italic", action: onItalic)
                }
                Divider().frame(height: 22)
                Group {
                    toolbarButton("Left", icon: "text.alignleft", action: onAlignLeft)
                    toolbarButton("Center", icon: "text.aligncenter", action: onAlignCenter)
                    toolbarButton("Right", icon: "text.alignright", action: onAlignRight)
                }
                Divider().frame(height: 22)
                Group {
                    toolbarButton("123", icon: "number", action: onFormatNumber)
                    toolbarButton("$", icon: "dollarsign.circle", action: onFormatCurrency, color: .green)
                    toolbarButton("%", icon: "percent", action: onFormatPercentage, color: .orange)
                    toolbarButton("Date", icon: "calendar", action: onFormatDate, color: .blue)
                }
                Divider().frame(height: 22)
                Group {
                    toolbarButton("Sum", icon: "sum", action: onSum, color: .indigo)
                    toolbarButton("Avg", icon: "function", action: onAverage, color: .indigo)
                    toolbarButton("Clear", icon: "xmark.rectangle", action: onClearCell, color: .red)
                }
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
