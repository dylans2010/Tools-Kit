import SwiftUI

struct BundleSizeAnalyzerDevTool: DevTool {
    let id = "bundle-size-analyzer"
    let name = "Bundle Size Analyzer"
    let category: DevToolCategory = .performance
    let icon = "chart.pie"
    let description = "Analyze app bundle composition and size"

    func render() -> some View {
        SimpleDevToolView(title: name, placeholder: "Analyze current bundle") { _ in
            let bundle = Bundle.main
            let path = bundle.bundlePath
            return "Bundle: \(path.components(separatedBy: "/").last ?? path)\nExecutable: \(bundle.executableURL?.lastPathComponent ?? "N/A")\nInfo.plist keys: \(bundle.infoDictionary?.count ?? 0)\nLocalizations: \(bundle.localizations.joined(separator: ", "))"
        }
    }
}
