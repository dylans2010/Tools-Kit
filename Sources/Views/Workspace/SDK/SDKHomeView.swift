import SwiftUI

struct SDKHomeView: View {
    @StateObject private var projectManager = SDKProjectManager.shared
    @State private var searchText = ""
    @State private var statusFilter: SDKProject.ProjectStatus?
    @State private var showingCreateSheet = false
    @State private var newProjectName = ""

    private var projects: [SDKProject] {
        projectManager.filteredProjects(search: searchText, status: statusFilter)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                SDKSectionHeader(
                    title: "SDK Projects",
                    subtext: "Manage and build your WorkspaceSDK applications.",
                    isCentered: false
                )
                .padding(.horizontal)

                if projects.isEmpty {
                    SDKModernCard {
                        ContentUnavailableView(
                            "No Projects",
                            systemImage: "folder.badge.plus",
                            description: Text("Create a project in App Builder to get started.")
                        )
                    }
                    .padding(.horizontal)
                } else {
                    LazyVStack(spacing: 12) {
                        ForEach(projects) { project in
                            NavigationLink {
                                SDKBuildView()
                                    .onAppear { projectManager.loadProject(id: project.id) }
                            } label: {
                                projectCard(project)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)
                }

                SDKSectionHeader(title: "Quick Access", subtext: "Jump to core SDK tools.")
                    .padding(.horizontal)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    quickAccessLink(destination: SDKWorkspaceContainerView(), title: "IDE Workspace", icon: "square.split.2x2.fill", color: .indigo)
                    quickAccessLink(destination: SDKDeveloperGuideView(), title: "Dev Guide", icon: "book.closed.fill", color: .blue)
                    quickAccessLink(destination: SDKBuildView(), title: "App Builder", icon: "hammer.fill", color: .orange)
                    quickAccessLink(destination: SDKInternalView(), title: "SDK Internal", icon: "terminal.fill", color: .gray)
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("WorkspaceSDK")
        .searchable(text: $searchText, prompt: "Search projects")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingCreateSheet = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button("All") { statusFilter = nil }
                    Button("Active") { statusFilter = .active }
                    Button("Draft") { statusFilter = .draft }
                } label: {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                }
            }
        }
        .sheet(isPresented: $showingCreateSheet) {
            NavigationStack {
                createProjectForm
            }
            .presentationDetents([.medium])
        }
    }

    private func projectCard(_ project: SDKProject) -> some View {
        SDKModernCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(project.name)
                        .font(.headline)
                    Spacer()
                    SDKStatusPill(
                        status: project.status == .active ? .success : .warning,
                        text: project.status.rawValue.capitalized
                    )
                }

                Text(project.description.isEmpty ? "No description provided for this project." : project.description)
                    .sdkSubtext()
                    .lineLimit(2)

                HStack {
                    Label("\(project.enabledScopes.count) Scopes", systemImage: "lock.shield")
                    Spacer()
                    Text("Updated \(project.updatedAt.formatted(date: .abbreviated, time: .shortened))")
                }
                .font(.caption2)
                .foregroundStyle(.tertiary)
            }
        }
    }

    private func quickAccessLink<D: View>(destination: D, title: String, icon: String, color: Color) -> some View {
        NavigationLink(destination: destination) {
            SDKModernCard {
                VStack(spacing: 8) {
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundStyle(color)
                    Text(title)
                        .font(.caption.bold())
                }
                .frame(maxWidth: .infinity)
            }
        }
        .buttonStyle(.plain)
    }

    private var createProjectForm: some View {
        Form {
            Section {
                TextField("Project Name", text: $newProjectName)
            } header: {
                Text("New Project")
            } footer: {
                Text("Enter a unique name for your SDK project.")
            }

            Button {
                _ = projectManager.createProject(name: newProjectName, status: .draft)
                newProjectName = ""
                showingCreateSheet = false
            } label: {
                Text("Create Project")
                    .frame(maxWidth: .infinity)
            }
            .disabled(newProjectName.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        .navigationTitle("Create Project")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    showingCreateSheet = false
                    newProjectName = ""
                }
            }
        }
    }
}
