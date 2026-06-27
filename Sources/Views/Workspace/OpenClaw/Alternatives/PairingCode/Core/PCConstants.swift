import Foundation

public enum PCConstants {
    public static let codeLength = 8
    public static let expiryWindow: TimeInterval = 60.0
    public static let validationEndpoint = "/alt/pairing-code/validate"
    public static let keychainService = "com.toolskit.openclaw.pairing-code"
}
