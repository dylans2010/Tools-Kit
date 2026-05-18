import SwiftUI
import CryptoKit

struct HashGeneratorDevTool: DevTool {
    let id = "hash-generator"
    let name = "Hash Generator"
    let category = DevToolCategory.security
    let icon = "number"
    let description = "Generate SHA-256 and MD5 hashes"

    func render() -> some View {
        HashGeneratorView()
    }
}

struct HashGeneratorView: View {
    @StateObject private var viewModel = HashGeneratorViewModel()

    var body: some View {
        Form {
            Section("Input Text") {
                TextEditor(text: $viewModel.inputText)
                    .frame(height: 100)
            }

            Section("Hashes") {
                LabeledContent("MD5", value: viewModel.md5Hash)
                LabeledContent("SHA-256", value: viewModel.sha256Hash)
            }
        }
    }
}

class HashGeneratorViewModel: ObservableObject {
    @Published var inputText = ""

    var md5Hash: String {
        guard let data = inputText.data(using: .utf8) else { return "" }
        let hash = Insecure.MD5.hash(data: data)
        return hash.map { String(format: "%02x", $0) }.joined()
    }

    var sha256Hash: String {
        guard let data = inputText.data(using: .utf8) else { return "" }
        let hash = SHA256.hash(data: data)
        return hash.map { String(format: "%02x", $0) }.joined()
    }
}
