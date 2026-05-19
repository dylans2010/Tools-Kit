import SwiftUI

struct JSONFormatterDevTool: DevTool {
    let id = "json-formatter"
    let name = "JSON Formatter"
    let category = DevToolCategory.data
    let icon = "text.badge.checkmark"
    let description = "Prettify and minify JSON data"

    func render() -> some View {
        JSONFormatterDevToolView()
    }
}

struct JSONFormatterDevToolView: View {
    @StateObject private var viewModel = JSONFormatterViewModel()
    @State private var showingBatchSheet = false

    var body: some View {
        Form {
            Section("Input") {
                ZStack(alignment: .topTrailing) {
                    TextEditor(text: $viewModel.input)
                        .frame(height: 180)
                        .font(.system(.caption, design: .monospaced))

                    Button {
                        viewModel.input = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .padding(8)
                    .opacity(viewModel.input.isEmpty ? 0 : 1)
                }

                HStack {
                    Button("Paste") {
                        if let string = UIPasteboard.general.string {
                            viewModel.input = string
                        }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)

                    Button("Sample") {
                        viewModel.input = "{\"id\":101,\"title\":\"ToolsKit SDK\",\"active\":true,\"metadata\":{\"version\":\"2.4\",\"tags\":[\"dev\",\"tool\"]}}"
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)

                    Spacer()

                    if !viewModel.isValidJSON {
                        Text("Invalid JSON")
                            .font(.caption2)
                            .foregroundStyle(.red)
                    }
                }
            }

            Section("Options") {
                Picker("Format", selection: $viewModel.formatType) {
                    Text("Prettify").tag(JSONFormatType.prettify)
                    Text("Minify").tag(JSONFormatType.minify)
                }
                .pickerStyle(.segmented)

                Toggle("Sort Keys", isOn: $viewModel.sortKeys)

                if viewModel.formatType == .prettify {
                    Stepper("Indentation: \(viewModel.indentSize)", value: $viewModel.indentSize, in: 1...8)
                }
            }

            Section("Output") {
                ZStack(alignment: .bottomTrailing) {
                    ScrollView {
                        Text(viewModel.output)
                            .font(.system(.caption2, design: .monospaced))
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .textSelection(.enabled)
                    }
                    .background(Color(uiColor: .systemGray6))
                    .cornerRadius(8)
                    .frame(minHeight: 250)

                    if !viewModel.output.isEmpty && viewModel.isValidJSON {
                        HStack(spacing: 12) {
                            Button {
                                UIPasteboard.general.string = viewModel.output
                            } label: {
                                Image(systemName: "doc.on.doc")
                                    .padding(10)
                                    .background(.ultraThinMaterial, in: Circle())
                            }

                            Button {
                                showingBatchSheet = true
                            } label: {
                                Image(systemName: "rectangle.stack.fill")
                                    .padding(10)
                                    .background(.ultraThinMaterial, in: Circle())
                            }
                        }
                        .padding(12)
                    }
                }

                HStack {
                    Button {
                        let tempDir = FileManager.default.temporaryDirectory
                        let fileURL = tempDir.appendingPathComponent("formatted.json")
                        try? viewModel.output.write(to: fileURL, atomically: true, encoding: .utf8)
                    } label: {
                        Label("Export File", systemImage: "square.and.arrow.up")
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!viewModel.isValidJSON)
                }
            }

            Section("History") {
                ForEach(viewModel.history.prefix(5)) { item in
                    Button {
                        viewModel.input = item.content
                    } label: {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(item.title).font(.subheadline)
                                Text(item.timestamp, style: .time).font(.caption2).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "arrow.uturn.backward")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                }
            }
        }
        .navigationTitle("JSON Formatter")
        .sheet(isPresented: $showingBatchSheet) {
            JSONBatchProcessView(viewModel: viewModel)
        }
    }
}

enum JSONFormatType {
    case prettify, minify
}

struct JSONHistoryItem: Identifiable {
    let id = UUID()
    let title: String
    let content: String
    let timestamp = Date()
}

class JSONFormatterViewModel: ObservableObject {
    @Published var input = "{\"id\":1,\"name\":\"Test\",\"tags\":[\"swift\",\"ios\"]}" {
        didSet {
            if input != oldValue { process() }
        }
    }
    @Published var output = ""
    @Published var formatType = JSONFormatType.prettify {
        didSet { process() }
    }
    @Published var indentSize = 2 {
        didSet { process() }
    }
    @Published var sortKeys = true {
        didSet { process() }
    }
    @Published var isValidJSON = true
    @Published var history: [JSONHistoryItem] = []

    func process() {
        guard !input.isEmpty else {
            output = ""
            isValidJSON = true
            return
        }

        guard let data = input.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data, options: []) else {
            output = "Invalid JSON structure"
            isValidJSON = false
            return
        }

        isValidJSON = true
        var options: JSONSerialization.WritingOptions = []
        if formatType == .prettify { options.insert(.prettyPrinted) }
        if sortKeys { options.insert(.sortedKeys) }

        if let formattedData = try? JSONSerialization.data(withJSONObject: json, options: options),
           let result = String(data: formattedData, encoding: .utf8) {
            output = result

            // Add to history if unique
            if !history.contains(where: { $0.content == input }) {
                history.insert(JSONHistoryItem(title: "JSON \(history.count + 1)", content: input), at: 0)
            }
        }
    }
}

struct JSONBatchProcessView: View {
    @ObservedObject var viewModel: JSONFormatterViewModel
    @State private var batchInput = ""
    @State private var batchResults: [String] = []
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            VStack {
                Text("Paste multiple JSON objects (one per line)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.top)

                TextEditor(text: $batchInput)
                    .frame(height: 200)
                    .font(.system(.caption2, design: .monospaced))
                    .padding(8)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(8)
                    .padding()

                Button("Process All") {
                    let lines = batchInput.components(separatedBy: .newlines)
                    batchResults = lines.compactMap { line in
                        guard let data = line.data(using: .utf8),
                              let json = try? JSONSerialization.jsonObject(with: data, options: []),
                              let formatted = try? JSONSerialization.data(withJSONObject: json, options: viewModel.sortKeys ? [.sortedKeys] : []),
                              let res = String(data: formatted, encoding: .utf8) else {
                            return nil
                        }
                        return res
                    }
                }
                .buttonStyle(.borderedProminent)

                if !batchResults.isEmpty {
                    List(batchResults, id: \.self) { res in
                        Text(res).font(.system(size: 8, design: .monospaced)).lineLimit(1)
                    }

                    Button("Copy All (Newlines)") {
                        UIPasteboard.general.string = batchResults.joined(separator: "\n")
                        dismiss()
                    }
                    .padding()
                }

                Spacer()
            }
            .navigationTitle("Batch Process")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    JSONFormatterDevToolView()
}
