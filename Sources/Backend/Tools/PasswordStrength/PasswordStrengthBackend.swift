import Foundation

class PasswordStrengthBackend: ObservableObject {
    @Published var password = ""

    var entropy: Double {
        guard !password.isEmpty else { return 0 }

        var charsetSize = 0
        if password.rangeOfCharacter(from: .lowercaseLetters) != nil { charsetSize += 26 }
        if password.rangeOfCharacter(from: .uppercaseLetters) != nil { charsetSize += 26 }
        if password.rangeOfCharacter(from: .decimalDigits) != nil { charsetSize += 10 }
        if password.rangeOfCharacter(from: CharacterSet(charactersIn: "!@#$%^&*()-_=+[]{}|;:,.<>?")) != nil { charsetSize += 26 }

        if charsetSize == 0 { charsetSize = 10 } // Fallback

        return log2(Double(charsetSize)) * Double(password.count)
    }

    var strengthLabel: String {
        let e = entropy
        if e < 28 { return "Very Weak" }
        if e < 36 { return "Weak" }
        if e < 60 { return "Moderate" }
        if e < 128 { return "Strong" }
        return "Excellent"
    }

    var strengthColor: String {
        let e = entropy
        if e < 28 { return "red" }
        if e < 36 { return "orange" }
        if e < 60 { return "yellow" }
        if e < 128 { return "green" }
        return "blue"
    }
}
