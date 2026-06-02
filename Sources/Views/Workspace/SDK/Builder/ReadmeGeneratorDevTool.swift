import SwiftUI

struct ReadmeGeneratorDevTool: DevTool {
    let id = "readme-gen"
    let name = "README Generator"
    let category: DevToolCategory = .utilities
    let icon = "doc.text.below.ecg"
    let description = "Generate professional README.md templates"

    func render() -> some View {
        SimpleDevToolView(title: name, placeholder: "Project Name") { input in
            "# \(input)\n\n## Description\nAdd description here.\n\n## Installation\n```bash\nswift build\n```\n\n## Usage\nExplain usage here."
        }
    }
}
