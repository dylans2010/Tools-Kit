import SwiftUI

struct ConnectorDataMappingView: View {
    @State private var mappings: [ConnectorFieldMapping] = []
    @State private var showingCreateMapping = false
    @State private var sourceField = ""
    @State private var targetField = ""
    @State private var transformType: TransformType = .direct
    @State private var showingBatchImport = false
    @State private var batchJSON = ""
    @State private var validationResults: [MappingValidation] = []
    @State private var showingValidation = false
    @State private var searchText = ""
    @State private var sortOrder: MappingSortOrder = .source
    @State private var showingExport = false
    @State private var showingTestMapping = false
    @State private var testInput = ""
    @State private var testOutput = ""
    @State private var selectedMappingID: UUID?
    @State private var showingPresets = false
    @State private var defaultValue = ""
    @State private var isRequired = true
    @State private var showingChainBuilder = false
    @State private var chainSteps: [TransformChainStep] = []

    private var filteredMappings: [ConnectorFieldMapping] {
        var result = mappings
        if !searchText.isEmpty {
            result = result.filter {
                $0.sourceField.localizedCaseInsensitiveContains(searchText) ||
                $0.targetField.localizedCaseInsensitiveContains(searchText)
            }
        }
        switch sortOrder {
        case .source: result.sort { $0.sourceField < $1.sourceField }
        case .target: result.sort { $0.targetField < $1.targetField }
        case .transform: result.sort { $0.transform.rawValue < $1.transform.rawValue }
        }
        return result
    }

