import SwiftUI
#if canImport(UniformTypeIdentifiers)
import UniformTypeIdentifiers
#endif

struct SkillsView: View {
    @StateObject private var skillsManager = AIService.SkillsManager.shared
    @State private var showAddSkill = false
    @State private var showFileImporter = false

    var body: some View {
        List {
            if skillsManager.skills.isEmpty {
                ContentUnavailableView(
                    "No Skills Uploaded",
                    systemImage: "bolt.square",
                    description: Text("Upload .md files or create new skills to enhance AI capabilities.")
                )
            } else {
                ForEach($skillsManager.skills) { $skill in
                    NavigationLink(destination: SkillsDetailView(skill: $skill)) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(skill.name)
                                    .font(.headline)
                                HStack(spacing: 8) {
                                    Text(skill.category)
                                        .font(.caption2.bold())
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.blue.opacity(0.1), in: Capsule())
                                    Text("v\(skill.version)")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                    Text(skill.createdAt.formatted(date: .abbreviated, time: .omitted))
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                            Spacer()
                            Toggle("", isOn: $skill.isActive)
                                .labelsHidden()
                                .onChange(of: skill.isActive) { _, _ in
                                    skillsManager.updateSkill(skill)
                                }
                        }
                    }
                }
                .onDelete { indexSet in
                    indexSet.forEach { index in
                        skillsManager.deleteSkill(skillsManager.skills[index])
                    }
                }
            }
        }
        .navigationTitle("AI Skills")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        showAddSkill = true
                    } label: {
                        Label("New Skill", systemImage: "plus")
                    }
                    Button {
                        showFileImporter = true
                    } label: {
                        Label("Import .md File", systemImage: "doc.badge.plus")
                    }
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showAddSkill) {
            AddSkillView()
        }
        .fileImporter(
            isPresented: $showFileImporter,
            allowedContentTypes: [UTType.plainText, UTType(filenameExtension: "md")!],
            allowsMultipleSelection: true
        ) { result in
            switch result {
            case .success(let urls):
                urls.forEach { url in
                    let accessing = url.startAccessingSecurityScopedResource()
                    defer { if accessing { url.stopAccessingSecurityScopedResource() } }
                    try? skillsManager.importSkill(from: url)
                }
            case .failure(let error):
                print("Import failed: \(error.localizedDescription)")
            }
        }
    }
}
