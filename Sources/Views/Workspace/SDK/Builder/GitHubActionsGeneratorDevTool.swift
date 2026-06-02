import SwiftUI

struct GitHubActionsGeneratorDevTool: DevTool {
    let id = "github-actions-gen"
    let name = "GitHub Actions Generator"
    let category: DevToolCategory = .automation
    let icon = "bolt.fill"
    let description = "Generate CI/CD workflows for GitHub Actions"

    func render() -> some View {
        Text("Swift Test Workflow")
            .font(.headline)
            .padding()
        Text("name: Swift\non: [push]\njobs:\n  build:\n    runs-on: macos-latest\n    steps:\n    - uses: actions/checkout@v4\n    - name: Build\n      run: swift build\n    - name: Run tests\n      run: swift test")
            .font(.system(.caption, design: .monospaced))
            .padding()
    }
}
