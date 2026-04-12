import SwiftUI

struct MathSuiteView: View {
    @StateObject private var backend = MathSuiteBackend()
    @State private var numA: String = ""
    @State private var numB: String = ""

    var body: some View {
        ToolDetailView(tool: MathSuiteTool()) {
            VStack(spacing: 24) {
                HStack(spacing: 16) {
                    ToolInputSection("Number A") {
                        TextField("A", text: $numA)
                            .keyboardType(.numberPad)
                            .padding()
                    }

                    ToolInputSection("Number B") {
                        TextField("B", text: $numB)
                            .keyboardType(.numberPad)
                            .padding()
                    }
                }

                Button("Calculate GCD & LCM") {
                    if let a = Int(numA), let b = Int(numB) {
                        backend.calculate(a: a, b: b)
                    }
                }
                .buttonStyle(.borderedProminent)

                if !backend.gcdResult.isEmpty {
                    ToolOutputView("Greatest Common Divisor (GCD)", value: backend.gcdResult)
                    ToolOutputView("Least Common Multiple (LCM)", value: backend.lcmResult)
                }
            }
        }
    }
}

struct MathSuiteTool: Tool {
    let name = "Math: GCD & LCM"
    let icon = "function"
    let category = ToolCategory.utility
    let complexity = ToolComplexity.basic
    let description = "Calculate Greatest Common Divisor and Least Common Multiple of two numbers"
    let requiresAPI = false
    var view: AnyView { AnyView(MathSuiteView()) }
}
