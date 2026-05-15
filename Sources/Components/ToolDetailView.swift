import SwiftUI

struct ToolDetailView<Content: View>: View {
    let tool: any Tool
    let content: Content

    init(tool: any Tool, @ViewBuilder content: () -> Content) {
        self.tool = tool
        self.content = content()
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 16) {
                        Image(systemName: tool.icon)
                            .font(.system(size: 30, weight: .semibold))
                            .foregroundColor(.blue)
                            .frame(width: 58, height: 58)
                            .background(
                                LinearGradient(colors: [Color.blue.opacity(0.18), Color.cyan.opacity(0.18)], startPoint: .topLeading, endPoint: .bottomTrailing)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 14))

                        VStack(alignment: .leading, spacing: 4) {
                            Text(tool.name)
                                .font(.title.bold())

                            HStack {
                                Text(tool.category.rawValue)
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.blue.opacity(0.1))
                                    .foregroundColor(.blue)
                                    .cornerRadius(8)

                                Text(tool.complexity.rawValue)
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.secondary.opacity(0.1))
                                    .foregroundColor(.secondary)
                                    .cornerRadius(8)
                            }
                        }
                    }

                    Text(tool.description)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .padding(.top, 8)
                }
                .padding()
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .cornerRadius(16)
                .padding(.horizontal)

                content
                    .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(uiColor: .systemGroupedBackground))
    }
}
