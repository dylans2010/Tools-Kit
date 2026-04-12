import SwiftUI

struct PercentChangeView: View {
    @StateObject private var backend = PercentChangeBackend()
    @State private var oldVal: String = ""
    @State private var newVal: String = ""

    var body: some View {
        ToolDetailView(tool: PercentChangeTool()) {
            VStack(spacing: 24) {
                ToolInputSection("Initial Value") {
                    TextField("From", text: $oldVal)
                        .keyboardType(.decimalPad)
                        .padding()
                }

                ToolInputSection("Final Value") {
                    TextField("To", text: $newVal)
                        .keyboardType(.decimalPad)
                        .padding()
                }

                Button("Calculate Change") {
                    if let o = Double(oldVal), let n = Double(newVal) {
                        backend.calculate(oldValue: o, newValue: n)
                    }
                }
                .buttonStyle(.borderedProminent)

                if !backend.result.isEmpty {
                    ToolOutputView("Percent Change", value: backend.result)
                }
            }
        }
    }
}

struct PercentChangeTool: Tool {
    let name = "Percent Change"
    let icon = "percent"
    let category = ToolCategory.utility
    let complexity = ToolComplexity.basic
    let description = "Calculate percentage increases and decreases between values"
    let requiresAPI = false
    var view: AnyView { AnyView(PercentChangeView()) }
}
