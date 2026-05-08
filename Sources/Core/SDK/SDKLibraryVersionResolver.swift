import Foundation

public final class SDKLibraryVersionResolver {
    public init() {}

    public func resolvePreferredVersion(for libraryName: String, availableVersions: [String], preferredVersion: String?) -> String? {
        if let preferred = preferredVersion, availableVersions.contains(preferred) {
            return preferred
        }
        return availableVersions.sorted(by: isVersionHigher).first
    }

    public func diff(from oldVersion: String, to newVersion: String) -> String {
        if oldVersion == newVersion {
            return "No version changes"
        }
        return "Version changed from \(oldVersion) to \(newVersion)"
    }

    private func isVersionHigher(_ lhs: String, _ rhs: String) -> Bool {
        let left = lhs.split(separator: ".").compactMap { Int($0) }
        let right = rhs.split(separator: ".").compactMap { Int($0) }
        for idx in 0..<max(left.count, right.count) {
            let l = idx < left.count ? left[idx] : 0
            let r = idx < right.count ? right[idx] : 0
            if l != r { return l > r }
        }
        return lhs > rhs
    }
}
