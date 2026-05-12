import SwiftUI

struct FileSizeView: View {
    @StateObject private var backend = FileSizeBackend()

    var body: some View {
        VStack(spacing: 0) {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Enter a value and select its unit to see conversions across all standard data sizes.")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        HStack {
                            TextField("e.g. 1024", text: $backend.inputAmount)
                                .keyboardType(.decimalPad)
                                .font(.title3.bold())
                                .foregroundColor(.blue)
                                .onChange(of: backend.inputAmount) { _, _ in backend.convert() }

                            Spacer()

                            Picker("Unit", selection: $backend.inputUnit) {
                                ForEach(FileSizeBackend.SizeUnit.allCases) { unit in
                                    Text(unit.rawValue).tag(unit)
                                }
                            }
                            .pickerStyle(.menu)
                            .onChange(of: backend.inputUnit) { _, _ in backend.convert() }
                        }
                    }
                } header: {
                    Text("Input Value")
                }

                Section {
                    ForEach(FileSizeBackend.SizeUnit.allCases) { unit in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(unit.rawValue)
                                    .font(.headline)
                                Text(descriptionForUnit(unit))
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            HStack {
                                Text(backend.results[unit.rawValue] ?? "0")
                                    .font(.system(.body, design: .monospaced))
                                    .bold()

                                Button(action: {
                                    UIPasteboard.general.string = backend.results[unit.rawValue]
                                }) {
                                    Image(systemName: "doc.on.doc")
                                        .font(.caption2)
                                }
                                .buttonStyle(.borderless)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                } header: {
                    Text("Conversion Results")
                } footer: {
                    Text("Conversions use the standard base-1024 system (1 KB = 1024 Bytes).")
                }
            }
        }
        .navigationTitle("File Size Converter")
        .onAppear { backend.convert() }
    }

    private func descriptionForUnit(_ unit: FileSizeBackend.SizeUnit) -> String {
        switch unit {
        case .bytes: return "Base unit of data"
        case .kilobytes: return "Kilobytes"
        case .megabytes: return "Megabytes"
        case .gigabytes: return "Gigabytes"
        case .terabytes: return "Terabytes"
        }
    }
}

struct FileSizeTool: Tool, Sendable {
    let name = "File Size Converter"
    let icon = "externaldrive"
    let category = ToolCategory.conversion
    let complexity = ToolComplexity.basic
    let description = "Instantly convert between bytes, KB, MB, GB, and TB"
    let requiresAPI = false
    var view: AnyView { AnyView(FileSizeView()) }
}
