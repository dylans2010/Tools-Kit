import SwiftUI

struct SideBySideDiffView: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Mock diff entry
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Notebooks/Research.swift")
                            .font(.caption.monospaced())
                            .padding(8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.workspaceSurface)

                        HStack(spacing: 0) {
                            // Left side (Old)
                            VStack(alignment: .leading, spacing: 2) {
                                DiffLine(text: "func fetchData() {", type: .normal)
                                DiffLine(text: "-  let url = \"old-api.com\"", type: .removed)
                                DiffLine(text: "   print(\"Fetching...\")", type: .normal)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.red.opacity(0.05))

                            Divider()

                            // Right side (New)
                            VStack(alignment: .leading, spacing: 2) {
                                DiffLine(text: "func fetchData() {", type: .normal)
                                DiffLine(text: "+  let url = \"new-api.com\"", type: .added)
                                DiffLine(text: "   print(\"Fetching...\")", type: .normal)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.green.opacity(0.05))
                        }
                    }
                    .border(Color.secondary.opacity(0.2))
                    .padding()
                }
            }
            .navigationTitle("Side-by-Side Diff")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct DiffLine: View {
    let text: String
    let type: LineType

    enum LineType { case normal, added, removed }

    var body: some View {
        Text(text)
            .font(.system(.caption2, design: .monospaced))
            .padding(.horizontal, 4)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(backgroundColor)
    }

    private var backgroundColor: Color {
        switch type {
        case .normal: return .clear
        case .added: return .green.opacity(0.2)
        case .removed: return .red.opacity(0.2)
        }
    }
}
