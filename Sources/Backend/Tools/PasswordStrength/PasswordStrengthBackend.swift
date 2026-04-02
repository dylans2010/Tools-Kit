import Foundation

class PasswordStrengthBackend: ObservableObject {
    @Published var password = ""

    var strength: Double {
        calculateStrength()
    }

    var strengthText: String {
        let strengthValue = strength
        if strengthValue < 0.25 {
            return "Very Weak"
        } else if strengthValue < 0.5 {
            return "Weak"
        } else if strengthValue < 0.75 {
            return "Medium"
        } else if strengthValue < 1.0 {
            return "Strong"
        } else {
            return "Very Strong"
        }
    }

    var feedback: [String] {
        var suggestions: [String] = []

        if password.count < 8 {
            suggestions.append("Use at least 8 characters")
        }
        if !password.contains(where: { $0.isUppercase }) {
            suggestions.append("Add uppercase letters (A-Z)")
        }
        if !password.contains(where: { $0.isLowercase }) {
            suggestions.append("Add lowercase letters (a-z)")
        }
        if !password.contains(where: { $0.isNumber }) {
            suggestions.append("Add numbers (0-9)")
        }
        if !password.contains(where: { "!@#$%^&*()-_=+[]{}|;:,.<>?".contains($0) }) {
            suggestions.append("Add special characters (!@#$%^&*)")
        }
        if password.count < 12 {
            suggestions.append("Consider using 12+ characters for better security")
        }

        return suggestions
    }

    private func calculateStrength() -> Double {
        guard !password.isEmpty else { return 0.0 }

        var score = 0.0

        // Length score (max 0.3)
        if password.count >= 8 {
            score += 0.1
        }
        if password.count >= 12 {
            score += 0.1
        }
        if password.count >= 16 {
            score += 0.1
        }

        // Character variety (max 0.4)
        if password.contains(where: { $0.isLowercase }) {
            score += 0.1
        }
        if password.contains(where: { $0.isUppercase }) {
            score += 0.1
        }
        if password.contains(where: { $0.isNumber }) {
            score += 0.1
        }
        if password.contains(where: { "!@#$%^&*()-_=+[]{}|;:,.<>?".contains($0) }) {
            score += 0.1
        }

        // Complexity bonus (max 0.3)
        let uniqueChars = Set(password).count
        if uniqueChars > password.count / 2 {
            score += 0.15
        }
        if uniqueChars > password.count * 2 / 3 {
            score += 0.15
        }

        return min(score, 1.0)
    }
}
