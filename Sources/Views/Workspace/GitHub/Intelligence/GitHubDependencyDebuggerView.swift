import SwiftUI

struct GitHubDependencyDebuggerView: View {
    @ObservedObject private var analyzer = RepoAnalyzerService.shared

    var body: some View {
        List {
            Section(header: Text("Circular Dependencies"), footer: Text("Circular dependencies can cause memory leaks and unexpected behavior.")) {
                if analyzer.circularDependencies.isEmpty {
                    Label("No circular dependencies detected", systemImage: "checkmark.circle.fill").foregroundStyle(.green)
                } else {
                    ForEach(analyzer.circularDependencies, id: \.self) { dep in
                        Label(dep, systemImage: "exclamationmark.triangle.fill").foregroundStyle(.red).font(.caption)
                    }
                }
            }

            Section {
                Button("Scan Sources for Cycles") {
                    analyzer.scanForCircularDependencies(rootPath: "Sources")
                }
                .frame(maxWidth: .infinity)
            }

            Section {
                VStack(alignment: .leading, spacing: 4) {
                    Text("System Discovery").font(.subheadline.bold())
                    Text("Scanning real .swift files for 'import' statements.").font(.caption2).foregroundStyle(.secondary)
                }
            } header: {
                Text("Module Chains")
            }
        }
        .navigationTitle("Dependency Debugger")
    }
}
