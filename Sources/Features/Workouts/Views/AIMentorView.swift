import SwiftUI

struct AIMentorView: View {
    @StateObject private var manager = WorkoutsManager.shared

    var body: some View {
        VStack(spacing: 0) {
            List {
                Section("Snapshot") {
                    Text(manager.mentorContextPreview)
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
            }
            .frame(height: 180)

            AIMentorChatView()
        }
        .navigationTitle("AI Mentor")
        .onAppear {
            manager.ensureMentorMemoryLoaded()
        }
    }
}
