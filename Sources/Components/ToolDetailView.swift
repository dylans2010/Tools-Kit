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
                // Header Section
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 16) {
                        Image(systemName: tool.icon)
                            .font(.system(size: 32))
                            .foregroundColor(.blue)
                            .frame(width: 64, height: 64)
                            .background(Color.blue.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 16))

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
                .padding(.horizontal)

                Divider()
                    .padding(.horizontal)

                // Tool Content
                content
                    .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemGroupedBackground))
    }
}
