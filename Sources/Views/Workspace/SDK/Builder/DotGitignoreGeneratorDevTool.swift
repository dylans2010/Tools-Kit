import SwiftUI

struct DotGitignoreGeneratorDevTool: DevTool {
    let id = "gitignore-gen"
    let name = ".gitignore Generator"
    let category: DevToolCategory = .automation
    let icon = "eye.slash"
    let description = "Generate .gitignore files for Swift and Xcode"

    func render() -> some View {
        Text("Swift/Xcode .gitignore")
            .font(.headline)
            .padding()
        Text(".DS_Store\nbuild/\n*.xcodeproj/project.xcworkspace/\n*.xcuserdata/\nDerivedData/\n.swiftpm/xcode/package.xcworkspace/xcuserdata/")
            .font(.system(.caption, design: .monospaced))
            .padding()
    }
}
