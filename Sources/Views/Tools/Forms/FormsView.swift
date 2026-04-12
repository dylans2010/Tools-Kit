import SwiftUI
import UniformTypeIdentifiers

struct FormsView: View {
    @StateObject private var backend = FormsBackend()
    @State private var showingCreate = false
    @State private var showingTemplates = false
    @State private var showingImport = false

    var body: some View {
        ToolDetailView(tool: FormsTool()) {
            VStack(spacing: 16) {
                HStack {
                    Button("Create Form") { showingCreate = true }
                        .buttonStyle(.borderedProminent)
                    Button("Templates") { showingTemplates = true }
                        .buttonStyle(.bordered)
                    Button("Import .form") { showingImport = true }
                        .buttonStyle(.bordered)
                }

                ToolInputSection("Your Forms") {
                    if backend.forms.isEmpty {
                        ContentUnavailableView("No Forms", systemImage: "list.bullet.rectangle", description: Text("Create or import a form to start."))
                            .padding()
                    } else {
                        ForEach(backend.forms) { form in
                            NavigationLink(destination: EditFormView(backend: backend, form: form)) {
                                VStack(alignment: .leading) {
                                    Text(form.name).font(.headline)
                                    Text(form.description).font(.subheadline).foregroundColor(.secondary)
                                }
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                            if form.id != backend.forms.last?.id { Divider() }
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showingCreate) {
            NavigationStack { CreateFormView(backend: backend) }
        }
        .sheet(isPresented: $showingTemplates) {
            NavigationStack { FormTemplatesView(backend: backend) }
        }
        .sheet(isPresented: $showingImport) {
            ImportFormView(backend: backend)
        }
    }
}

struct FormsTool: Tool {
    let name = "Forms"
    let icon = "list.bullet.rectangle.portrait"
    let category = ToolCategory.utility
    let complexity = ToolComplexity.advanced
    let description = "Build, style, import/export, and review secure .form files"
    let requiresAPI = false
    var view: AnyView { AnyView(FormsView()) }
}
