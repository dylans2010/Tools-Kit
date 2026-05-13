import SwiftUI

struct AddSkillView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showDraft = false
    @State private var useAI = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button {
                        useAI = false
                        showDraft = true
                    } label: {
                        Label {
                            VStack(alignment: .leading) {
                                Text("Write Skill")
                                Text("Manually define AI behavior and rules.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        } icon: {
                            Image(systemName: "pencil")
                        }
                    }

                    Button {
                        useAI = true
                        showDraft = true
                    } label: {
                        Label {
                            VStack(alignment: .leading) {
                                Text("Generate with AI")
                                Text("Let AI help you draft a skill based on a prompt.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        } icon: {
                            Image(systemName: "sparkles")
                        }
                    }
                } header: {
                    Text("Creation Method")
                }
            }
            .navigationTitle("Add Skill")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .navigationDestination(isPresented: $showDraft) {
                DraftSkillsView(isAIGenerated: useAI)
            }
        }
    }
}
