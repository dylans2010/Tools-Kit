import SwiftUI

struct SDKAPIBrowserView: View {
    @ObservedObject var sdk = WorkspaceSDK.shared
    @State private var searchText = ""

    var filteredRoutes: [SDKRoute] {
        let routes = sdk.apiRoutes()
        if searchText.isEmpty { return routes }
        return routes.filter { $0.path.lowercased().contains(searchText.lowercased()) || $0.module.lowercased().contains(searchText.lowercased()) }
    }

    var body: some View {
        List {
            ForEach(filteredRoutes) { route in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(route.method.rawValue)
                            .font(.caption2.bold())
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(methodColor(route.method).opacity(0.2))
                            .foregroundColor(methodColor(route.method))
                            .cornerRadius(4)

                        Text(route.path)
                            .font(.system(.subheadline, design: .monospaced))
                    }

                    if !route.description.isEmpty {
                        Text(route.description)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Text("Module: \(route.module)")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("API Browser")
        .searchable(text: $searchText, prompt: "Search endpoints")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Task { await sdk.kernel.boot() }
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
            }
        }
    }

    private func methodColor(_ method: SDKRoute.Method) -> Color {
        switch method {
        case .get: return .blue
        case .post: return .green
        case .put: return .orange
        case .delete: return .red
        }
    }
}
