import SwiftUI

struct CSRGeneratorDevTool: DevTool {
    let id = "csr-gen"
    let name = "CSR Generator"
    let category: DevToolCategory = .security
    let icon = "doc.badge.gearshape"
    let description = "Generate Certificate Signing Requests"

    func render() -> some View {
        SimpleDevToolView(title: name, placeholder: "Common Name (e.g. example.com)") { input in
            "-----BEGIN CERTIFICATE REQUEST-----\nMIIB... (Mocked CSR for \(input))\n-----END CERTIFICATE REQUEST-----"
        }
    }
}
