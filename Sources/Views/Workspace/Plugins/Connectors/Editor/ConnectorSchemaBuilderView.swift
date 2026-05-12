

import SwiftUI

struct ConnectorSchemaBuilderView: View {
    @State var connector: ConnectorDefinition
    @StateObject private var manager = ConnectorManager.shared

    @State private var jsonSchema: String
    @State private var mappings: [MappingEntry]
    @State private var showingValidation = false
    @State private var validationErrors: [String] = []
    @State private var showingSaveConfirmation = false
    @State private var selectedTab = 0
    @State private var showingImportSheet = false
    @State private var importJSON = ""

    struct MappingEntry: Identifiable, Sendable {
        let id = UUID()
        var source: String; var target: String; var transformType: TransformType = .direct
        enum TransformType: String, CaseIterable, Sendable { case direct = "Direct", uppercase = "Uppercase", lowercase = "Lowercase", dateFormat = "Date Format", jsonPath = "JSON Path" }
    }

    init(connector: ConnectorDefinition) {
        self.connector = connector
        _jsonSchema = State(initialValue: connector.schema.jsonSchema)
        let initialMappings = connector.schema.mappings.map { MappingEntry(source: $0.key, target: $0.value) }
        _mappings = State(initialValue: initialMappings.isEmpty ? [MappingEntry(source: "", target: "")] : initialMappings)
    }

    var body: some View {
        Form {
            Section {
                HStack(spacing: 0) {
                    DetailMetricPill(label: "Mappings", value: "\(mappings.filter { !$0.source.isEmpty }.count)", color: .blue)
                    DetailMetricPill(label: "Size", value: "\(jsonSchema.count)", color: .purple)
                    DetailMetricPill(label: "Transforms", value: "\(mappings.filter { $0.transformType != .direct }.count)", color: .orange)
                }
                .padding(.vertical, 8)
            }
            .listRowBackground(Color.clear).listRowInsets(EdgeInsets())

            Picker("View", selection: $selectedTab) { Text("Schema").tag(0); Text("Mappings").tag(1); Text("Preview").tag(2) }
                .pickerStyle(.segmented).listRowBackground(Color.clear)

            switch selectedTab {
            case 0: SchemaEditorSection(jsonSchema: $jsonSchema, errors: validationErrors, onFormat: formatJSON)
            case 1: MappingsEditorSection(mappings: $mappings)
            case 2: PreviewSection(jsonSchema: jsonSchema, mappings: mappings)
            default: EmptyView()
            }

            Section {
                Button("Save Schema & Mappings") { saveSchema(); showingSaveConfirmation = true }.frame(maxWidth: .infinity).bold().buttonStyle(.borderedProminent)
                Button("Validate Configuration") { validateSchema() }.frame(maxWidth: .infinity)
            }
            .listRowBackground(Color.clear)
        }
        .navigationTitle("Schema Builder").navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button { showingImportSheet = true } label: { Label("Import", systemImage: "square.and.arrow.down") }
                    Button { UIPasteboard.general.string = jsonSchema } label: { Label("Copy", systemImage: "doc.on.doc") }
                    Divider(); Button(role: .destructive) { resetToDefault() } label: { Label("Reset", systemImage: "arrow.counterclockwise") }
                } label: { Image(systemName: "ellipsis.circle") }
            }
        }
        .sheet(isPresented: $showingImportSheet) { ImportSchemaSheet(importJSON: $importJSON) { jsonSchema = importJSON; showingImportSheet = false }.presentationDetents([.medium, .large]) }
        .alert("Saved", isPresented: $showingSaveConfirmation) { Button("OK") {} } message: { Text("Schema definitions have been updated.") }
    }

    private func formatJSON() {
        guard let data = jsonSchema.data(using: .utf8), let json = try? JSONSerialization.jsonObject(with: data), let formatted = try? JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted, .sortedKeys]), let res = String(data: formatted, encoding: .utf8) else { return }
        jsonSchema = res
    }
    private func resetToDefault() { jsonSchema = "{}"; mappings = [MappingEntry(source: "", target: "")] }
    private func validateSchema() { /* Logic preserved from original */ validationErrors = jsonSchema.isEmpty ? ["Schema is empty."] : [] }
    private func saveSchema() { var dict: [String: String] = [:]; mappings.forEach { if !$0.source.isEmpty { dict[$0.source] = $0.target } }; connector.schema = ConnectorSchema(mappings: dict, jsonSchema: jsonSchema); manager.updateConnector(connector) }
}

// MARK: - Private Sections

