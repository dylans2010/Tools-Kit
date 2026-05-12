import SwiftUI

struct SecureRouterTool: Tool, Sendable {
    let name = "Secure Router"
    let icon = "network.badge.shield.half.filled"
    let category = ToolCategory.network
    let complexity = ToolComplexity.advanced
    let description = "Route requests through a configurable endpoint with retry handling"
    let requiresAPI = false
    var view: AnyView { AnyView(SecureRouterView()) }
}

struct SecureRouterView: View {
    @StateObject private var backend = SecureRouterBackend()

    var body: some View {
        ToolDetailView(tool: SecureRouterTool()) {
            VStack(spacing: 16) {
                enableToggle
                regionSection
                if backend.selectedRegion?.id == "custom" {
                    customEndpointSection
                }
                retrySection
                testSection
            }
        }
        .navigationTitle("Secure Router")
    }

    private var enableToggle: some View {
        ToolInputSection("Mode") {
            Toggle(isOn: $backend.isEnabled) {
                HStack(spacing: 12) {
                    Image(systemName: "shield.fill")
                        .foregroundColor(backend.isEnabled ? .green : .secondary)
                    VStack(alignment: .leading) {
                        Text("Secure Routing")
                            .font(.subheadline.weight(.medium))
                        Text(backend.isEnabled ? "Active – routing through \(backend.activeEndpoint)" : "Disabled")
                            .font(.caption).foregroundColor(.secondary)
                    }
                }
            }
            .padding()
        }
    }

    private var regionSection: some View {
        ToolInputSection("Routing Endpoint") {
            ForEach(backend.regions) { region in
                Button {
                    backend.selectedRegion = region
                } label: {
                    HStack {
                        Text(region.flag)
                        Text(region.name).foregroundColor(.primary)
                        if region.id != "custom" {
                            Text(region.endpoint)
                                .font(.caption).foregroundColor(.secondary)
                        }
                        Spacer()
                        if backend.selectedRegion?.id == region.id {
                            Image(systemName: "checkmark").foregroundColor(.blue)
                        }
                    }
                    .padding()
                }
                if region.id != backend.regions.last?.id { Divider().padding(.leading) }
            }
        }
    }

    private var customEndpointSection: some View {
        ToolInputSection("Custom Endpoint URL") {
            HStack {
                Image(systemName: "link").foregroundColor(.secondary)
                TextField("https://your-proxy.example.com", text: $backend.customEndpoint)
                    .autocapitalization(.none).disableAutocorrection(true)
                    .keyboardType(.URL)
            }
            .padding()
        }
    }

    private var retrySection: some View {
        ToolInputSection("Retry Attempts") {
            HStack {
                Text("Retries on failure")
                Spacer()
                Stepper("\(backend.retryCount)", value: $backend.retryCount, in: 0...5)
            }
            .padding()
        }
    }

    private var testSection: some View {
        ToolInputSection("Connectivity Test") {
            VStack(spacing: 0) {
                Button {
                    Task { await backend.testConnectivity() }
                } label: {
                    if backend.isTesting {
                        HStack {
                            ProgressView().padding(.trailing, 6)
                            Text("Testing…")
                        }
                        .frame(maxWidth: .infinity).padding(.vertical, 4)
                    } else {
                        Label("Test Connection", systemImage: "antenna.radiowaves.left.and.right")
                            .frame(maxWidth: .infinity).padding(.vertical, 4)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(backend.isTesting || backend.activeEndpoint.isEmpty)
                .padding()

                if !backend.testResult.isEmpty {
                    Divider()
                    Text(backend.testResult)
                        .font(.subheadline)
                        .foregroundColor(backend.testResult.hasPrefix("✅") ? .green : .red)
                        .padding()
                }
            }
        }
    }
}
