import SwiftUI

struct SDKBuildAnalyzerDevTool: DevTool {
    let id = "sdk-build-analyzer"
    let name = "SDK Build Analyzer"
    let category = DevToolCategory.diagnostics
    let icon = "waveform.path.ecg.rectangle"
    let description = "Detailed analysis of SDK build performance and bottlenecks"

    func render() -> some View {
        SDKBuildStatView() // Reuse the view or create a specific one
    }
}
