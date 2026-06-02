import SwiftUI

struct ProxyConfigDevTool: DevTool {
    let id = "proxy-config"
    let name = "Proxy Configuration"
    let category: DevToolCategory = .networking
    let icon = "arrow.triangle.branch"
    let description = "Configure and test proxy settings for network requests"

    func render() -> some View {
        SimpleDevToolView(title: name, placeholder: "Enter proxy URL (e.g. http://proxy:8080)") { input in
            "Proxy: \(input)\nType: HTTP/HTTPS\nStatus: Ready to configure"
        }
    }
}
