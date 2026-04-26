import Foundation

public final class AgentCodeValidator {
    public init() {}

    public func validate(code: String, language: String) -> Bool {
        // Basic syntax check (braces balance)
        var balance = 0
        for char in code {
            if char == "{" { balance += 1 }
            else if char == "}" { balance -= 1 }
            if balance < 0 { return false }
        }
        return balance == 0
    }
}
