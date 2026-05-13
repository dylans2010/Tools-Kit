
import SwiftUI

struct SDKBridgeGeneratorView: View {
    @State private var selectedLanguage = "Swift"
    @State private var generatedCode = ""
    @StateObject private var projectManager = SDKProjectManager.shared

    var body: some View {
        VStack(spacing: 0) {
            Form {
                Picker("Target Language", selection: $selectedLanguage) {
                    Text("Swift").tag("Swift")
                    Text("Kotlin").tag("Kotlin")
                    Text("JavaScript").tag("JavaScript")
                    Text("C++").tag("C++")
                }

                Button("Generate Implementation") { generate() }
            }
            .frame(height: 150)

            if !generatedCode.isEmpty {
                ScrollView {
                    Text(generatedCode)
                        .font(.system(.caption2, design: .monospaced))
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .background(Color.black.opacity(0.05))
            }
        }
        .navigationTitle("Bridge")
    }

    private func generate() {
        guard let project = projectManager.currentProject else { return }
        var code = "// Generated Bridge for \(project.name)\n"
        code += "// Platform: \(selectedLanguage)\n\n"

        switch selectedLanguage {
        case "Swift":
            code += "protocol \(project.name.replacingOccurrences(of: " ", with: ""))Bridge {\n"
            for scope in project.enabledScopes {
                code += "    func handle\(scope.capitalized)(data: Any)\n"
            }
            code += "}"
        case "Kotlin":
            code += "interface \(project.name.replacingOccurrences(of: " ", with: ""))Bridge {\n"
            for scope in project.enabledScopes {
                code += "    fun handle\(scope.capitalized)(data: Any)\n"
            }
            code += "}"
        default:
            code += "// Extension points: \(project.enabledScopes.joined(separator: ", "))"
        }
        generatedCode = code
    }
}