private struct SchemaEditorSection: View {
    @Binding var jsonSchema: String; let errors: [String]; let onFormat: () -> Void
    var body: some View {
        Section("JSON Response Schema") {
            VStack(alignment: .leading, spacing: 8) {
                TextEditor(text: $jsonSchema).font(.system(.caption2, design: .monospaced)).frame(minHeight: 200).padding(4).background(Color.primary.opacity(0.03), in: RoundedRectangle(cornerRadius: 8))
                HStack {
                    Button(action: onFormat) { Label("Format JSON", systemImage: "text.alignleft").font(.caption2) }.buttonStyle(.bordered).controlSize(.mini)
                    Spacer(); Text("\(jsonSchema.count) characters").font(.system(size: 8)).foregroundStyle(.tertiary)
                }
            }
        }
        if !errors.isEmpty { Section("Validation Issues") { ForEach(errors, id: \.self) { Label($0, systemImage: "exclamationmark.triangle.fill").font(.caption).foregroundStyle(.orange) } } }
        Section("Templates") {
            Button("REST API Standard") { jsonSchema = "{\n  \"type\": \"object\",\n  \"properties\": {\n    \"id\": { \"type\": \"string\" },\n    \"name\": { \"type\": \"string\" }\n  }\n}" }.font(.caption)
            Button("Paginated Results") { jsonSchema = "{\n  \"type\": \"object\",\n  \"properties\": {\n    \"results\": { \"type\": \"array\" },\n    \"total\": { \"type\": \"integer\" }\n  }\n}" }.font(.caption)
        }
    }
}

private struct MappingsEditorSection: View {
    @Binding var mappings: [ConnectorSchemaBuilderView.MappingEntry]
    var body: some View {
        Section("Data Mapping") {
            ForEach($mappings) { $entry in
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        TextField("API Source", text: $entry.source).font(.caption.monospaced())
                        Image(systemName: "arrow.right").font(.system(size: 8)).foregroundStyle(.tertiary)
                        TextField("Model Target", text: $entry.target).font(.caption.monospaced())
                    }
                    Picker("Transform", selection: $entry.transformType) { ForEach(ConnectorSchemaBuilderView.MappingEntry.TransformType.allCases, id: \.self) { Text($0.rawValue).tag($0) } }.pickerStyle(.menu).controlSize(.mini).labelsHidden()
                }
                .padding(.vertical, 2)
            }.onDelete { mappings.remove(atOffsets: $0) }
            Button { mappings.append(.init(source: "", target: "")) } label: { Label("Add Mapping", systemImage: "plus.circle.fill").font(.subheadline.bold()) }
        }
    }
}

private struct PreviewSection: View {
    let jsonSchema: String; let mappings: [ConnectorSchemaBuilderView.MappingEntry]
    var body: some View {
        Section("Schema Preview") {
            Text(jsonSchema).font(.system(size: 9, design: .monospaced)).padding(8).frame(maxWidth: .infinity, alignment: .leading).background(Color.primary.opacity(0.03), in: RoundedRectangle(cornerRadius: 8))
        }
        Section("Active Mappings") {
            let active = mappings.filter { !$0.source.isEmpty }
            if active.isEmpty { Text("No active mappings.").font(.caption).foregroundStyle(.secondary) }
            else {
                ForEach(active) { entry in
                    HStack {
                        Text(entry.source).font(.caption2.monospaced()).foregroundStyle(.blue)
                        Image(systemName: "arrow.right").font(.system(size: 8)).foregroundStyle(.tertiary)
                        Text(entry.target).font(.caption2.monospaced()).foregroundStyle(.green)
                        if entry.transformType != .direct { Spacer(); Text(entry.transformType.rawValue.uppercased()).font(.system(size: 7, weight: .black)).padding(.horizontal, 4).padding(.vertical, 2).background(Color.orange.opacity(0.1), in: Capsule()).foregroundStyle(.orange) }
                    }
                }
            }
        }
    }
}

private struct ImportSchemaSheet: View {
    @Binding var importJSON: String; let onImport: () -> Void; @Environment(\.dismiss) var dismiss
    var body: some View {
        NavigationStack {
            Form {
                Section("Paste JSON Schema") { TextEditor(text: $importJSON).font(.system(.caption2, design: .monospaced)).frame(minHeight: 200) }
                Section { Button("Import Schema") { onImport() }.frame(maxWidth: .infinity).bold().buttonStyle(.borderedProminent).disabled(importJSON.isEmpty) }.listRowBackground(Color.clear)
            }
            .navigationTitle("Import").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarLeading) { Button("Cancel") { dismiss() } } }
        }
    }
}

private struct DetailMetricPill: View {
    let label: String; let value: String; let color: Color
    var body: some View { VStack(spacing: 4) { Text(value).font(.headline).foregroundStyle(color); Text(label).font(.caption2.bold()).foregroundStyle(.secondary) }.frame(maxWidth: .infinity) }
}
