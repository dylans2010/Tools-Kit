import SwiftUI

struct HTTPStatusCodeRefDevTool: DevTool {
    let id = "http-status-code-ref"
    let name = "HTTP Status Code Reference"
    let category: DevToolCategory = .networking
    let icon = "list.number"
    let description = "Quick reference for all HTTP response status codes"

    func render() -> some View {
        List {
            Section("1xx Informational") {
                statusRow(100, "Continue")
                statusRow(101, "Switching Protocols")
            }
            Section("2xx Success") {
                statusRow(200, "OK")
                statusRow(201, "Created")
                statusRow(204, "No Content")
            }
            Section("3xx Redirection") {
                statusRow(301, "Moved Permanently")
                statusRow(302, "Found")
                statusRow(304, "Not Modified")
            }
            Section("4xx Client Error") {
                statusRow(400, "Bad Request")
                statusRow(401, "Unauthorized")
                statusRow(403, "Forbidden")
                statusRow(404, "Not Found")
                statusRow(429, "Too Many Requests")
            }
            Section("5xx Server Error") {
                statusRow(500, "Internal Server Error")
                statusRow(502, "Bad Gateway")
                statusRow(503, "Service Unavailable")
                statusRow(504, "Gateway Timeout")
            }
        }
    }

    private func statusRow(_ code: Int, _ name: String) -> some View {
        HStack {
            Text("\(code)").font(.system(.body, design: .monospaced)).bold()
            Text(name)
        }
    }
}
