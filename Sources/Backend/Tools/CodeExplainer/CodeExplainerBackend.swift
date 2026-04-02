import Foundation

struct CodeComponent {
    let type: String
    let name: String
    let description: String
}

class CodeExplainerBackend: ObservableObject {
    @Published var code = ""
    @Published var explanation = ""
    @Published var components: [CodeComponent] = []
    @Published var isProcessing = false

    func explain() {
        let input = code.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !input.isEmpty else { return }

        isProcessing = true
        explanation = ""
        components = []

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            self.analyze(input)
            self.isProcessing = false
        }
    }

    private func analyze(_ input: String) {
        var foundComponents: [CodeComponent] = []

        // Regex for functions (Swift/JS style)
        if let funcRegex = try? NSRegularExpression(pattern: "(func|function)\\s+([a-zA-Z0-9_]+)", options: []) {
            let matches = funcRegex.matches(in: input, range: NSRange(location: 0, length: input.utf16.count))
            for match in matches {
                if let typeRange = Range(match.range(at: 1), in: input),
                   let nameRange = Range(match.range(at: 2), in: input) {
                    let name = String(input[nameRange])
                    foundComponents.append(CodeComponent(type: "Function", name: name, description: "A reusable block of code named '\(name)' that performs a specific task."))
                }
            }
        }

        // Regex for classes
        if let classRegex = try? NSRegularExpression(pattern: "class\\s+([a-zA-Z0-9_]+)", options: []) {
            let matches = classRegex.matches(in: input, range: NSRange(location: 0, length: input.utf16.count))
            for match in matches {
                if let nameRange = Range(match.range(at: 1), in: input) {
                    let name = String(input[nameRange])
                    foundComponents.append(CodeComponent(type: "Class", name: name, description: "A blueprint named '\(name)' for creating objects, providing initial values and implementations."))
                }
            }
        }

        // Check for loops
        if input.contains("for ") || input.contains("while ") {
            foundComponents.append(CodeComponent(type: "Loop", name: "Iteration", description: "This code contains logic to repeat a set of instructions multiple times."))
        }

        // Check for conditionals
        if input.contains("if ") || input.contains("switch ") {
            foundComponents.append(CodeComponent(type: "Conditional", name: "Logic Gate", description: "This code uses branching logic to execute different paths based on conditions."))
        }

        self.components = foundComponents

        if foundComponents.isEmpty {
            self.explanation = "I've analyzed your code. It appears to be a sequence of statements without distinct structural markers like functions or classes. It executes linearly from top to bottom."
        } else {
            self.explanation = "Based on the structural analysis, this code defines \(foundComponents.count) major components. It uses \(foundComponents.map { $0.type.lowercased() }.joined(separator: ", ")) to organize logic."
        }
    }
}
