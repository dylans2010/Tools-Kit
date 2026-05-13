import SwiftUI

struct SkillPickerModifier: ViewModifier {
    @Binding var text: String
    @StateObject private var skillsManager = AIService.SkillsManager.shared
    @State private var showPicker = false
    @State private var filterText = ""

    func body(content: Content) -> some View {
        ZStack(alignment: .bottomLeading) {
            content
                .onChange(of: text) { _, newValue in
                    if newValue.hasSuffix("/") {
                        showPicker = true
                        filterText = ""
                    } else if showPicker {
                        if let lastSlashIndex = newValue.lastIndex(of: "/") {
                            let suffix = newValue[newValue.index(after: lastSlashIndex)...]
                            if suffix.contains(" ") || suffix.contains("\n") {
                                showPicker = false
                            } else {
                                filterText = String(suffix)
                            }
                        } else {
                            showPicker = false
                        }
                    }
                }

            if showPicker {
                VStack {
                    pickerView
                        .frame(maxWidth: 300, maxHeight: 200)
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .shadow(radius: 8)
                        .padding(.bottom, 50) // Adjust based on keyboard/input height
                        .padding(.leading)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .zIndex(100)
            }
        }
    }

    private var pickerView: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Insert Skill")
                    .font(.caption.bold())
                    .foregroundColor(.secondary)
                Spacer()
                Button {
                    showPicker = false
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(Color(.secondarySystemBackground))

            List {
                let filteredSkills = skillsManager.skills.filter {
                    filterText.isEmpty || $0.name.localizedCaseInsensitiveContains(filterText)
                }

                if filteredSkills.isEmpty {
                    Text("No skills found")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    ForEach(filteredSkills) { skill in
                        Button {
                            selectSkill(skill)
                        } label: {
                            VStack(alignment: .leading) {
                                Text(skill.name)
                                    .font(.subheadline.weight(.medium))
                                Text(skill.content.prefix(50) + "...")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }
                        }
                    }
                }
            }
            .listStyle(.plain)
        }
    }

    private func selectSkill(_ skill: Skill) {
        if let lastSlashIndex = text.lastIndex(of: "/") {
            let prefix = text[..<lastSlashIndex]
            text = String(prefix) + "[Skill: \(skill.name)] "
        }
        showPicker = false
    }
}

extension View {
    func skillPicker(text: Binding<String>) -> some View {
        self.modifier(SkillPickerModifier(text: text))
    }
}
