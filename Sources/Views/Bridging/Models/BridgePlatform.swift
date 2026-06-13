import Foundation

/// Represents the host operating system platform.
public enum BridgePlatform: String, Codable, CaseIterable, Identifiable {
    case macos = "macOS"
    case windows = "Windows"
    case linux = "Linux"

    public var id: String { rawValue }

    public var iconName: String {
        switch self {
        case .macos: return "apple.logo"
        case .windows: return "windows.logo"
        case .linux: return "linux.logo"
        }
    }
}
