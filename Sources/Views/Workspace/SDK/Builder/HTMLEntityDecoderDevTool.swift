import SwiftUI

struct HTMLEntityDecoderDevTool: DevTool {
    let id = "html-entity-decoder"
    let name = "HTML Entity Decoder"
    let category = DevToolCategory.encoding
    let icon = "chevron.left.chevron.right"
    let description = "Decode HTML entities back to text"

    func render() -> some View {
        HTMLEntityDecoderView()
    }
}

struct HTMLEntityDecoderView: View {
    @StateObject private var viewModel = HTMLEntityDecoderViewModel()

    var body: some View {
        VStack(spacing: 0) {
            DevToolHeader(
                title: "HTML Entity Decoder",
                description: "Convert HTML entity sequences like &amp; back into their corresponding characters.",
                icon: "chevron.left.chevron.right"
            )
            .padding()

            Form {
                Section("HTML Entities") {
                    TextEditor(text: $viewModel.input)
                        .frame(height: 120)
                }

                Section("Plain Text") {
                    Text(viewModel.output)
                        .font(.system(.body, design: .monospaced))
                        .textSelection(.enabled)
                        .frame(minHeight: 60)

                    ExportPanel(content: viewModel.output, filename: "html_decoded.txt")
                }
            }
        }
    }
}

class HTMLEntityDecoderViewModel: ObservableObject {
    @Published var input = "&lt;b&gt;Hello &amp; World&lt;/b&gt;" {
        didSet { decode() }
    }
    @Published var output = ""

    private func decode() {
        let nsString = input as NSString
        let decoded = nsString.replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&apos;", with: "'")

        var result = decoded
        let regex = try? NSRegularExpression(pattern: "&#([0-9]+);|&#x([0-9a-fA-F]+);", options: .caseInsensitive)
        let range = NSRange(result.startIndex..<result.endIndex, in: result)

        if let matches = regex?.matches(in: result, options: [], range: range) {
            for match in matches.reversed() {
                if let r1 = Range(match.range(at: 1), in: result), let code = UInt32(result[r1]) {
                    if let scalar = UnicodeScalar(code) {
                        result.replaceSubrange(Range(match.range, in: result)!, with: String(scalar))
                    }
                } else if let r2 = Range(match.range(at: 2), in: result), let code = UInt32(result[r2], radix: 16) {
                    if let scalar = UnicodeScalar(code) {
                        result.replaceSubrange(Range(match.range, in: result)!, with: String(scalar))
                    }
                }
            }
        }

        output = result
    }
}
