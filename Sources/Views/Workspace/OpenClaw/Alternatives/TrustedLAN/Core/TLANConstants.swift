import Foundation
public enum TLANConstants {
    public static let serviceType = "_openclaw._tcp"
    public static let defaultPort = 9876
    public static let connectionTimeout: TimeInterval = 30.0
    public static let approvalTimeout: TimeInterval = 120.0
    public static let keychainService = "com.toolskit.openclaw.trusted-lan"
    public static let appInstallSecretKey = "com.toolskit.openclaw.install-secret"
    public static let tokenRotationThreshold: TimeInterval = 7 * 24 * 60 * 60
}
