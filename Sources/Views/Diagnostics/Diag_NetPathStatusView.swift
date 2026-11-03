import SwiftUI
import Network

final class DiagNewPathStatusModel: ObservableObject {
    @Published var status = "Unknown"
    @Published var isExpensive = false
    @Published var isConstrained = false
    private var monitor: NWPathMonitor?

    func start() {
        let m = NWPathMonitor()
        monitor = m
        m.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.status = String(describing: path.status)
                self?.isExpensive = path.isExpensive
                self?.isConstrained = path.isConstrained
            }
        }
        m.start(queue: .global(qos: .utility))
    }

    func stop() { monitor?.cancel(); monitor = nil }
}

struct Diag_NetPathStatusView: View {
    @StateObject private var model = DiagNewPathStatusModel()

    var body: some View {
        Form {
            Section("Path") {
                LabeledContent("Status") { Text(model.status) }
                LabeledContent("Expensive") { Text(model.isExpensive ? "Yes" : "No") }
                LabeledContent("Constrained") { Text(model.isConstrained ? "Yes" : "No") }
            }
            Section { Button("Refresh") { model.start() } }
        }
        .navigationTitle("Network Path")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { model.start() }
        .onDisappear { model.stop() }
    }
}
