import SwiftUI

struct DrawingBackgroundSelectorView: View {
    @Binding var backgroundStyle: DrawingBoardView.CanvasBackground

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Canvas Background", systemImage: "square.grid.3x3")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            Picker("Background", selection: $backgroundStyle) {
                ForEach(DrawingBoardView.CanvasBackground.allCases) { style in
                    Text(style.rawValue).tag(style)
                }
            }
            .pickerStyle(.segmented)
        }
    }
}
