import Foundation

struct AgentCodeValidator {
    func validateBalancedDelimiters(_ code: String) -> Bool {
        var stack: [Character] = []
        let pairs: [Character: Character] = [")": "(", "]": "[", "}": "{"]
        for ch in code {
            if ["(", "[", "{"].contains(ch) { stack.append(ch) }
            else if let expected = pairs[ch] {
                guard stack.popLast() == expected else { return false }
            }
        }
        return stack.isEmpty
    }
}
