import SwiftUI

struct SDKHomeView: View {
    @StateObject private var projectManager = SDKProjectManager.shared
    @State private var searchText = ""
    @State private var statusFilter: SDKProject.ProjectStatus?

    private var projects: [SDKProject] {
        projectManager.filteredProjects(search: searchText, status: statusFilter)
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(spacing: 20) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("SDK Control Plane").font(.title2.bold())
                                Text("ToolsKit v2.4.0 • Active Runtime").font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Circle()
                                .fill(Color.green)
                                .frame(width: 8, height: 8)
                                .overlay(Circle().stroke(Color.green.opacity(0.3), lineWidth: 4))
                        }

                        HStack(spacing: 12) {
                            SDKMetricCard(label: "Projects", value: "\(projects.count)", icon: "folder.fill", color: .blue)
                            SDKMetricCard(label: "Auth", value: "Valid", icon: "shield.checkered", color: .green)
                            SDKMetricCard(label: "Latency", value: "4ms", icon: "bolt.fill", color: .orange)
                        }
                    }
                    .padding(.vertical, 8)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                }

                Section {
                    NavigationLink(destination: SDKBuildView()) {
                        Label("SDK Build Pipeline", systemImage: "hammer.fill")
                            .font(.headline)
                            .foregroundStyle(.blue)
                    }
                }

                Section("Engineering Resources") {
                    NavigationLink(destination: SDKWorkspaceContainerView()) {
                        Label("IDE Workspace", systemImage: "macwindow.on.rectangle")
                    }
                    NavigationLink(destination: SDKDeveloperGuideView()) {
                        Label("Developer Documentation", systemImage: "book.closed.fill")
                    }
                    NavigationLink(destination: SignInView()) {
                        Label("Developer Identity", systemImage: "person.badge.key.fill")
                    }
                }

                Section("Project Index") {
                    if projects.isEmpty {
                        ContentUnavailableView(
                            "No Projects",
                            systemImage: "folder.badge.plus",
                            description: Text("Initialize an SDK project to start building.")
                        )
                    } else {
                        ForEach(projects) { project in
                            NavigationLink {
                                SDKBuildView()
                                    .onAppear { projectManager.loadProject(id: project.id) }
                            } label: {
                                SDKProjectRow(project: project)
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    projectManager.deleteProject(id: project.id)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                }

                Section {
                    NavigationLink(destination: SDKDebugView()) {
                        Label("Runtime Diagnostics", systemImage: "stethoscope")
                    }
                }
            }
            .navigationTitle("Platform SDK")
            .searchable(text: $searchText, prompt: "Search Projects")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Picker("Status", selection: $statusFilter) {
                            Text("All").tag(Optional<SDKProject.ProjectStatus>.none)
                            Text("Active").tag(Optional(SDKProject.ProjectStatus.active))
                            Text("Draft").tag(Optional(SDKProject.ProjectStatus.draft))
                        }
                        Divider()
                        Button {
                            _ = projectManager.createProject(name: "New SDK Project", status: .draft)
                        } label: {
                            Label("Create Project", systemImage: "plus")
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                }
            }
        }
    }
}
