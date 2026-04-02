import SwiftUI

struct IPInfoView: View {
    @StateObject private var backend = IPInfoBackend()

    var body: some View {
        VStack(spacing: 20) {
            Button(action: { backend.fetch() }) {
                if backend.isLoading {
                    ProgressView()
                } else {
                    Text("Fetch My IP Info")
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal)

            if !backend.error.isEmpty {
                Text(backend.error)
                    .foregroundColor(.red)
                    .padding()
            }

            if let info = backend.info {
                List {
                    Section(header: Text("Network")) {
                        InfoRow(label: "IP Address", value: info.ip ?? "Unknown")
                        InfoRow(label: "Organization", value: info.org ?? "Unknown")
                    }

                    Section(header: Text("Location")) {
                        InfoRow(label: "City", value: info.city ?? "Unknown")
                        InfoRow(label: "Region", value: info.region ?? "Unknown")
                        InfoRow(label: "Country", value: info.country_name ?? "Unknown")
                        InfoRow(label: "Coordinates", value: "\(info.latitude ?? 0), \(info.longitude ?? 0)")
                    }
                }
            } else if !backend.isLoading {
                ContentUnavailableView("No IP Info", systemImage: "network", description: Text("Tap the button to fetch your current IP details."))
            }
        }
        .navigationTitle("IP Info")
    }
}

struct InfoRow: View {
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

// Fallback for ContentUnavailableView if iOS < 17
#if !compiler(>=5.9) || !canImport(SwiftUI, _version: "17.0")
struct ContentUnavailableView<Label: View, Description: View>: View {
    let label: Label
    let description: Description
    let systemImage: String

    init(_ title: String, systemImage: String, description: Description) where Label == Text {
        self.label = Text(title)
        self.systemImage = systemImage
        self.description = description
    }

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: systemImage)
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            label.font(.headline)
            description.font(.subheadline).foregroundColor(.secondary)
        }
        .padding()
    }
}
#endif

struct IPInfoTool: Tool {
    let name = "IP Info"
    let icon = "network"
    let category = ToolCategory.utility
    let complexity = ToolComplexity.basic
    let description = "Get details about your current IP address"
    let requiresAPI = true
    var view: AnyView { AnyView(IPInfoView()) }
}
