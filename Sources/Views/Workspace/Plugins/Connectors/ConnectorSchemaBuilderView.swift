import SwiftUI

struct ConnectorSchemaBuilderView: View {
    @State var connector: ConnectorDefinition
    @StateObject private var manager = ConnectorManager.shared

    @State private var jsonSchema: String
    @State private var mappings: [MappingEntry]
    @State private var showingValidation = false
    @State private var validationErrors: [String] = []
    @State private var showingSaveConfirmation = false
    @State private var showingPreview = false
    @State private var selectedTab = 0
    @State private var transformationRule = ""
    @State private var showingImportSheet = false
    @State private var importJSON = ""

    struct MappingEntry: Identifiable {
        let id = UUID()
        var source: String
        var target: String
        var transformType: TransformType = .direct

        enum TransformType: String, CaseIterable {
            case direct = "Direct"
            case uppercase = "Uppercase"
            case lowercase = "Lowercase"
            case dateFormat = "Date Format"
            case jsonPath = "JSON Path"
        }
    }

    init(connector: ConnectorDefinition) {
        self.connector = connector
        _jsonSchema = State(initialValue: connector.schema.jsonSchema)

        let initialMappings = connector.schema.mappings.map { MappingEntry(source: $0.key, target: $0.value) }
        _mappings = State(initialValue: initialMappings.isEmpty ? [MappingEntry(source: "", target: "")] : initialMappings)
    }

    var body: some View {
        Form {
            // MARK: - Schema Stats
            Section {
                HStack(spacing: 16) {
                    schemaStat(label: "Mappings", value: "\(mappings.filter { !$0.source.isEmpty }.count)", color: .blue)
                    schemaStat(label: "Schema Size", value: "\(jsonSchema.count) chars", color: .purple)
                    schemaStat(label: "Transforms", value: "\(mappings.filter { $0.transformType != .direct }.count)", color: .orange)
                }
            }

            // MARK: - Tab Selector
            Picker("View", selection: $selectedTab) {
                Text("Schema").tag(0)
                Text("Mappings").tag(1)
                Text("Preview").tag(2)
            }
            .pickerStyle(.segmented)
            .listRowBackground(Color.clear)

            switch selectedTab {
            case 0: schemaEditor
            case 1: mappingsEditor
            case 2: previewSection
            default: schemaEditor
            }

            // MARK: - Actions
            Section {
                Button {
                    validateSchema()
                } label: {
                    Label("Validate Schema", systemImage: "checkmark.shield")
                }

                Button("Save Schema & Mappings") {
                    saveSchema()
                    showingSaveConfirmation = true
                }
                .frame(maxWidth: .infinity)
                .bold()
            }
        }
        .navigationTitle("Schema Builder")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button {
                        showingImportSheet = true
                    } label: {
                        Label("Import Schema", systemImage: "square.and.arrow.down")
                    }
                    Button {
                        UIPasteboard.general.string = jsonSchema
                    } label: {
                        Label("Copy Schema", systemImage: "doc.on.doc")
                    }
                    Button {
                        resetToDefault()
                    } label: {
                        Label("Reset to Default", systemImage: "arrow.counterclockwise")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingImportSheet) {
            importSchemaSheet
        }
        .alert("Schema Saved", isPresented: $showingSaveConfirmation) {
            Button("OK") {}
        } message: {
            Text("Schema and \(mappings.filter { !$0.source.isEmpty && !$0.target.isEmpty }.count) mapping(s) saved successfully.")
        }
    }

    // MARK: - Schema Editor

