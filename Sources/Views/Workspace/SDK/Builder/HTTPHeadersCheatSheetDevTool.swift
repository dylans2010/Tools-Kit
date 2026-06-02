import SwiftUI

struct HTTPHeadersCheatSheetDevTool: DevTool {
    let id = "http-headers-cheat"
    let name = "HTTP Headers Cheat Sheet"
    let category: DevToolCategory = .networking
    let icon = "list.bullet.rectangle"
    let description = "Common HTTP request and response headers"

    func render() -> some View {
        List {
            Section("Request Headers") {
                Text("Accept: application/json")
                Text("Authorization: Bearer <token>")
                Text("Content-Type: application/json")
                Text("User-Agent: ...")
            }
            Section("Response Headers") {
                Text("Cache-Control: no-cache")
                Text("Content-Length: 1234")
                Text("Set-Cookie: ...")
            }
        }
    }
}
