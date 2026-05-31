import SwiftUI

struct ScopeTemplatesView: View {
    @ObservedObject var scopeService = DeveloperScopeService.shared
    @State private var showingAddTemplate = false
    @State private var templates: [ScopeTemplate] = [
        ScopeTemplate(name: "Basic Identity", scopeIdentifiers: ["user.read", "user.email"]),
        ScopeTemplate(name: "Data Analytics", scopeIdentifiers: ["analytics.read", "logs.view"]),
        ScopeTemplate(name: "System Management", scopeIdentifiers: ["system.write", "network.admin"])
    ]

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
    }
}
