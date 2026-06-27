import Foundation

public actor PCValidationEngine {
    public static let shared = PCValidationEngine()
    private init() {}

    public func validateCodeFormat(_ code: String) -> Bool {
        return code.count == PCConstants.codeLength && CharacterSet.decimalDigits.isSuperset(of: CharacterSet(charactersIn: code))
    }
}
