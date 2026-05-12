import SwiftUI

struct IPIntelligenceTool: Tool, Sendable {
    let name = "IP Intelligence"
    let icon = "antenna.radiowaves.left.and.right"
    let category = ToolCategory.network
    let complexity = ToolComplexity.advanced
    let description = "Detailed IP geolocation, ISP, and VPN/proxy detection"
    let requiresAPI = false
    var view: AnyView { AnyView(IPIntelligenceView()) }
}

struct IPIntelligenceView: View {
    @StateObject private var backend = IPIntelligenceBackend()

    var body: some View {
        ToolDetailView(tool: IPIntelligenceTool()) {
            VStack(spacing: 16) {
                inputSection
                if backend.isLoading {
                    ProgressView("Fetching intelligence…")
                        .frame(maxWidth: .infinity).padding()
                        .background(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(12)
                }
                if !backend.errorMessage.isEmpty {
                    errorCard
                }
                if let data = backend.data {
                    resultsView(data)
                }
            }
        }
        .navigationTitle("IP Intelligence")
        .task { await backend.lookup() }
    }

    private var inputSection: some View {
        ToolInputSection("Target IP") {
            VStack(spacing: 0) {
                HStack {
                    Image(systemName: "network").foregroundColor(.secondary).frame(width: 20)
                    TextField("IP address (leave blank for yours)", text: $backend.lookupIP)
                        .autocapitalization(.none).disableAutocorrection(true)
                        .keyboardType(.numbersAndPunctuation)
                }
                .padding()
                Divider()
                HStack(spacing: 12) {
                    Button {
                        Task { await backend.lookup() }
                    } label: {
                        Label("Analyze", systemImage: "magnifyingglass")
                            .frame(maxWidth: .infinity).padding(.vertical, 4)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(backend.isLoading)

                    Button {
                        backend.clearCache()
                    } label: {
                        Image(systemName: "trash")
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
                }
                .padding()
            }
        }
    }

    private var errorCard: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill").foregroundColor(.orange)
            Text(backend.errorMessage).font(.subheadline)
        }
        .padding().frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.orange.opacity(0.1)).cornerRadius(12)
    }

    @ViewBuilder
    private func resultsView(_ data: IPIntelligenceData) -> some View {
        HStack(spacing: 12) {
            riskBadge(data)
            Spacer()
        }

        ToolInputSection("Network") {
            infoRow(label: "IP Address", value: data.ip, icon: "network")
            Divider().padding(.leading, 44)
            infoRow(label: "Country Code", value: data.asNumber, icon: "flag")
            Divider().padding(.leading, 44)
            infoRow(label: "Continent", value: data.isp, icon: "globe")
            Divider().padding(.leading, 44)
            infoRow(label: "Continent Code", value: data.org, icon: "number")
        }

        ToolInputSection("Location") {
            infoRow(label: "Country", value: data.country, icon: "flag")
            Divider().padding(.leading, 44)
            infoRow(label: "Region", value: data.region, icon: "map")
            Divider().padding(.leading, 44)
            infoRow(label: "City", value: "\(data.city) \(data.zip)", icon: "building.columns")
            Divider().padding(.leading, 44)
            infoRow(label: "Timezone", value: data.timezone, icon: "clock")
            Divider().padding(.leading, 44)
            infoRow(label: "Coordinates", value: String(format: "%.4f, %.4f", data.latitude, data.longitude), icon: "location")
        }

        ToolInputSection("Privacy Signals") {
            flagRow(label: "Proxy / VPN", flagged: data.isProxy, icon: "shield.lefthalf.filled")
            Divider().padding(.leading, 44)
            flagRow(label: "Hosting / Datacenter", flagged: data.isHosting, icon: "server.rack")
            Divider().padding(.leading, 44)
            flagRow(label: "Mobile Network", flagged: data.isMobile, icon: "iphone")
        }
    }

    private func riskBadge(_ data: IPIntelligenceData) -> some View {
        let isRisky = data.isProxy || data.isHosting
        return HStack {
            Image(systemName: isRisky ? "exclamationmark.shield.fill" : "checkmark.shield.fill")
                .foregroundColor(isRisky ? .orange : .green)
            Text(isRisky ? "Suspicious signals detected" : "No suspicious signals")
                .font(.subheadline.weight(.medium))
                .foregroundColor(isRisky ? .orange : .green)
        }
        .padding()
        .background((isRisky ? Color.orange : Color.green).opacity(0.1))
        .cornerRadius(12)
    }

    private func infoRow(label: String, value: String, icon: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue).frame(width: 20)
            Text(label).foregroundColor(.secondary).font(.subheadline)
            Spacer()
            Text(value).font(.subheadline.weight(.medium))
                .multilineTextAlignment(.trailing)
        }
        .padding(.horizontal).padding(.vertical, 10)
    }

    private func flagRow(label: String, flagged: Bool, icon: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(flagged ? .orange : .green).frame(width: 20)
            Text(label).foregroundColor(.secondary).font(.subheadline)
            Spacer()
            Text(flagged ? "Yes" : "No")
                .font(.subheadline.bold())
                .foregroundColor(flagged ? .orange : .green)
        }
        .padding(.horizontal).padding(.vertical, 10)
    }
}
