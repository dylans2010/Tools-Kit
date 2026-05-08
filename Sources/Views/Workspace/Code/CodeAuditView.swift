import SwiftUI

struct CodeAuditView: View {
    @ObservedObject var analyzer: CodeAnalyzer

    var body: some View {
        List {
            Section {
                ForEach(analyzer.modules) { module in
                    VStack(alignment: .leading) {
                        Text(module.name)
                            .font(.headline)
                        Text(module.path)
                            .font(.caption)
                            .foregroundColor(.secondary)

                        HStack {
                            SDKStatPill(label: module.type.rawValue.capitalized, value: "", color: color(for: module.type))
                            if !module.dependencies.isEmpty {
                                SDKStatPill(label: "\(module.dependencies.count) Deps", value: "", color: .gray)
                            }
                        }
                        .padding(.top, 4)
                    }
                    .padding(.vertical, 4)
                }
            } header: {
                Text("Detected Modules")
            }

            if let structure = analyzer.auditResult {
                Section {
                    ForEach(structure.files.prefix(50), id: \.path) { file in
                        HStack {
                            Image(systemName: file.type == "dir" ? "folder" : "doc")
                                .foregroundColor(file.type == "dir" ? .blue : .secondary)
                            Text(file.path)
                                .font(.system(.caption, design: .monospaced))
                            Spacer()
                            if file.size > 0 {
                                Text("\(file.size / 1024) KB")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    if structure.files.count > 50 {
                        Text("... and \(structure.files.count - 50) more files")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .italic()
                    }
                } header: {
                    Text("File Tree")
                }
            }
        }
        .navigationTitle("Repository Audit")
    }

    private func color(for type: CodeModule.ModuleType) -> Color {
        switch type {
        case .feature: return .purple
        case .core: return .blue
        case .utility: return .green
        case .ui: return .pink
        }
    }
}