    private var schemaEditor: some View {
        Group {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Define the expected API response structure in JSON format.")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    TextEditor(text: $jsonSchema)
                        .font(.system(.caption, design: .monospaced))
                        .frame(minHeight: 200)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.2)))

                    HStack {
                        Button {
                            formatJSON()
                        } label: {
                            Label("Format JSON", systemImage: "text.alignleft")
                                .font(.caption)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)

                        Spacer()

                        Text("\(jsonSchema.count) Characters")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 8)
            } header: {
                Text("JSON Response Schema")
            }

            // MARK: - Validation Results
            if !validationErrors.isEmpty {
                Section {
                    ForEach(validationErrors, id: \.self) { error in
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                                .font(.caption)
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                    }
                } header: {
                    Text("Validation Issues")
                }
            }

            // MARK: - Quick Templates
            Section {
                Button {
                    jsonSchema = "{\n  \"type\": \"object\",\n  \"properties\": {\n    \"id\": { \"type\": \"string\" },\n    \"name\": { \"type\": \"string\" },\n    \"data\": { \"type\": \"array\", \"items\": { \"type\": \"object\" } }\n  }\n}"
                } label: {
                    Label("REST API Response", systemImage: "doc.text")
                        .font(.caption)
                }

                Button {
                    jsonSchema = "{\n  \"type\": \"object\",\n  \"properties\": {\n    \"results\": { \"type\": \"array\" },\n    \"total\": { \"type\": \"integer\" },\n    \"page\": { \"type\": \"integer\" },\n    \"per_page\": { \"type\": \"integer\" }\n  }\n}"
                } label: {
                    Label("Paginated Response", systemImage: "doc.text")
                        .font(.caption)
                }
            } header: {
                Text("Schema Templates")
            }
        }
    }

    // MARK: - Mappings Editor

    private var mappingsEditor: some View {
        Group {
            Section {
                Text("Map API response fields to internal Workspace models. Use dot notation for nested fields (e.g. data.user.name).")
                    .font(.caption)
                    .foregroundColor(.secondary)

                ForEach($mappings) { $entry in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            TextField("API Field (Source)", text: $entry.source)
                                .font(.system(.caption, design: .monospaced))
                            Image(systemName: "arrow.right")
                                .foregroundColor(.secondary)
                                .font(.caption)
                            TextField("Workspace Model (Target)", text: $entry.target)
                                .font(.system(.caption, design: .monospaced))
                        }

                        Picker("Transform", selection: $entry.transformType) {
                            ForEach(MappingEntry.TransformType.allCases, id: \.self) { type in
                                Text(type.rawValue).tag(type)
                            }
                        }
                        .pickerStyle(.menu)
                        .font(.caption2)
                    }
                    .padding(.vertical, 2)
                }
                .onDelete { indices in
                    mappings.remove(atOffsets: indices)
                }

                Button {
                    mappings.append(MappingEntry(source: "", target: ""))
                } label: {
                    Label("Add Mapping", systemImage: "plus.circle")
                }
            } header: {
                Text("Data Mapping")
            }
        }
    }

    // MARK: - Preview

    private var previewSection: some View {
        Group {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Current Schema")
                        .font(.caption.bold())
                        .foregroundColor(.secondary)

                    Text(jsonSchema)
                        .font(.system(.caption2, design: .monospaced))
                        .padding(8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.systemGroupedBackground))
                        .cornerRadius(8)
                }
            } header: {
                Text("Schema Preview")
            }

            Section {
                ForEach(mappings.filter { !$0.source.isEmpty && !$0.target.isEmpty }) { entry in
                    HStack {
                        Text(entry.source)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.blue)

                        Image(systemName: "arrow.right")
                            .font(.caption2)
                            .foregroundColor(.secondary)

                        Text(entry.target)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.green)

                        if entry.transformType != .direct {
                            Spacer()
                            Text(entry.transformType.rawValue)
                                .font(.system(size: 9, weight: .bold))
                                .padding(.horizontal, 4)
                                .padding(.vertical, 2)
                                .background(Color.orange.opacity(0.15))
                                .foregroundColor(.orange)
                                .clipShape(RoundedRectangle(cornerRadius: 3))
                        }
                    }
                }

                if mappings.filter({ !$0.source.isEmpty && !$0.target.isEmpty }).isEmpty {
                    Text("No Active Mappings Defined")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } header: {
                Text("Active Mappings (\(mappings.filter { !$0.source.isEmpty && !$0.target.isEmpty }.count))")
            }
        }
    }

    // MARK: - Import Sheet

    private var importSchemaSheet: some View {
        NavigationView {
            Form {
                Section {
                    TextEditor(text: $importJSON)
                        .font(.system(.caption, design: .monospaced))
                        .frame(minHeight: 200)
                } header: {
                    Text("Paste JSON Schema")
                }

                Section {
                    Button("Import") {
                        jsonSchema = importJSON
                        showingImportSheet = false
                    }
                    .disabled(importJSON.isEmpty)
                }
            }
            .navigationTitle("Import Schema")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showingImportSheet = false }
                }
            }
        }
    }

    // MARK: - Helpers

    private func schemaStat(label: String, value: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.title3.bold())
                .foregroundColor(color)
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func validateSchema() {
        validationErrors = []

        if jsonSchema.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            validationErrors.append("Schema is empty.")
            return
        }

        guard let data = jsonSchema.data(using: .utf8) else {
            validationErrors.append("Schema contains invalid characters.")
            return
        }

        do {
            _ = try JSONSerialization.jsonObject(with: data)
        } catch {
            validationErrors.append("Invalid JSON: \(error.localizedDescription)")
        }

        for (index, mapping) in mappings.enumerated() {
            if !mapping.source.isEmpty && mapping.target.isEmpty {
                validationErrors.append("Mapping #\(index + 1): Missing target field.")
            }
            if mapping.source.isEmpty && !mapping.target.isEmpty {
                validationErrors.append("Mapping #\(index + 1): Missing source field.")
            }
        }
    }

    private func formatJSON() {
        guard let data = jsonSchema.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data),
              let formatted = try? JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted, .sortedKeys]),
              let result = String(data: formatted, encoding: .utf8) else { return }
        jsonSchema = result
    }

    private func resetToDefault() {
        jsonSchema = "{}"
        mappings = [MappingEntry(source: "", target: "")]
    }

    private func saveSchema() {
        var mappingDict: [String: String] = [:]
        for entry in mappings where !entry.source.isEmpty && !entry.target.isEmpty {
            mappingDict[entry.source] = entry.target
        }

        connector.schema = ConnectorSchema(mappings: mappingDict, jsonSchema: jsonSchema)
        connector.updatedAt = Date()
        manager.updateConnector(connector)
    }
}
