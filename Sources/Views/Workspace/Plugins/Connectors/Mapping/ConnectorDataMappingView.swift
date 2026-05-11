import SwiftUI

struct ConnectorDataMappingView: View {
    @State private var mappings: [DataMapping] = []
    @State private var showingCreateMapping = false
    @State private var sourceField = ""
    @State private var targetField = ""
    @State private var transformType: TransformType = .direct

    var body: some View {
        List {
            Section("Field Mappings") {
                if mappings.isEmpty {
                    ContentUnavailableView("No Mappings", systemImage: "arrow.left.arrow.right", description: Text("Create field mappings between connector data sources."))
                } else {
                    ForEach(mappings) { mapping in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(mapping.sourceField)
                                    .font(.subheadline.monospaced())
                                Text("Source")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            VStack(spacing: 2) {
                                Image(systemName: "arrow.right")
                                Text(mapping.transform.rawValue)
                                    .font(.caption2)
                                    .foregroundStyle(.blue)
                            }
                            Spacer()
                            VStack(alignment: .trailing) {
                                Text(mapping.targetField)
                                    .font(.subheadline.monospaced())
                                Text("Target")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .onDelete { indexSet in
                        mappings.remove(atOffsets: indexSet)
                    }
                }
            }

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
                    }
                }
            }
        }
        .navigationTitle("Data Mapping")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showingCreateMapping = true } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingCreateMapping) {
            NavigationStack {
                Form {
                    Section("Source") {
                        TextField("Source Field", text: $sourceField)
                    }
                    Section("Target") {
                        TextField("Target Field", text: $targetField)
                    }
                    Section("Transform") {
                        Picker("Type", selection: $transformType) {
                            ForEach(TransformType.allCases, id: \.self) { type in
                                Text(type.rawValue.capitalized).tag(type)
                            }
                        }
                    }
                }
                .navigationTitle("New Mapping")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Cancel") { showingCreateMapping = false } }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Add") {
                            mappings.append(DataMapping(sourceField: sourceField, targetField: targetField, transform: transformType))
                            sourceField = ""
                            targetField = ""
                            showingCreateMapping = false
                        }
                        .disabled(sourceField.isEmpty || targetField.isEmpty)
                    }
                }
            }
        }
    }
}

private struct DataMapping: Identifiable {
    let id = UUID()
    let sourceField: String
    let targetField: String
    let transform: TransformType
}

private enum TransformType: String, CaseIterable {
    case direct, uppercase, lowercase, trim, dateFormat, jsonParse, numberFormat

    var icon: String {
        switch self {
        case .direct: return "equal"
        case .uppercase: return "textformat.size.larger"
        case .lowercase: return "textformat.size.smaller"
        case .trim: return "scissors"
        case .dateFormat: return "calendar"
        case .jsonParse: return "curlybraces"
        case .numberFormat: return "number"
        }
    }

    var description: String {
        switch self {
        case .direct: return "Pass value as-is"
        case .uppercase: return "Convert to uppercase"
        case .lowercase: return "Convert to lowercase"
        case .trim: return "Trim whitespace"
        case .dateFormat: return "Parse and format dates"
        case .jsonParse: return "Parse JSON strings"
        case .numberFormat: return "Format numeric values"
        }
    }
}
