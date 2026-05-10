import SwiftUI

struct IPInfoView: View {
    @StateObject private var backend = IPInfoBackend()

    var body: some View {
        VStack(spacing: 0) {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Get detailed geographical and network information about your current internet connection.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        Button(action: { backend.fetch() }) {
                            if backend.isLoading {
                                HStack {
                                    Spacer()
                                    ProgressView()
                                    Spacer()
                                }
                            } else {
                                Label("Fetch Details", systemImage: "arrow.down.circle")
                                    .frame(maxWidth: .infinity)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(backend.isLoading)
                        .padding(.vertical, 8)
                    }
                } header: {
                    Text("Lookup")
                }

                if !backend.error.isEmpty {
                    Section {
                        Text(backend.error)
                            .foregroundColor(.red)
                    }
                }

                if let info = backend.info {
                    Section {
                        IPInfoRow(label: "IP Address", value: info.ip ?? "Unknown")
                        IPInfoRow(label: "Organization", value: info.org ?? "Unknown")
                    } header: {
                        Text("Network")
                    }

                    Section {
                        IPInfoRow(label: "City", value: info.city ?? "Unknown")
                        IPInfoRow(label: "Region", value: info.region ?? "Unknown")
                        IPInfoRow(label: "Country", value: info.country_name ?? "Unknown")
                        IPInfoRow(label: "Coordinates", value: "\(info.latitude ?? 0), \(info.longitude ?? 0)")
                        IPInfoRow(label: "Timezone", value: info.timezone ?? "Unknown")
                    } header: {
                        Text("Location")
                    } footer: {
                        Text("IP information provided by public lookup services.")
                    }
                }
            }
        }
        .navigationTitle("IP Info")
    }
}

struct IPInfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label).foregroundColor(.secondary)
            Spacer()
            Text(value).bold()
        }
    }
}

struct IPInfoTool: Tool {
    let name = "IP Info"
    let icon = "network"
    let category = ToolCategory.utility
    let complexity = ToolComplexity.basic
    let description = "Get details about your current IP address"
    let requiresAPI = true
    var view: AnyView { AnyView(IPInfoView()) }
}
