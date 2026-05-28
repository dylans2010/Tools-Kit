import SwiftUI

struct JSONFormatterDevTool: DevTool {
    let id = "json-formatter"
    let name = "JSON Formatter"
    let category = DevToolCategory.data
    let icon = "text.badge.checkmark"
    let description = "Prettify, minify, validate, and query JSON data"

    func render() -> some View {
        JSONFormatterDevToolView()
    }
}

struct JSONFormatterDevToolView: View {
    @StateObject private var viewModel = JSONFormatterViewModel()

    var body: some View {
        Form {
            Section(header: Text("Input")) {
                TextEditor(text: $viewModel.input)
                    .frame(height: 150)
                    .font(.system(.caption, design: .monospaced))
                HStack {
                    Button("Paste") {
                        if let text = UIPasteboard.general.string {
                            viewModel.input = text
                        }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)

                    Button("Clear") { viewModel.input = "" }
                        .buttonStyle(.bordered)
                        .controlSize(.small)

                    Button("Sample") {
                        viewModel.input = """
                        {"users":[{"id":1,"name":"Alice","roles":["admin","editor"]},{"id":2,"name":"Bob","roles":["viewer"]}],"meta":{"total":2,"page":1}}
                        """
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }

            Section(header: Text("Options")) {
                Picker("Format", selection: $viewModel.formatType) {
                    Text("Prettify").tag(JSONFormatType.prettify)
                    Text("Minify").tag(JSONFormatType.minify)
                    Text("Sort Keys").tag(JSONFormatType.sortedKeys)
                }
                .pickerStyle(.segmented)

                Stepper("Indentation: \(viewModel.indentSize) spaces", value: $viewModel.indentSize, in: 1...8)
                    .disabled(viewModel.formatType == .minify)

                Toggle("Escape Unicode", isOn: $viewModel.escapeUnicode)
            }

            Section(header: Text("Validation")) {
                HStack {
                    Image(systemName: viewModel.isValid ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundStyle(viewModel.isValid ? .green : .red)
                    Text(viewModel.isValid ? "Valid JSON" : "Invalid JSON")
                        .font(.caption)
                    Spacer()
                    if viewModel.isValid {
                        Text("\(viewModel.keyCount) keys · \(viewModel.depth) levels deep")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }

                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(.caption2)
                        .foregroundStyle(.red)
                }
            }

            Section(header: Text("JSON Path Query")) {
                HStack {
                    TextField("e.g. users[0].name", text: $viewModel.jsonPath)
                        .font(.system(.caption, design: .monospaced))
                        .textInputAutocapitalization(.never)
                    Button("Query") { viewModel.queryPath() }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                }
                if !viewModel.queryResult.isEmpty {
                    Text(viewModel.queryResult)
                        .font(.system(.caption2, design: .monospaced))
                        .textSelection(.enabled)
                        .padding(4)
                        .background(Color.blue.opacity(0.05), in: RoundedRectangle(cornerRadius: 4))
                }
            }

            Section(header: Text("Output")) {
                ScrollView {
                    Text(viewModel.output)
                        .font(.system(.caption2, design: .monospaced))
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .textSelection(.enabled)
                }
                .background(Color(uiColor: .systemGray6))
                .cornerRadius(8)
                .frame(minHeight: 200)

                HStack {
                    Button {
                        UIPasteboard.general.string = viewModel.output
                    } label: {
                        Label("Copy", systemImage: "doc.on.doc")
                    }
                    .buttonStyle(.bordered)

                    Button {
                        let tempDir = FileManager.default.temporaryDirectory
                        let fileURL = tempDir.appendingPathComponent("formatted.json")
                        try? viewModel.output.write(to: fileURL, atomically: true, encoding: .utf8)
                    } label: {
                        Label("Export", systemImage: "square.and.arrow.up")
                    }
                    .buttonStyle(.bordered)

                    Spacer()
                    Text("\(viewModel.output.count) chars")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            Section(header: Text("Statistics")) {
                LabeledContent("Size", value: "\(viewModel.input.utf8.count) bytes")
                LabeledContent("Keys", value: "\(viewModel.keyCount)")
                LabeledContent("Arrays", value: "\(viewModel.arrayCount)")
                LabeledContent("Nesting Depth", value: "\(viewModel.depth)")
            }
        }
    }
}

enum JSONFormatType {
    case prettify, minify, sortedKeys
}

class JSONFormatterViewModel: ObservableObject {
    @Published var input = "{\"id\":1,\"name\":\"Test\",\"tags\":[\"swift\",\"ios\"]}" {
        didSet { process() }
    }
    @Published var output = ""
    @Published var formatType = JSONFormatType.prettify {
        didSet { process() }
    }
    @Published var indentSize = 2 {
        didSet { process() }
    }
    @Published var escapeUnicode = false {
        didSet { process() }
    }
    @Published var isValid = true
    @Published var errorMessage: String?
    @Published var keyCount = 0
    @Published var arrayCount = 0
    @Published var depth = 0
    @Published var jsonPath = ""
    @Published var queryResult = ""

    private func process() {
        guard let data = input.data(using: .utf8) else {
            output = "Invalid input encoding"
            isValid = false
            errorMessage = "Cannot encode input as UTF-8"
            return
        }

        do {
            let json = try JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed])
            isValid = true
            errorMessage = nil
            analyzeStructure(json, currentDepth: 0)

            var options: JSONSerialization.WritingOptions = []
            switch formatType {
            case .prettify: options = [.prettyPrinted, .sortedKeys]
            case .minify: options = [.sortedKeys]
            case .sortedKeys: options = [.prettyPrinted, .sortedKeys]
            }
            if escapeUnicode { options.insert(.withoutEscapingSlashes) }

            let formattedData = try JSONSerialization.data(withJSONObject: json, options: options)
            output = String(data: formattedData, encoding: .utf8) ?? ""
        } catch {
            output = "Parse Error"
            isValid = false
            errorMessage = error.localizedDescription
            keyCount = 0
            arrayCount = 0
            depth = 0
        }
    }

    private func analyzeStructure(_ json: Any, currentDepth: Int) {
        var keys = 0
        var arrays = 0
        var maxDepth = currentDepth

        func traverse(_ obj: Any, depth: Int) {
            maxDepth = max(maxDepth, depth)
            if let dict = obj as? [String: Any] {
                keys += dict.count
                for (_, value) in dict { traverse(value, depth: depth + 1) }
            } else if let arr = obj as? [Any] {
                arrays += 1
                for item in arr { traverse(item, depth: depth + 1) }
            }
        }
        traverse(json, depth: currentDepth)
        self.keyCount = keys
        self.arrayCount = arrays
        self.depth = maxDepth
    }

    func queryPath() {
        guard let data = input.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data, options: []) else {
            queryResult = "Invalid JSON"
            return
        }

        let parts = jsonPath.split(separator: ".").map(String.init)
        var current: Any = json

        for part in parts {
            if let bracketRange = part.range(of: #"\[(\d+)\]"#, options: .regularExpression) {
                let key = String(part[part.startIndex..<bracketRange.lowerBound])
                let indexStr = part[bracketRange].dropFirst().dropLast()
                guard let index = Int(indexStr) else { queryResult = "Invalid index"; return }

                if !key.isEmpty {
                    guard let dict = current as? [String: Any], let val = dict[key] else { queryResult = "Key not found: \(key)"; return }
                    current = val
                }
                guard let arr = current as? [Any], index < arr.count else { queryResult = "Index out of bounds"; return }
                current = arr[index]
            } else {
                guard let dict = current as? [String: Any], let val = dict[part] else { queryResult = "Key not found: \(part)"; return }
                current = val
            }
        }

        if let data = try? JSONSerialization.data(withJSONObject: current, options: .prettyPrinted),
           let str = String(data: data, encoding: .utf8) {
            queryResult = str
        } else {
            queryResult = "\(current)"
        }
    }
}

#Preview {
    JSONFormatterDevToolView()
}
