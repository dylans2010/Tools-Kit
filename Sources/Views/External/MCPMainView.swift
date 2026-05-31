import SwiftUI

struct MCPMainView: View {
    @StateObject private var manager = MCPManager.shared
    @State private var showingAddServer = false
    @State private var newServerName = ""
    @State private var newServerURL = ""

    var body: some View {
        List {
            Section("External Connections") {
                if manager.servers.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "network.badge.shield.half.filled")
                            .font(.system(size: 40))
                            .foregroundStyle(.secondary)
                        Text("No MCP Servers Connected")
                            .font(.headline)
                        Text("Connect external Model Context Protocol servers to extend Persona's capabilities with custom tools and data.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding(.vertical, 24)
                } else {
                    ForEach(manager.servers) { server in
                        NavigationLink(destination: MCPServerDetailView(server: server)) {
                            HStack {
                                statusIndicator(server.status)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(server.name).font(.subheadline.bold())
                                    Text(server.url.absoluteString).font(.system(size: 9)).foregroundStyle(.secondary)
                                }
                                Spacer()
                                Text("\(server.tools.count) tools").font(.system(size: 10, weight: .bold)).foregroundStyle(.tertiary)
                            }
                        }
                    }
                    .onDelete { indexSet in
                        indexSet.forEach { idx in
                            manager.removeServer(id: manager.servers[idx].id)
                        }
                    }
                }
            }

            Section {
                Button { showingAddServer = true } label: {
                    Label("Add MCP Server", systemImage: "plus.circle.fill")
                        .font(.subheadline.bold())
                }
            }
        }
        .navigationTitle("External Services")
        .sheet(isPresented: $showingAddServer) {
            addServerSheet
        }
    }

    private func statusIndicator(_ status: MCPServerStatus) -> some View {
        Circle()
            .fill(statusColor(status))
            .frame(width: 8, height: 8)
    }

    private func statusColor(_ status: MCPServerStatus) -> Color {
        switch status {
        case .connected: return .green
        case .connecting: return .blue
        case .disconnected: return .gray
        case .error: return .red
        }
    }

    private var addServerSheet: some View {
        NavigationStack {
            Form {
                Section("Server Configuration") {
                    TextField("Server Name", text: $newServerName)
                    TextField("Server URL (http://...)", text: $newServerURL)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                }

                Section {
                    Text("The server must implement the Model Context Protocol (MCP) to be recognized by the workspace.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Connect MCP Server")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { showingAddServer = false } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Connect") {
                        if let url = URL(string: newServerURL) {
                            manager.addServer(name: newServerName, url: url)
                            showingAddServer = false
                            newServerName = ""
                            newServerURL = ""
                        }
                    }
                    .disabled(newServerName.isEmpty || newServerURL.isEmpty)
                }
            }
        }
    }
}

struct MCPServerDetailView: View {
    let server: MCPServerConfig
    @StateObject private var manager = MCPManager.shared

    var body: some View {
        List {
            Section("Server Info") {
                LabeledContent("Status", value: server.status.rawValue)
                LabeledContent("Endpoint", value: server.url.absoluteString)
                LabeledContent("Last Seen", value: server.lastSeen.formatted(date: .abbreviated, time: .shortened))
            }

            Section("Available Tools") {
                if server.tools.isEmpty {
                    Text("No tools exposed by this server.").font(.caption).foregroundStyle(.secondary)
                } else {
                    ForEach(server.tools) { tool in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(tool.name).font(.system(size: 11, weight: .bold, design: .monospaced))
                            Text(tool.description).font(.caption).foregroundStyle(.secondary)

                            if !tool.parameters.isEmpty {
                                Text("Params: \(tool.parameters.keys.joined(separator: ", "))")
                                    .font(.system(size: 8))
                                    .foregroundStyle(.tertiary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }

            Section {
                Button("Reconnect") {
                    manager.connect(serverID: server.id)
                }
                Button(role: .destructive) {
                    manager.removeServer(id: server.id)
                } label: {
                    Text("Disconnect & Remove")
                }
            }
        }
        .navigationTitle(server.name)
    }
}
