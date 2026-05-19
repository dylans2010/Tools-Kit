import SwiftUI

struct APIResponseViewerDevTool: DevTool {
    let id = "api-response-viewer"
    let name = "API Response Viewer"
    let category = DevToolCategory.networking
    let icon = "doc.text.magnifyingglass"
    let description = "Detailed inspection and formatting of API responses"

    func render() -> some View {
        APIResponseViewerView()
    }
}

struct APIResponseViewerView: View {
    @StateObject private var viewModel = APIResponseViewerViewModel()
    @State private var viewMode: APIViewMode = .pretty
    @State private var searchText = ""

    var body: some View {
        List {
            Section("Raw Response Body") {
                ZStack(alignment: .topTrailing) {
                    TextEditor(text: $viewModel.rawInput)
                        .frame(height: 160)
                        .font(.system(size: 11, design: .monospaced))
                        .padding(4)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(8)

                    VStack {
                        if !viewModel.rawInput.isEmpty {
                            Button { viewModel.rawInput = "" } label: {
                                Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                            }
                            .padding(8)
                        }

                        Button {
                            if let s = UIPasteboard.general.string { viewModel.rawInput = s }
                        } label: {
                            Image(systemName: "doc.on.clipboard.fill").foregroundStyle(.blue)
                        }
                        .padding(8)
                    }
                }

                HStack {
                    Button("Format JSON") { viewModel.formatJSON() }
                        .buttonStyle(.bordered)
                        .controlSize(.small)

                    Spacer()

                    Menu {
                        Button("Export as .json") { viewModel.export(as: "response.json") }
                        Button("Export as .txt") { viewModel.export(as: "response.txt") }
                    } label: {
                        Label("Export", systemImage: "square.and.arrow.up")
                    }
                    .font(.caption2)
                }
            }

            Section {
                Picker("View Mode", selection: $viewMode) {
                    Label("Pretty", systemImage: "text.alignleft").tag(APIViewMode.pretty)
                    Label("Raw", systemImage: "curlybraces").tag(APIViewMode.raw)
                    Label("Tree", systemImage: "list.bullet.indent").tag(APIViewMode.structure)
                }
                .pickerStyle(.segmented)
            }

            Section {
                contentView
                    .frame(minHeight: 300)
            } header: {
                if viewMode == .structure {
                    TextField("Filter keys...", text: $searchText)
                        .textFieldStyle(.roundedBorder)
                        .textCase(nil)
                        .autocorrectionDisabled()
                }
            }

            Section("Payload Analysis") {
                HStack {
                    MetricLabel(label: "Size", value: viewModel.dataSize)
                    Divider()
                    MetricLabel(label: "Type", value: viewModel.formatDetected)
                    Divider()
                    MetricLabel(label: "Nodes", value: "\(viewModel.nodeCount)")
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("Response Lab")
    }

    @ViewBuilder
    private var contentView: some View {
        switch viewMode {
        case .pretty:
            ScrollView {
                Text(viewModel.prettyOutput)
                    .font(.system(.caption2, design: .monospaced))
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
            }
            .background(Color(uiColor: .systemGray6))
            .cornerRadius(8)
        case .raw:
            ScrollView {
                Text(viewModel.rawInput)
                    .font(.system(.caption2, design: .monospaced))
                    .padding()
            }
            .background(Color(uiColor: .secondarySystemBackground))
            .cornerRadius(8)
        case .structure:
            List(viewModel.structure, children: \.children) { item in
                HStack {
                    Image(systemName: item.icon)
                        .foregroundStyle(.secondary)
                    Text(item.key)
                        .font(.caption.bold())
                    Spacer()
                    Text(item.value)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

enum APIViewMode {
    case pretty, raw, structure
}

struct StructureItem: Identifiable {
    let id = UUID()
    let key: String
    let value: String
    let icon: String
    var children: [StructureItem]?
}

class APIResponseViewerViewModel: ObservableObject {
    @Published var rawInput = "" {
        didSet { process() }
    }
    @Published var prettyOutput = ""
    @Published var dataSize = "0 bytes"
    @Published var formatDetected = "None"
    @Published var structure: [StructureItem] = []
    @Published var nodeCount = 0

    func formatJSON() {
        guard let data = rawInput.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data, options: []),
              let prettyData = try? JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted]),
              let prettyString = String(data: prettyData, encoding: .utf8) else { return }
        rawInput = prettyString
    }

    func export(as filename: String) {
        let av = UIActivityViewController(activityItems: [rawInput], applicationActivities: nil)
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            windowScene.windows.first?.rootViewController?.present(av, animated: true)
        }
    }

    private func process() {
        nodeCount = 0
        guard let data = rawInput.data(using: .utf8) else {
            prettyOutput = ""
            dataSize = "0 bytes"
            formatDetected = "None"
            structure = []
            return
        }

        dataSize = ByteCountFormatter.string(fromByteCount: Int64(data.count), countStyle: .file)

        if let json = try? JSONSerialization.jsonObject(with: data, options: []),
           let prettyData = try? JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted, .sortedKeys]),
           let prettyString = String(data: prettyData, encoding: .utf8) {
            prettyOutput = prettyString
            formatDetected = "JSON"
            structure = buildStructure(from: json)
        } else {
            prettyOutput = rawInput
            formatDetected = "Raw"
            structure = []
        }
    }

    private func buildStructure(from object: Any, key: String = "root") -> [StructureItem] {
        if let dict = object as? [String: Any] {
            return dict.map { k, v in
                var item = StructureItem(key: k, value: "", icon: "folder")
                item.children = buildStructure(from: v, key: k)
                return item
            }.sorted { $0.key < $1.key }
        } else if let array = object as? [Any] {
            return array.enumerated().map { i, v in
                var item = StructureItem(key: "[\(i)]", value: "", icon: "list.bullet")
                item.children = buildStructure(from: v, key: "[\(i)]")
                return item
            }
        } else {
            return [StructureItem(key: key, value: "\(object)", icon: "tag")]
        }
    }
}

#Preview {
    APIResponseViewerView()
}
