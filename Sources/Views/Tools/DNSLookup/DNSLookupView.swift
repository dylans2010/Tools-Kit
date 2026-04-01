import SwiftUI
struct DNSLookupView: View {
    @StateObject private var backend = DNSLookupBackend()
    var body: some View {
        VStack(spacing: 16) {
            Button("DNS Lookup") { backend.lookup() }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .navigationTitle("DNS Lookup")
    }
}
struct DNSLookupTool: Tool {
    let name = "DNS Lookup"
    let icon = "magnifyingglass.circle"
    let category = ToolCategory.utility
    let complexity = ToolComplexity.basic
    let description = "DNS Lookup"
    let isOfflineCapable = false
    let requiresAPI = true
    let isAIEnabled = false
    let complexityLevel = 2
    var view: AnyView { AnyView(DNSLookupView()) }
}
