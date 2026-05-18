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

    var body: some View {
        VStack(spacing: 0) {
            DevToolHeader(
                title: "API Response Viewer",
                description: "Paste raw API response data to format, inspect, and analyze its structure.",
                icon: "doc.text.magnifyingglass"
            )
            .padding()

            Form {
                Section("Input Raw Data") {
                    TextEditor(text: $viewModel.rawInput)
                        .frame(height: 150)
                        .font(.system(.caption, design: .monospaced))
                }

                Section("Analysis & Formatting") {
                    Picker("View Mode", selection: $viewMode) {
                        Text("Pretty").tag(APIViewMode.pretty)
                        Text("Raw").tag(APIViewMode.raw)
                        Text("Structure").tag(APIViewMode.structure)
                    }
                    .pickerStyle(.segmented)

                    contentView
                        .frame(minHeight: 250)
                }

                Section("Metrics") {
                    LabeledContent("Data Size", value: viewModel.dataSize)
                    LabeledContent("Format Detected", value: viewModel.formatDetected)
                }
            }
        }
    }

    @ViewBuilder
    private var contentView: some View {
        switch viewMode {
        case .pretty:
            JSONView(json: viewModel.prettyOutput)
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
        didSet {
            process()
        }
    }
    @Published var prettyOutput = ""
    @Published var dataSize = "0 bytes"
    @Published var formatDetected = "None"
    @Published var structure: [StructureItem] = []

    private func process() {
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
            formatDetected = "Plain Text / Unknown"
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
