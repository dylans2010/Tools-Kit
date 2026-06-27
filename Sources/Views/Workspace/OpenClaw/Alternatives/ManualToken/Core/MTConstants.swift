import Foundation

public enum MTConstants {
    public static let tokenLength = 44
    public static let expiryDuration: TimeInterval = 15 * 60
    public static let validationEndpoint = "/alt/manual-token/validate"
    public static let keychainService = "com.toolskit.openclaw.manual-token"
}
