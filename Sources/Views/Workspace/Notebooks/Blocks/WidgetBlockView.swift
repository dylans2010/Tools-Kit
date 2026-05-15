import SwiftUI

struct WidgetBlockView: View {
    @Binding var block: NotebookBlock
    var onUpdate: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Interactive Widget")
                .font(.caption.bold())
                .foregroundStyle(.secondary)

            HStack(spacing: 15) {
                widgetButton(icon: "timer", label: "Timer")
                widgetButton(icon: "calendar", label: "Event")
                widgetButton(icon: "checkmark.seal.fill", label: "Status")
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(uiColor: .tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
    }

    private func widgetButton(icon: String, label: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.blue)
            Text(label)
                .font(.system(size: 10, weight: .bold))
        }
        .frame(width: 60, height: 60)
        .background(Color.workspaceSurface, in: RoundedRectangle(cornerRadius: 10))
    }
}
