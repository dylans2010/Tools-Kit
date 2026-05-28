import SwiftUI

struct UUIDGeneratorDevTool: DevTool {
    let id = "uuid-generator"
    let name = "UUID Generator"
    let category = DevToolCategory.data
    let icon = "barcode"
    let description = "Generate UUIDs with batch, format, and validation options"

    func render() -> some View {
        UUIDGeneratorDevToolView()
    }
}

struct UUIDGeneratorDevToolView: View {
    @StateObject private var viewModel = UUIDGeneratorViewModel()

    var body: some View {
        Form {
            Section(header: Text("Generated UUID")) {
                Text(viewModel.currentUUID)
                    .font(.system(.headline, design: .monospaced))
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 4)

                HStack {
                    Button {
                        viewModel.generate()
                    } label: {
                        Label("Generate", systemImage: "arrow.clockwise")
                    }
                    .buttonStyle(.borderedProminent)

                    Button {
                        UIPasteboard.general.string = viewModel.currentUUID
                    } label: {
                        Label("Copy", systemImage: "doc.on.doc")
                    }
                    .buttonStyle(.bordered)
                }
            }

            Section(header: Text("Format Options")) {
                Toggle("Uppercase", isOn: $viewModel.isUppercase)
                Toggle("Include Hyphens", isOn: $viewModel.includeHyphens)
                Picker("Prefix", selection: $viewModel.prefix) {
                    Text("None").tag("")
                    Text("urn:uuid:").tag("urn:uuid:")
                    Text("0x").tag("0x")
                    Text("{braces}").tag("{}")
                }
            }

            Section(header: Text("Batch Generate")) {
                Stepper("Count: \(viewModel.batchCount)", value: $viewModel.batchCount, in: 1...100)

                Button {
                    viewModel.generateBatch()
                } label: {
                    Label("Generate Batch", systemImage: "square.stack.3d.up")
                }
                .buttonStyle(.bordered)

                if !viewModel.batchResults.isEmpty {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 2) {
                            ForEach(Array(viewModel.batchResults.enumerated()), id: \.offset) { _, uuid in
                                Text(uuid)
                                    .font(.system(.caption2, design: .monospaced))
                                    .textSelection(.enabled)
                            }
                        }
                    }
                    .frame(height: min(CGFloat(viewModel.batchResults.count) * 16, 200))

                    Button {
                        UIPasteboard.general.string = viewModel.batchResults.joined(separator: "\n")
                    } label: {
                        Label("Copy All", systemImage: "doc.on.doc.fill")
                    }
                    .buttonStyle(.bordered).controlSize(.small)
                }
            }

            Section(header: Text("UUID Validator")) {
                TextField("Paste UUID to validate", text: $viewModel.validateInput)
                    .font(.system(.caption, design: .monospaced))
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                if !viewModel.validateInput.isEmpty {
                    HStack {
                        Image(systemName: viewModel.isValidUUID ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundStyle(viewModel.isValidUUID ? .green : .red)
                        Text(viewModel.isValidUUID ? "Valid UUID format" : "Invalid UUID format")
                            .font(.caption)
                        if viewModel.isValidUUID, let version = viewModel.detectedVersion {
                            Spacer()
                            Text("v\(version)")
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .background(Color.blue.opacity(0.1), in: Capsule())
                        }
                    }
                }
            }

            Section {
                HStack {
                    Text("History")
                        .font(.headline)
                    Spacer()
                    Text("\(viewModel.history.count) items")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Button("Clear") {
                        viewModel.history.removeAll()
                    }
                    .font(.caption)
                    .disabled(viewModel.history.isEmpty)
                }

                if viewModel.history.isEmpty {
                    ContentUnavailableView("No History", systemImage: "clock", description: Text("Generated UUIDs appear here."))
                        .frame(height: 150)
                } else {
                    ForEach(viewModel.history) { item in
                        Button {
                            UIPasteboard.general.string = item.title
                        } label: {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.title)
                                    .font(.system(.caption, design: .monospaced))
                                Text(item.timestamp, style: .relative)
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                    }
                }
            } header: {
                Text("History")
            }
        }
    }
}

class UUIDGeneratorViewModel: ObservableObject {
    @Published var currentUUID = UUID().uuidString
    @Published var isUppercase = true
    @Published var includeHyphens = true
    @Published var prefix = ""
    @Published var batchCount = 5
    @Published var batchResults: [String] = []
    @Published var validateInput = ""
    @Published var history: [HistoryItem] = []

    var isValidUUID: Bool {
        UUID(uuidString: validateInput.replacingOccurrences(of: "urn:uuid:", with: "").trimmingCharacters(in: CharacterSet(charactersIn: "{}"))) != nil
    }

    var detectedVersion: Int? {
        let clean = validateInput.replacingOccurrences(of: "-", with: "")
        guard clean.count == 32 else { return nil }
        let versionChar = clean[clean.index(clean.startIndex, offsetBy: 12)]
        return Int(String(versionChar))
    }

    func generate() {
        var uuid = UUID().uuidString
        if !isUppercase { uuid = uuid.lowercased() }
        if !includeHyphens { uuid = uuid.replacingOccurrences(of: "-", with: "") }

        if prefix == "{}" {
            uuid = "{\(uuid)}"
        } else if !prefix.isEmpty {
            uuid = prefix + uuid
        }

        currentUUID = uuid
        history.insert(HistoryItem(title: uuid, detail: "Generated"), at: 0)
        if history.count > 50 { history = Array(history.prefix(50)) }
    }

    func generateBatch() {
        batchResults = (0..<batchCount).map { _ in
            var uuid = UUID().uuidString
            if !isUppercase { uuid = uuid.lowercased() }
            if !includeHyphens { uuid = uuid.replacingOccurrences(of: "-", with: "") }
            if prefix == "{}" { uuid = "{\(uuid)}" }
            else if !prefix.isEmpty { uuid = prefix + uuid }
            return uuid
        }
    }
}

#Preview {
    UUIDGeneratorDevToolView()
}