    var body: some View {
        List {
            overviewSection
            sortAndFilterSection
            mappingsSection
            transformTypesSection
            validationSection
            testMappingSection
            actionsSection
        }
        .navigationTitle("Data Mapping")
        .searchable(text: $searchText, prompt: "Search mappings")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button { showingCreateMapping = true } label: { Label("Add Mapping", systemImage: "plus") }
                    Button { showingBatchImport = true } label: { Label("Import Batch", systemImage: "square.and.arrow.down") }
                    Button { showingPresets = true } label: { Label("Mapping Presets", systemImage: "list.star") }
                    Button { showingChainBuilder = true } label: { Label("Transform Chain", systemImage: "link") }
                    Divider()
                    Button { showingExport = true } label: { Label("Export Mappings", systemImage: "square.and.arrow.up") }
                    Button(role: .destructive) { mappings.removeAll() } label: { Label("Clear All", systemImage: "trash") }
                } label: { Image(systemName: "ellipsis.circle") }
            }
        }
        .sheet(isPresented: $showingCreateMapping) {
            NavigationStack { createMappingSheet }
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingBatchImport) {
            NavigationStack { batchImportSheet }
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingValidation) {
            NavigationStack { validationResultsSheet }
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingExport) {
            NavigationStack { exportSheet }
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingPresets) {
            NavigationStack { presetsSheet }
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingChainBuilder) {
            NavigationStack { chainBuilderSheet }
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Overview Section

    private var overviewSection: some View {
        Section("Mapping Overview") {
            HStack(spacing: 16) {
                VStack(spacing: 2) {
                    Text("\(mappings.count)").font(.title3.bold()).foregroundStyle(.blue)
                    Text("Total").font(.caption2).foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                VStack(spacing: 2) {
                    Text("\(mappings.filter { $0.transform != .direct }.count)").font(.title3.bold()).foregroundStyle(.orange)
                    Text("Transforms").font(.caption2).foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                VStack(spacing: 2) {
                    Text("\(mappings.filter { $0.isRequired }.count)").font(.title3.bold()).foregroundStyle(.red)
                    Text("Required").font(.caption2).foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                VStack(spacing: 2) {
                    Text("\(mappings.filter { $0.defaultValue != nil }.count)").font(.title3.bold()).foregroundStyle(.green)
                    Text("Defaults").font(.caption2).foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: - Sort & Filter

    private var sortAndFilterSection: some View {
        Section {
            Picker("Sort By", selection: $sortOrder) {
                ForEach(MappingSortOrder.allCases, id: \.self) { order in
                    Text(order.rawValue.capitalized).tag(order)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    // MARK: - Mappings Section

    private var mappingsSection: some View {
        Section("Field Mappings") {
            if filteredMappings.isEmpty {
                ContentUnavailableView("No Mappings", systemImage: "arrow.left.arrow.right", description: Text("Create field mappings between connector data sources."))
            } else {
                ForEach(filteredMappings) { mapping in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(mapping.sourceField)
                                .font(.subheadline.monospaced())
                            Text("Source")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            if mapping.isRequired {
                                Text("Required")
                                    .font(.system(size: 7, weight: .bold))
                                    .foregroundStyle(.red)
                            }
                        }
                        Spacer()
                        VStack(spacing: 2) {
                            Image(systemName: "arrow.right")
                            Text(mapping.transform.rawValue)
                                .font(.caption2)
                                .foregroundStyle(.blue)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(mapping.targetField)
                                .font(.subheadline.monospaced())
                            Text("Target")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            if let def = mapping.defaultValue {
                                Text("Default: \(def)")
                                    .font(.system(size: 7))
                                    .foregroundStyle(.tertiary)
                            }
                        }
                    }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) { mappings.removeAll { $0.id == mapping.id } } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                    .swipeActions(edge: .leading, allowsFullSwipe: false) {
                        Button { duplicateMapping(mapping) } label: {
                            Label("Duplicate", systemImage: "doc.on.doc")
                        }
                        .tint(.blue)
                    }
                }
                .onMove { mappings.move(fromOffsets: $0, toOffset: $1) }
            }
        }
    }

    // MARK: - Transform Types

    private var transformTypesSection: some View {
        Section("Transform Types") {
            ForEach(TransformType.allCases, id: \.self) { type in
                HStack {
                    Image(systemName: type.icon)
                        .foregroundStyle(.blue)
                        .frame(width: 24)
                    VStack(alignment: .leading) {
                        Text(type.rawValue.capitalized)
                            .font(.subheadline)
                        Text(type.description)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text("\(mappings.filter { $0.transform == type }.count)")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.tertiary)
                }
            }
        }
    }

    // MARK: - Validation Section

    private var validationSection: some View {
        Section("Validation") {
            Button {
                validateMappings()
                showingValidation = true
            } label: {
                Label("Validate All Mappings", systemImage: "checkmark.shield")
            }
            if !validationResults.isEmpty {
                let errors = validationResults.filter { !$0.isValid }
                if errors.isEmpty {
                    Label("All mappings valid", systemImage: "checkmark.circle.fill")
                        .font(.caption).foregroundStyle(.green)
                } else {
                    Label("\(errors.count) issue(s) found", systemImage: "exclamationmark.triangle.fill")
                        .font(.caption).foregroundStyle(.orange)
                }
            }
        }
    }

    // MARK: - Test Mapping Section

    private var testMappingSection: some View {
        Section("Test Transform") {
            TextField("Test input value", text: $testInput)
                .font(.body.monospaced())
            Button("Run Transform") {
                testOutput = applyTransform(testInput, transform: transformType)
            }
            .disabled(testInput.isEmpty)
            if !testOutput.isEmpty {
                LabeledContent("Result") {
                    Text(testOutput)
                        .font(.body.monospaced())
                        .foregroundStyle(.blue)
                }
            }
        }
    }

    // MARK: - Actions

    private var actionsSection: some View {
        Section("Bulk Actions") {
            Button { reverseAllMappings() } label: {
                Label("Reverse All Directions", systemImage: "arrow.left.arrow.right")
            }
            .disabled(mappings.isEmpty)
            Button { deduplicateMappings() } label: {
                Label("Remove Duplicates", systemImage: "minus.diamond")
            }
            .disabled(mappings.isEmpty)
        }
    }

    // MARK: - Create Mapping Sheet

    private var createMappingSheet: some View {
        Form {
            Section("Source") {
                TextField("Source Field", text: $sourceField)
                    .autocorrectionDisabled()
            }
            Section("Target") {
                TextField("Target Field", text: $targetField)
                    .autocorrectionDisabled()
            }
            Section("Transform") {
                Picker("Type", selection: $transformType) {
                    ForEach(TransformType.allCases, id: \.self) { type in
                        Text(type.rawValue.capitalized).tag(type)
                    }
                }
            }
            Section("Options") {
                Toggle("Required", isOn: $isRequired)
                TextField("Default Value (optional)", text: $defaultValue)
            }
        }
        .navigationTitle("New Mapping")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) { Button("Cancel") { showingCreateMapping = false } }
            ToolbarItem(placement: .confirmationAction) {
                Button("Add") {
                    mappings.append(ConnectorFieldMapping(
                        sourceField: sourceField,
                        targetField: targetField,
                        transform: transformType,
                        isRequired: isRequired,
                        defaultValue: defaultValue.isEmpty ? nil : defaultValue
                    ))
                    sourceField = ""
                    targetField = ""
                    defaultValue = ""
                    isRequired = true
                    showingCreateMapping = false
                }
                .disabled(sourceField.isEmpty || targetField.isEmpty)
            }
        }
    }

    // MARK: - Batch Import Sheet

    private var batchImportSheet: some View {
        Form {
            Section("JSON Input") {
                TextEditor(text: $batchJSON)
                    .font(.caption.monospaced())
                    .frame(minHeight: 200)
            }
            Section {
                Text("Format: [{\"source\": \"field_a\", \"target\": \"field_b\", \"transform\": \"direct\"}]")
                    .font(.caption2).foregroundStyle(.secondary)
            }
            Section {
                Button("Import Mappings") {
                    importBatchMappings()
                    showingBatchImport = false
                }
                .frame(maxWidth: .infinity).bold()
                .buttonStyle(.borderedProminent)
                .disabled(batchJSON.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .listRowBackground(Color.clear)
        }
        .navigationTitle("Batch Import")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Validation Results Sheet

    private var validationResultsSheet: some View {
        List {
            ForEach(validationResults) { result in
                HStack {
                    Image(systemName: result.isValid ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundStyle(result.isValid ? .green : .red)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(result.sourceField) → \(result.targetField)")
                            .font(.subheadline.monospaced())
                        Text(result.message)
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle("Validation Results")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Export Sheet

    private var exportSheet: some View {
        Form {
            Section("Export Format") {
                Text(buildExportJSON())
                    .font(.caption.monospaced())
                    .textSelection(.enabled)
            }
            Section {
                Button("Copy to Clipboard") {
                    UIPasteboard.general.string = buildExportJSON()
                }
                .frame(maxWidth: .infinity).bold()
                .buttonStyle(.borderedProminent)
            }
            .listRowBackground(Color.clear)
        }
        .navigationTitle("Export Mappings")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Presets Sheet

    private var presetsSheet: some View {
        List {
            Section("Common Presets") {
                ForEach(MappingPreset.allPresets) { preset in
                    Button {
                        for m in preset.mappings {
                            mappings.append(m)
                        }
                        showingPresets = false
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(preset.name).font(.subheadline.bold())
                            Text(preset.description).font(.caption).foregroundStyle(.secondary)
                            Text("\(preset.mappings.count) mappings").font(.caption2).foregroundStyle(.tertiary)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .navigationTitle("Mapping Presets")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Chain Builder Sheet

    private var chainBuilderSheet: some View {
        Form {
            Section("Transform Chain") {
                if chainSteps.isEmpty {
                    Text("Add steps to build a transform chain").font(.caption).foregroundStyle(.secondary)
                } else {
                    ForEach(chainSteps) { step in
                        HStack {
                            Image(systemName: step.transform.icon)
                                .foregroundStyle(.blue)
                            Text(step.transform.rawValue.capitalized)
                                .font(.subheadline)
                        }
                    }
                    .onMove { chainSteps.move(fromOffsets: $0, toOffset: $1) }
                    .onDelete { chainSteps.remove(atOffsets: $0) }
                }
            }
            Section("Add Step") {
                ForEach(TransformType.allCases, id: \.self) { type in
                    Button {
                        chainSteps.append(TransformChainStep(transform: type))
                    } label: {
                        Label(type.rawValue.capitalized, systemImage: type.icon)
                    }
                }
            }
            if !chainSteps.isEmpty {
                Section("Preview") {
                    let result = chainSteps.reduce("sample_input") { current, step in
                        applyTransform(current, transform: step.transform)
                    }
                    LabeledContent("Input", value: "sample_input")
                    LabeledContent("Output") {
                        Text(result).font(.body.monospaced()).foregroundStyle(.blue)
                    }
                }
            }
        }
        .navigationTitle("Transform Chain")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Helpers

    private func duplicateMapping(_ mapping: ConnectorFieldMapping) {
        mappings.append(ConnectorFieldMapping(
            sourceField: mapping.sourceField,
            targetField: mapping.targetField + "_copy",
            transform: mapping.transform,
            isRequired: mapping.isRequired,
            defaultValue: mapping.defaultValue
        ))
    }

    private func reverseAllMappings() {
        mappings = mappings.map {
            ConnectorFieldMapping(
                sourceField: $0.targetField,
                targetField: $0.sourceField,
                transform: $0.transform,
                isRequired: $0.isRequired,
                defaultValue: $0.defaultValue
            )
        }
    }

    private func deduplicateMappings() {
        var seen: Set<String> = []
        mappings = mappings.filter { mapping in
            let key = "\(mapping.sourceField)->\(mapping.targetField)"
            if seen.contains(key) { return false }
            seen.insert(key)
            return true
        }
    }

    private func validateMappings() {
        validationResults = mappings.map { mapping in
            var issues: [String] = []
            if mapping.sourceField.isEmpty { issues.append("Empty source field") }
            if mapping.targetField.isEmpty { issues.append("Empty target field") }
            if mapping.sourceField == mapping.targetField && mapping.transform == .direct {
                issues.append("Identity mapping (source equals target with no transform)")
            }
            if mapping.sourceField.contains(" ") { issues.append("Source field contains spaces") }
            if mapping.targetField.contains(" ") { issues.append("Target field contains spaces") }
            return MappingValidation(
                sourceField: mapping.sourceField,
                targetField: mapping.targetField,
                isValid: issues.isEmpty,
                message: issues.isEmpty ? "Valid" : issues.joined(separator: "; ")
            )
        }
    }

    private func applyTransform(_ input: String, transform: TransformType) -> String {
        switch transform {
        case .direct: return input
        case .uppercase: return input.uppercased()
        case .lowercase: return input.lowercased()
        case .trim: return input.trimmingCharacters(in: .whitespacesAndNewlines)
        case .dateFormat: return input
        case .jsonParse: return input
        case .numberFormat:
            if let num = Double(input) { return String(format: "%.2f", num) }
            return input
        case .base64Encode:
            return Data(input.utf8).base64EncodedString()
        case .base64Decode:
            if let data = Data(base64Encoded: input), let str = String(data: data, encoding: .utf8) { return str }
            return input
        case .hashMD5:
            return "md5(\(input))"
        case .snakeCase:
            return input.replacingOccurrences(of: " ", with: "_").lowercased()
        case .camelCase:
            let words = input.split(separator: " ").map { String($0) }
            guard let first = words.first else { return input }
            return first.lowercased() + words.dropFirst().map { $0.capitalized }.joined()
        }
    }

    private func importBatchMappings() {
        guard let data = batchJSON.data(using: .utf8),
              let items = try? JSONSerialization.jsonObject(with: data) as? [[String: String]] else { return }
        for item in items {
            if let source = item["source"], let target = item["target"] {
                let transform = TransformType(rawValue: item["transform"] ?? "direct") ?? .direct
                mappings.append(ConnectorFieldMapping(sourceField: source, targetField: target, transform: transform, isRequired: true, defaultValue: nil))
            }
        }
        batchJSON = ""
    }

    private func buildExportJSON() -> String {
        let items = mappings.map { m -> [String: String] in
            var dict: [String: String] = ["source": m.sourceField, "target": m.targetField, "transform": m.transform.rawValue]
            if let def = m.defaultValue { dict["default"] = def }
            dict["required"] = m.isRequired ? "true" : "false"
            return dict
        }
        guard let data = try? JSONSerialization.data(withJSONObject: items, options: [.prettyPrinted, .sortedKeys]),
              let json = String(data: data, encoding: .utf8) else { return "[]" }
        return json
    }
}

// MARK: - Private Models

private struct ConnectorFieldMapping: Identifiable {
    let id = UUID()
    let sourceField: String
    let targetField: String
    let transform: TransformType
    let isRequired: Bool
    let defaultValue: String?
}

private enum TransformType: String, CaseIterable {
    case direct, uppercase, lowercase, trim, dateFormat, jsonParse, numberFormat
    case base64Encode, base64Decode, hashMD5, snakeCase, camelCase

    var icon: String {
        switch self {
        case .direct: return "equal"
        case .uppercase: return "textformat.size.larger"
        case .lowercase: return "textformat.size.smaller"
        case .trim: return "scissors"
        case .dateFormat: return "calendar"
        case .jsonParse: return "curlybraces"
        case .numberFormat: return "number"
        case .base64Encode: return "lock"
        case .base64Decode: return "lock.open"
        case .hashMD5: return "number.circle"
        case .snakeCase: return "textformat.abc.dottedunderline"
        case .camelCase: return "textformat"
        }
    }

    var description: String {
        switch self {
        case .direct: return "Pass the value through unchanged"
        case .uppercase: return "Convert all characters to uppercase"
        case .lowercase: return "Convert all characters to lowercase"
        case .trim: return "Remove leading and trailing whitespace"
        case .dateFormat: return "Apply date formatting rules"
        case .jsonParse: return "Parse JSON string into structured data"
        case .numberFormat: return "Format numbers with precision"
        case .base64Encode: return "Encode value to Base64"
        case .base64Decode: return "Decode Base64 to plain text"
        case .hashMD5: return "Generate MD5 hash of input"
        case .snakeCase: return "Convert to snake_case format"
        case .camelCase: return "Convert to camelCase format"
        }
    }
}

private enum MappingSortOrder: String, CaseIterable {
    case source, target, transform
}

private struct MappingValidation: Identifiable {
    let id = UUID()
    let sourceField: String
    let targetField: String
    let isValid: Bool
    let message: String
}

private struct TransformChainStep: Identifiable {
    let id = UUID()
    let transform: TransformType
}

private struct MappingPreset: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let mappings: [ConnectorFieldMapping]

    static var allPresets: [MappingPreset] {
        [
            MappingPreset(
                name: "User Profile",
                description: "Standard user profile field mappings",
                mappings: [
                    ConnectorFieldMapping(sourceField: "first_name", targetField: "firstName", transform: .camelCase, isRequired: true, defaultValue: nil),
                    ConnectorFieldMapping(sourceField: "last_name", targetField: "lastName", transform: .camelCase, isRequired: true, defaultValue: nil),
                    ConnectorFieldMapping(sourceField: "email", targetField: "emailAddress", transform: .lowercase, isRequired: true, defaultValue: nil),
                    ConnectorFieldMapping(sourceField: "phone", targetField: "phoneNumber", transform: .trim, isRequired: false, defaultValue: nil)
                ]
            ),
            MappingPreset(
                name: "API Response",
                description: "Common REST API response mappings",
                mappings: [
                    ConnectorFieldMapping(sourceField: "id", targetField: "identifier", transform: .direct, isRequired: true, defaultValue: nil),
                    ConnectorFieldMapping(sourceField: "created_at", targetField: "createdDate", transform: .dateFormat, isRequired: false, defaultValue: nil),
                    ConnectorFieldMapping(sourceField: "updated_at", targetField: "modifiedDate", transform: .dateFormat, isRequired: false, defaultValue: nil),
                    ConnectorFieldMapping(sourceField: "data", targetField: "payload", transform: .jsonParse, isRequired: true, defaultValue: "{}")
                ]
            ),
            MappingPreset(
                name: "Event Stream",
                description: "Event-driven data mappings",
                mappings: [
                    ConnectorFieldMapping(sourceField: "event_type", targetField: "eventName", transform: .snakeCase, isRequired: true, defaultValue: nil),
                    ConnectorFieldMapping(sourceField: "timestamp", targetField: "occurredAt", transform: .dateFormat, isRequired: true, defaultValue: nil),
                    ConnectorFieldMapping(sourceField: "payload", targetField: "eventData", transform: .jsonParse, isRequired: true, defaultValue: nil),
                    ConnectorFieldMapping(sourceField: "source", targetField: "origin", transform: .lowercase, isRequired: false, defaultValue: "unknown")
                ]
            )
        ]
    }
}
