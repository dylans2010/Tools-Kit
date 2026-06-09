import SwiftUI

public struct FeedbackAdminDebugPanel: View {
    @State private var showingResetAlert = false

    public init() {}

    public var body: some View {
        List {
            Section("Diagnostics Override") {
                Button("Force Diagnostics Capture") {
                    Task {
                        _ = await DiagnosticsManager.shared.captureDiagnostics()
                    }
                }
                Button("Dump Logs to Console") {
                    // print logs
                }
            }

            Section("Sync Management") {
                Button("Force Sync Queue") {
                    // trigger sync
                }
                Button("Clear Pending Queue", role: .destructive) {
                    // clear queue
                }
            }

            Section("Data Management") {
                Button("Reset Feedback System", role: .destructive) {
                    showingResetAlert = true
                }
            }
        }
        .navigationTitle("Admin Debug")
        .alert("Reset Feedback?", isPresented: $showingResetAlert) {
            Button("Reset", role: .destructive) {
                // Clear all local data
                UserDefaults.standard.removeObject(forKey: "com.toolskit.feedback.reports")
                UserDefaults.standard.removeObject(forKey: "com.toolskit.feedback.pending")
            }
            Button("Cancel", role: .cancel) {}
        }
    }
}
