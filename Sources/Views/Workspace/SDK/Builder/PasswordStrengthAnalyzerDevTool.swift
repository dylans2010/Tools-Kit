import SwiftUI

struct PasswordStrengthAnalyzerDevTool: DevTool {
    let id = "password-strength"
    let name = "Password Strength Analyzer"
    let category: DevToolCategory = .security
    let icon = "gauge.medium"
    let description = "Analyze the strength and complexity of a password"

    func render() -> some View {
        SimpleDevToolView(title: name, placeholder: "Enter password") { input in
            var score = 0
            if input.count >= 8 { score += 1 }
            if input.rangeOfCharacter(from: .uppercaseLetters) != nil { score += 1 }
            if input.rangeOfCharacter(from: .decimalDigits) != nil { score += 1 }
            if input.rangeOfCharacter(from: .punctuationCharacters) != nil { score += 1 }

            let ratings = ["Very Weak", "Weak", "Medium", "Strong", "Very Strong"]
            return "Strength: \(ratings[score])\nEntropy estimate: \(input.count * 4) bits"
        }
    }
}
