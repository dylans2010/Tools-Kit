import SwiftUI

struct PortCheckerView: View {
    @StateObject private var backend = PortCheckerBackend()

    var body: some View {
        VStack(spacing: 24) {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Hostname or IP").font(.caption).foregroundColor(.secondary)
                    TextField("e.g., google.com", text: $backend.host)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Port Number").font(.caption).foregroundColor(.secondary)
                    TextField("e.g., 443", text: $backend.port)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.numberPad)
                }
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)

            Button(action: backend.check) {
                if backend.isChecking {
                    ProgressView().tint(.white)
                } else {
                    Label("Check Port Status", systemImage: "network")
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(backend.isChecking || backend.host.isEmpty || backend.port.isEmpty)
            .padding(.horizontal)

            if !backend.status.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: statusIcon)
                        .font(.system(size: 40))
                        .foregroundColor(statusColor)

                    Text(backend.status)
                        .font(.headline)
                        .multilineTextAlignment(.center)
                        .foregroundColor(statusColor)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(statusColor.opacity(0.1))
                .cornerRadius(12)
                .padding(.horizontal)
            }

            Spacer()
        }
        .padding()
        .navigationTitle("Port Checker")
    }

    private var statusColor: Color {
        switch backend.color {
        case "green": return .green
        case "red": return .red
        case "orange": return .orange
        default: return .gray
        }
    }

    private var statusIcon: String {
        switch backend.color {
        case "green": return "checkmark.shield.fill"
        case "red": return "xmark.shield.fill"
        case "orange": return "exclamationmark.shield.fill"
        default: return "questionmark.shield"
        }
    }
}

struct PortCheckerTool: Tool, Sendable {
    let name = "Port Checker"
    let icon = "server.rack"
    let category = ToolCategory.utility
    let complexity = ToolComplexity.advanced
    let description = "Check if a specific port is open on a remote host"
    let requiresAPI = true
    var view: AnyView { AnyView(PortCheckerView()) }
}
