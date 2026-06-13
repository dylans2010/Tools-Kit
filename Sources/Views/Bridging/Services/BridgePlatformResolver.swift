import Foundation

public final class BridgePlatformResolver {
    public static let shared = BridgePlatformResolver()

    private init() {}

    public func defaultPort(for platform: BridgePlatform) -> Int {
        switch platform {
        case .macos: return 8080
        case .windows: return 8081
        case .linux: return 8082
        }
    }

    public func capabilities(for platform: BridgePlatform) -> [String] {
        switch platform {
        case .macos:
            return ["Filesystem (APFS)", "Terminal (zsh/bash)", "AppleScript", "Swift", "Python", "Xcode CLI Tools"]
        case .windows:
            return ["Filesystem (NTFS)", "PowerShell", "CMD", ".NET", "Python", "WSL2"]
        case .linux:
            return ["Filesystem (ext4/btrfs)", "Terminal (bash)", "Docker", "Python", "C++", "Systemd"]
        }
    }

    public func defaultShell(for platform: BridgePlatform) -> String {
        switch platform {
        case .macos: return "/bin/zsh"
        case .windows: return "powershell.exe"
        case .linux: return "/bin/bash"
        }
    }

    public func pathSeparator(for platform: BridgePlatform) -> String {
        switch platform {
        case .macos, .linux: return "/"
        case .windows: return "\\"
        }
    }

    public func validateCommand(_ command: String, for platform: BridgePlatform) -> Bool {
        // Basic safety check - avoid destructive system commands without approval
        let dangerousPatterns = ["rm -rf /", "format ", "mkfs", "del /s /q C:\\"]
        return !dangerousPatterns.contains { command.contains($0) }
    }
}
