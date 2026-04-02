import Foundation

class PasswordGeneratorBackend: ObservableObject {
    @Published var length = 16.0
    @Published var includeUppercase = true
    @Published var includeNumbers = true
    @Published var includeSpecial = true
    @Published var password = ""

    func generate() {
        let lowercase = "abcdefghijklmnopqrstuvwxyz"
        let uppercase = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        let numbers = "0123456789"
        let special = "!@#$%^&*()-_=+[]{}|;:,.<>?"

        var charset = lowercase
        if includeUppercase { charset += uppercase }
        if includeNumbers { charset += numbers }
        if includeSpecial { charset += special }

        guard !charset.isEmpty else {
            password = ""
            return
        }

        password = String((0..<Int(length)).compactMap { _ in charset.randomElement() })
    }
}
