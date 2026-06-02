import SwiftUI

struct AppReceiptInspectorDevTool: DevTool {
    let id = "app-receipt-inspector"
    let name = "App Receipt Inspector"
    let category: DevToolCategory = .security
    let icon = "scroll"
    let description = "Inspect local App Store receipt for validation testing"

    func render() -> some View {
        List {
            Section("Receipt Location") {
                if let url = Bundle.main.appStoreReceiptURL {
                    Text(url.path).font(.caption2).foregroundStyle(.secondary)
                    Button("Check Existence") {
                        // Simulation
                    }
                } else {
                    Text("No receipt URL found").foregroundStyle(.red)
                }
            }
            Section("Guidance") {
                Text("In sandbox mode, use StoreKit testing to generate a mock receipt.")
            }
        }
    }
}
