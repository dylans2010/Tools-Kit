import SwiftUI

struct ScopeTemplatesView: View {
    @ObservedObject var scopeService = DeveloperScopeService.shared
    @State private var showingAddTemplate = false
    @State private var newTemplateName = ""

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
            Section("Reusable Permission Sets") {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "rectangle.stack.badge.plus").foregroundStyle(.blue)
                        Text("Policy Templates").font(.subheadline.bold())
                    }
                    Text("Standardize your application's requested scopes using pre-defined templates for common use cases.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }

            Section("Active Templates") {
                let templates = DeveloperPersistentStore.shared.scopeTemplates
                if templates.isEmpty {
                    EmptyStateView(icon: "square.stack", title: "No Templates", message: "Create a template to quickly apply specific sets of permissions to your projects.")
                } else {
                    ForEach(templates) { template in
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text(template.name).font(.subheadline.bold())
                                Spacer()
                                Text("\(template.scopeIdentifiers.count) scopes").font(.system(size: 8, weight: .black)).foregroundStyle(.secondary)
                            }

                            FlowLayout(template.scopeIdentifiers, spacing: 4) { scope in
                                Text(scope).font(.system(size: 8, design: .monospaced)).padding(.horizontal, 6).padding(.vertical, 2).background(Color.primary.opacity(0.05), in: RoundedRectangle(cornerRadius: 4))
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }

            Section {
                Button { showingAddTemplate = true } label: {
                    Label("Define New Template", systemImage: "plus.circle.fill").font(.subheadline.bold())
                }
            }
            }
            .padding()
        }
        .navigationTitle("Scope Templates")
        .alert("New Template", isPresented: $showingAddTemplate) {
            TextField("Template Name", text: $newTemplateName)
            Button("Cancel", role: .cancel) { }
            Button("Create") {
                var current = DeveloperPersistentStore.shared.scopeTemplates
                current.append(ScopeTemplate(name: newTemplateName, scopeIdentifiers: ["identity.read"]))
                DeveloperPersistentStore.shared.saveScopeTemplates(current)
                newTemplateName = ""
            }
        } message: {
            Text("Enter a name for the new permission set template.")
        }
    }
}
