import SwiftUI

struct SemVerCalculatorDevTool: DevTool {
    let id = "semver-calc"
    let name = "Semantic Versioning Calculator"
    let category: DevToolCategory = .utilities
    let icon = "text.badge.plus"
    let description = "Calculate next semantic version (Major, Minor, Patch)"

    func render() -> some View {
        SimpleDevToolView(title: name, placeholder: "1.2.3, minor") { input in
            let parts = input.components(separatedBy: ",")
            let version = parts[0].trimmingCharacters(in: .whitespaces)
            let vParts = version.split(separator: ".").map { Int($0) ?? 0 }
            guard vParts.count == 3 else { return "Format: 1.2.3, [major|minor|patch]" }

            var major = vParts[0], minor = vParts[1], patch = vParts[2]
            let type = parts.count > 1 ? parts[1].trimmingCharacters(in: .whitespaces).lowercased() : "patch"

            if type == "major" { major += 1; minor = 0; patch = 0 }
            else if type == "minor" { minor += 1; patch = 0 }
            else { patch += 1 }

            return "\(major).\(minor).\(patch)"
        }
    }
}
