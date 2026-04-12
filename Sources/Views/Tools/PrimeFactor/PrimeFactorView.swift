import SwiftUI

struct PrimeFactorView: View {
    @StateObject private var backend = PrimeFactorBackend()
    @State private var input: String = ""

    var body: some View {
        ToolDetailView(tool: PrimeFactorTool()) {
            VStack(spacing: 24) {
                ToolInputSection("Positive Integer") {
                    TextField("Enter number", text: $input)
                        .keyboardType(.numberPad)
                        .padding()
                }

                Button("Factorize") {
                    if let n = Int(input), n > 1 {
                        backend.factorize(n)
                    }
                }
                .buttonStyle(.borderedProminent)

                if !backend.factors.isEmpty {
                    ToolOutputView("Prime Factors", value: backend.factors)
                }
            }
        }
    }
}

struct PrimeFactorTool: Tool {
    let name = "Prime Factorization"
    let icon = "numbersign"
    let category = ToolCategory.utility
    let complexity = ToolComplexity.basic
    let description = "Break down any positive integer into its prime factors"
    let requiresAPI = false
    var view: AnyView { AnyView(PrimeFactorView()) }
}
