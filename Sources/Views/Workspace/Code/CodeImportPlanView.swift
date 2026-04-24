import SwiftUI

struct CodeImportPlanView: View {
    @ObservedObject var analyzer: CodeAnalyzer
    @State private var showingGeneration = false

    var body: some View {
        List {
            Section(header: Text("Proposed Actions"), footer: Text("Modules marked for refactor will be transformed using Agent Mode.")) {
                ForEach(analyzer.importPlan) { action in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(action.module.name)
                                .font(.subheadline)
                                .bold()
                            Text(action.targetPath.isEmpty ? "Skipped" : action.targetPath)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        ActionBadge(type: action.action)
                    }
                }
            }

            Section {
                Button(action: { showingGeneration = true }) {
                    HStack {
                        Spacer()
                        Label("Execute Import Plan", systemImage: "play.fill")
                        Spacer()
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
            }
        }
        .navigationTitle("Import Plan")
        .sheet(isPresented: $showingGeneration) {
            CodeGenerationView(analyzer: analyzer)
        }
    }
}

struct ActionBadge: View {
    let type: ImportAction.ActionType

    var body: some View {
        Text(type.rawValue.uppercased())
            .font(.system(size: 10, weight: .bold, design: .monospaced))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.2))
            .foregroundColor(color)
            .cornerRadius(4)
    }

    private var color: Color {
        switch type {
        case .importAsIs: return .blue
        case .refactor: return .orange
        case .discard: return .red
        }
    }
}
