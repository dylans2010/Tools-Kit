import SwiftUI

struct UnitConverterView: View {
    @StateObject private var backend = UnitConverterBackend()

    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Select a category and enter a value to convert between different units of measurement.")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    ScrollView(.horizontal, showsIndicators: false) {
                        Picker("Category", selection: $backend.selectedCategory) {
                            ForEach(UnitCategory.allCases, id: \.self) { cat in
                                Text(cat.rawValue).tag(cat)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                }
                .padding(.vertical, 4)
            } header: {
                Text("Category")
            }

            Section {
                VStack(spacing: 16) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("From")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            TextField("Value", text: $backend.input)
                                .keyboardType(.decimalPad)
                                .font(.title3.bold())
                                .onChange(of: backend.input) { _ in backend.convert() }
                        }

                        Spacer()

                        unitPicker(for: .from)
                    }

                    Button(action: backend.swap) {
                        Image(systemName: "arrow.up.arrow.down.circle.fill")
                            .font(.title2)
                            .foregroundColor(.blue)
                    }

                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("To")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(backend.output)
                                .font(.title3.bold())
                                .foregroundColor(.blue)
                        }

                        Spacer()

                        unitPicker(for: .to)
                    }
                }
                .padding(.vertical, 8)
            } header: {
                Text("Conversion")
            }

            Section {
                Button(action: { UIPasteboard.general.string = backend.output }) {
                    Label("Copy Result", systemImage: "doc.on.doc")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .disabled(backend.output == "0")
            }
        }
        .navigationTitle("Unit Converter")
    }

    enum PickerType { case from, to }

    @ViewBuilder
    private func unitPicker(for type: PickerType) -> some View {
        switch backend.selectedCategory {
        case .length:
            Picker("", selection: type == .from ? $backend.lengthUnitFrom : $backend.lengthUnitTo) {
                ForEach(backend.lengthUnits, id: \.self) { unit in
                    Text(unit.symbol).tag(unit)
                }
            }
            .onChange(of: type == .from ? backend.lengthUnitFrom : backend.lengthUnitTo) { _ in backend.convert() }
        case .mass:
            Picker("", selection: type == .from ? $backend.massUnitFrom : $backend.massUnitTo) {
                ForEach(backend.massUnits, id: \.self) { unit in
                    Text(unit.symbol).tag(unit)
                }
            }
            .onChange(of: type == .from ? backend.massUnitFrom : backend.massUnitTo) { _ in backend.convert() }
        case .temperature:
            Picker("", selection: type == .from ? $backend.tempUnitFrom : $backend.tempUnitTo) {
                ForEach(backend.tempUnits, id: \.self) { unit in
                    Text(unit.symbol).tag(unit)
                }
            }
            .onChange(of: type == .from ? backend.tempUnitFrom : backend.tempUnitTo) { _ in backend.convert() }
        case .volume:
            Picker("", selection: type == .from ? $backend.volumeUnitFrom : $backend.volumeUnitTo) {
                ForEach(backend.volumeUnits, id: \.self) { unit in
                    Text(unit.symbol).tag(unit)
                }
            }
            .onChange(of: type == .from ? backend.volumeUnitFrom : backend.volumeUnitTo) { _ in backend.convert() }
        case .speed:
            Picker("", selection: type == .from ? $backend.speedUnitFrom : $backend.speedUnitTo) {
                ForEach(backend.speedUnits, id: \.self) { unit in
                    Text(unit.symbol).tag(unit)
                }
            }
            .onChange(of: type == .from ? backend.speedUnitFrom : backend.speedUnitTo) { _ in backend.convert() }
        case .pressure:
            Picker("", selection: type == .from ? $backend.pressureUnitFrom : $backend.pressureUnitTo) {
                ForEach(backend.pressureUnits, id: \.self) { unit in
                    Text(unit.symbol).tag(unit)
                }
            }
            .onChange(of: type == .from ? backend.pressureUnitFrom : backend.pressureUnitTo) { _ in backend.convert() }
        case .energy:
            Picker("", selection: type == .from ? $backend.energyUnitFrom : $backend.energyUnitTo) {
                ForEach(backend.energyUnits, id: \.self) { unit in
                    Text(unit.symbol).tag(unit)
                }
            }
            .onChange(of: type == .from ? backend.energyUnitFrom : backend.energyUnitTo) { _ in backend.convert() }
        }
    }
}

struct UnitConverterTool: Tool {
    let name = "Unit Converter"
    let icon = "ruler"
    let category = ToolCategory.conversion
    let complexity = ToolComplexity.basic
    let description = "Convert between various measurement units"
    let requiresAPI = false
    var view: AnyView { AnyView(UnitConverterView()) }
}
