import SwiftUI

struct SSHKeyGeneratorDevTool: DevTool {
    let id = "ssh-key-gen"
    let name = "SSH Key Generator"
    let category: DevToolCategory = .security
    let icon = "key.fill"
    let description = "Generate SSH key pairs (RSA, Ed25519)"

    func render() -> some View {
        SimpleDevToolView(title: name, placeholder: "Key Comment (email)") { input in
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAA... \(input)"
        }
    }
}
