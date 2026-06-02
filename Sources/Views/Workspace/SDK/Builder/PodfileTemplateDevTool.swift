import SwiftUI

struct PodfileTemplateDevTool: DevTool {
    let id = "podfile-template"
    let name = "Podfile Template"
    let category: DevToolCategory = .automation
    let icon = "p.circle"
    let description = "Template for CocoaPods Podfile"

    func render() -> some View {
        Text("Podfile Template")
            .font(.headline)
            .padding()
        Text("platform :ios, '15.0'\nuse_frameworks!\n\ntarget 'YourApp' do\n  pod 'Alamofire'\nend")
            .font(.system(.caption, design: .monospaced))
            .padding()
    }
}
