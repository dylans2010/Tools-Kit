import SwiftUI

struct StorageAnalyzerView: View {
    @StateObject private var backend = StorageAnalyzerBackend()

    var body: some View {
        ToolDetailView(tool: StorageAnalyzerTool()) {
            VStack(spacing: 24) {
                // Usage Bar
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Usage")
                            .font(.headline)
                        Spacer()
                        Text("\(backend.format(backend.usedSpace)) of \(backend.format(backend.totalCapacity))")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.secondary.opacity(0.2))

                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.blue)
                                .frame(width: geo.size.width * CGFloat(Double(backend.usedSpace) / Double(backend.totalCapacity)))
                        }
                    }
                    .frame(height: 16)
                }

                ToolInputSection("Details") {
                    HStack {
                        Text("Available Space")
                        Spacer()
                        Text(backend.format(backend.freeSpace))
                            .bold()
                            .foregroundColor(.green)
                    }
                    .padding()

                    Divider()

                    HStack {
                        Text("Used Space")
                        Spacer()
                        Text(backend.format(backend.usedSpace))
                            .bold()
                    }
                    .padding()
                }
            }
        }
        .onAppear { backend.refresh() }
    }
}

struct StorageAnalyzerTool: Tool {
    let name = "Storage Analyzer"
    let icon = "internaldrive"
    let category = ToolCategory.utility
    let complexity = ToolComplexity.basic
    let description = "Visualize and manage your device's storage space"
    let requiresAPI = false
    var view: AnyView { AnyView(StorageAnalyzerView()) }
}
