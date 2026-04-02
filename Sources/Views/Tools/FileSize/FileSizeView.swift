import SwiftUI

struct FileSizeView: View {
    @StateObject private var backend = FileSizeBackend()

    var body: some View {
        VStack(spacing: 0) {
            Form {
                Section(header: Text("Input Value")) {
                    HStack {
                        TextField("Amount", text: $backend.inputAmount)
                            .keyboardType(.decimalPad)
                            .font(.title3.bold())
                            .onChange(of: backend.inputAmount) { _ in backend.convert() }

                        Spacer()

                        Picker("", selection: $backend.inputUnit) {
                            ForEach(FileSizeBackend.SizeUnit.allCases) { unit in
                                Text(unit.rawValue).tag(unit)
                            }
                        }
                        .onChange(of: backend.inputUnit) { _ in backend.convert() }
                    }
                }

                Section(header: Text("Conversion Table")) {
                    ForEach(FileSizeBackend.SizeUnit.allCases) { unit in
                        HStack {
                            Text(unit.rawValue)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(backend.results[unit.rawValue] ?? "0")
                                .font(.system(.body, design: .monospaced))
                                .bold()
                                .onTapGesture {
                                    UIPasteboard.general.string = backend.results[unit.rawValue]
                                }
                        }
                    }
                }
            }
        }
        .navigationTitle("File Size Converter")
        .onAppear { backend.convert() }
    }
}

struct FileSizeTool: Tool {
    let name = "File Size Converter"
    let icon = "externaldrive"
    let category = ToolCategory.conversion
    let complexity = ToolComplexity.basic
    let description = "Instantly convert between bytes, KB, MB, GB, and TB"
    let requiresAPI = false
    var view: AnyView { AnyView(FileSizeView()) }
}
