import SwiftUI

struct DeveloperBetaTestingView: View {
    var body: some View {
        List {
            Section("Internal Testing") {
                HStack {
                    VStack(alignment: .leading) {
                        Text("Core Team").font(.subheadline.bold())
                        Text("12 Testers").font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text("Active").font(.caption2.bold()).foregroundStyle(.green)
                }
            }

            Section("External Beta") {
                HStack {
                    VStack(alignment: .leading) {
                        Text("Public Beta Group").font(.subheadline.bold())
                        Text("450/1000 Testers").font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text("Active").font(.caption2.bold()).foregroundStyle(.green)
                }
            }

            Section("Feedback") {
                ForEach(0..<3) { i in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("User \(i+123)").font(.caption.bold())
                            Spacer()
                            Text("v1.2.0 (45)").font(.system(size: 8)).foregroundStyle(.tertiary)
                        }
                        Text("This is some dummy feedback from a beta tester regarding a crash in the latest build.").font(.caption).foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }

            Section {
                Button("Invite Testers") {}
                Button("Create New Testing Group") {}
            }
        }
        .navigationTitle("Beta Testing")
    }
}
