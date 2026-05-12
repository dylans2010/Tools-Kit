import SwiftUI

struct AspectRatioView: View {
    @StateObject private var backend = AspectRatioBackend()
    @State private var width: String = ""
    @State private var height: String = ""

    var body: some View {
        ToolDetailView(tool: AspectRatioTool()) {
            VStack(spacing: 24) {
                HStack(spacing: 16) {
                    ToolInputSection("Width") {
                        TextField("W", text: $width)
                            .keyboardType(.numberPad)
                            .padding()
                    }

                    ToolInputSection("Height") {
                        TextField("H", text: $height)
                            .keyboardType(.numberPad)
                            .padding()
                    }
                }

                Button("Calculate Ratio") {
                    if let w = Double(width), let h = Double(height) {
                        backend.calculate(width: w, height: h)
                    }
                }
                .buttonStyle(.borderedProminent)

                if !backend.result.isEmpty {
                    ToolOutputView("Aspect Ratio", value: backend.result)
                }
            }
        }
    }
}

struct AspectRatioTool: Tool, Sendable {
    let name = "Aspect Ratio"
    let icon = "aspectratio"
    let category = ToolCategory.utility
    let complexity = ToolComplexity.basic
    let description = "Calculate and simplify aspect ratios for images and videos"
    let requiresAPI = false
    var view: AnyView { AnyView(AspectRatioView()) }
}
