import SwiftUI

struct ScopeTemplatesView: View {
    @ObservedObject var scopeService = DeveloperScopeService.shared
    @State private var showingAddTemplate = false
    @State private var templates: [ScopeTemplate] = [
        ScopeTemplate(name: "Basic Identity", description: "Standard user profile and email access.", scopes: ["user.read", "user.email"]),
        ScopeTemplate(name: "Data Analytics", description: "Read-only access to usage telemetry and logs.", scopes: ["analytics.read", "logs.view"]),
        ScopeTemplate(name: "System Management", description: "Full administrative control over cloud resources.", scopes: ["system.write", "network.admin"])
    ]

    var body: some View {
        List {
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
                if templates.isEmpty {
                    EmptyStateView(icon: "square.stack", title: "No Templates", message: "Create a template to quickly apply specific sets of permissions to your projects.")
                } else {
                    ForEach(templates) { template in
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text(template.name).font(.subheadline.bold())
                                Spacer()
                                Text("\(template.scopes.count) scopes").font(.system(size: 8, weight: .black)).foregroundStyle(.secondary)
                            }

                            Text(template.description).font(.caption).foregroundStyle(.secondary)

                            FlowLayout(template.scopes, spacing: 4) { scope in
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
        .navigationTitle("Scope Templates")
    }
}
