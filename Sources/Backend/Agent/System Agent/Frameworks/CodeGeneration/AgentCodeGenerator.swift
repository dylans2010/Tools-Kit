import Foundation

struct AgentCodeGenerator {
    func wrapInFunction(name: String, body: String, language: String = "swift") -> String {
        switch language.lowercased() {
        case "python": return "def \(name)():
" + body.split(separator: "
").map { "    \($0)" }.joined(separator: "
")
        default: return "func \(name)() {
" + body.split(separator: "
").map { "    \($0)" }.joined(separator: "
") + "
}"
        }
    }
}
