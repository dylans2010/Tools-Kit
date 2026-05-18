import SwiftUI

struct JSONValidatorTool: DevTool {
    let id = UUID()
    let name = "JSON Validator"
    let category: DevToolCategory = .data
    let icon = "checkmark.seal"
    let description = "Validate JSON syntax and structure"
    func render() -> some View { JSONValidatorDevToolView() }
}

struct JSONValidatorDevToolView: View {
    @State private var input = ""
    @State private var isValid: Bool?
    @State private var errorDetail: String?
    @State private var jsonInfo: [(String, String)] = []
    var body: some View {
        Form {
            Section("JSON Input") {
                TextEditor(text: $input).frame(minHeight: 120).font(.system(.body, design: .monospaced))
            }
            Section {
                Button("Validate") { validate() }
                    .disabled(input.isEmpty)
            }
            if let isValid {
                Section("Result") {
                    Label(isValid ? "Valid JSON" : "Invalid JSON",
                          systemImage: isValid ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundStyle(isValid ? .green : .red)
                    if let errorDetail {
                        Text(errorDetail).font(.caption).foregroundStyle(.red)
                    }
                }
            }
            if !jsonInfo.isEmpty {
                Section("Structure") {
                    ForEach(jsonInfo, id: \.0) { key, value in
                        LabeledContent(key, value: value)
                    }
                }
            }
        }
        .navigationTitle("JSON Validator")
    }
    private func validate() {
        errorDetail = nil
        jsonInfo.removeAll()
        guard let data = input.data(using: .utf8) else {
            isValid = false; errorDetail = "Cannot encode as UTF-8"; return
        }
        do {
            let obj = try JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed)
            isValid = true
            if let dict = obj as? [String: Any] {
                jsonInfo.append(("Type", "Object"))
                jsonInfo.append(("Keys", "\(dict.count)"))
            } else if let arr = obj as? [Any] {
                jsonInfo.append(("Type", "Array"))
                jsonInfo.append(("Elements", "\(arr.count)"))
            } else {
                jsonInfo.append(("Type", "Primitive"))
            }
            jsonInfo.append(("Size", "\(data.count) bytes"))
        } catch {
            isValid = false
            errorDetail = error.localizedDescription
        }
    }
}
