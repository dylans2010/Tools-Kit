import SwiftUI

struct SDKStateInspectorView: View {
    @StateObject private var stateStore = SDKStateStore.shared

    var body: some View {
        List {
            Section("Global State Store") {
                Text("Real-time reactive state inspection").font(.caption).foregroundStyle(.secondary)
                // In a full implementation, we'd iterate over stateStore.state keys
                Label("Session ID: active_session_001", systemImage: "key.fill")
                Label("Last Sync: \(Date().formatted())", systemImage: "clock.fill")
            }
        }
        .navigationTitle("State Inspector")
    }
}
