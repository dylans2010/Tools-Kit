import SwiftUI

struct HTTPStatusCheatSheetDevTool: DevTool {
    let id = "http-status-codes"
    let name = "HTTP Status Cheat Sheet"
    let category: DevToolCategory = .networking
    let icon = "network"
    let description = "Cheat sheet for HTTP response status codes"

    func render() -> some View {
        List {
            Section("1xx Informational") { Text("100 Continue") }
            Section("2xx Success") { Text("200 OK"); Text("201 Created"); Text("204 No Content") }
            Section("3xx Redirection") { Text("301 Moved Permanently"); Text("302 Found"); Text("304 Not Modified") }
            Section("4xx Client Error") { Text("400 Bad Request"); Text("401 Unauthorized"); Text("403 Forbidden"); Text("404 Not Found") }
            Section("5xx Server Error") { Text("500 Internal Server Error"); Text("502 Bad Gateway"); Text("503 Service Unavailable") }
        }
    }
}
