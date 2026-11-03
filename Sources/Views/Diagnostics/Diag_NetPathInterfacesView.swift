import SwiftUI
import Network

final class DiagNewPathInterfacesModel: ObservableObject {
    @Published var interfaces: [String] = []
    private var monitor: NWPathMonitor?

    func start() {
        let m = NWPathMonitor()
        monitor = m
        m.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.interfaces = path.availableInterfaces.map { "\($0.name) (\($0.type))" }
            }
        }
        m.start(queue: .global(qos: .utility))
    }

    func stop() { monitor?.cancel(); monitor = nil }
}

struct Diag_NetPathInterfacesView: View {
    @StateObject private var model = DiagNewPathInterfacesModel()

    var body: some View {
        Form {
            Section("Available Interfaces") {
                if model.interfaces.isEmpty {
                    Text("Waiting for path update…").foregroundStyle(.secondary)
                } else {
                    ForEach(model.interfaces, id: \.self) { i in Text(i).font(.caption) }
                }
            }
            Section { Button("Refresh") { model.start() } }
        }
        .navigationTitle("Path Interfaces")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { model.start() }
        .onDisappear { model.stop() }
    }
}
