import SwiftUI

struct DrawingActionBarView: View {
    let canUndo: Bool
    let canRedo: Bool
    let canClear: Bool
    let canExport: Bool
    let onUndo: () -> Void
    let onRedo: () -> Void
    let onClear: () -> Void
    let onExport: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Button("Undo", action: onUndo)
                .disabled(!canUndo)
            Button("Redo", action: onRedo)
                .disabled(!canRedo)
            Button("Clear", role: .destructive, action: onClear)
                .disabled(!canClear)

            Spacer()

            Button {
                onExport()
            } label: {
                Label("Export PNG", systemImage: "square.and.arrow.up")
            }
            .buttonStyle(.borderedProminent)
            .disabled(!canExport)
        }
        .font(.subheadline.weight(.semibold))
    }
}
