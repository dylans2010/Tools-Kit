import Foundation

public actor MTValidationEngine {
    public static let shared = MTValidationEngine()
    private init() {}

    public func isValidToken(_ token: String) -> Bool {
        return token.count >= 10 && !token.contains(" ")
    }
}
