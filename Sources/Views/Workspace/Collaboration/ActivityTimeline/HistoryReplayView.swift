import SwiftUI

struct HistoryReplayView: View {
    @Environment(\.dismiss) var dismiss
    let commits: [CollaborationCommit]
    @State private var currentStep: Int = 0

    var body: some View {
        NavigationStack {
            VStack {
                // Visualization area
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.workspaceSurface)

                    if !commits.isEmpty {
                        VStack {
                            Text("Replaying Step \(currentStep + 1) of \(commits.count)")
                                .font(.headline)
                            Text(commits[currentStep].message)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    } else {
                        Text("No history to replay")
                            .foregroundColor(.secondary)
                    }
                }
                .padding()

                // Controls
                VStack(spacing: 20) {
                    Slider(value: Binding(
                        get: { Double(currentStep) },
                        set: { currentStep = Int($0) }
                    ), in: 0...Double(max(0, commits.count - 1)), step: 1)

                    HStack(spacing: 40) {
                        Button(action: { if currentStep > 0 { currentStep -= 1 } }) {
                            Image(systemName: "backward.fill")
                        }

                        Button(action: { /* Auto play logic */ }) {
                            Image(systemName: "play.fill")
                                .font(.title)
                        }

                        Button(action: { if currentStep < commits.count - 1 { currentStep += 1 } }) {
                            Image(systemName: "forward.fill")
                        }
                    }
                    .font(.title2)
                }
                .padding()
            }
            .navigationTitle("History Replay")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}
