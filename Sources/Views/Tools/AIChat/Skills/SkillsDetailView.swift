import SwiftUI

struct SkillsDetailView: View {
    @Binding var skill: Skill
    @StateObject private var skillsManager = AIService.SkillsManager.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Form {
            Section("Details") {
                TextField("Name", text: $skill.name)
                Toggle("Active", isOn: $skill.isActive)
            }

            Section("Content (Markdown)") {
                TextEditor(text: $skill.content)
                    .frame(minHeight: 300)
                    .font(.system(.body, design: .monospaced))
            }
        }
        .navigationTitle(skill.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Save") {
                    skillsManager.updateSkill(skill)
                    dismiss()
                }
            }
        }
    }
}
