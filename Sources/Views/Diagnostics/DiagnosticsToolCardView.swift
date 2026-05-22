import SwiftUI

struct DiagnosticsToolCardView: View {
    let tool: DiagnosticTool
    var namespace: Namespace.ID?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: tool.icon)
                    .font(.title2)
                    .foregroundStyle(tool.category.tint)
                    .frame(width: 38, height: 38)
                    .background(tool.category.tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))

                Text(tool.name)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            }

            Text(tool.description)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
    }
}
