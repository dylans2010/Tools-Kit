import SwiftUI

struct DeveloperUnitConverterView: View {
    @State private var inputValue = ""
    @State private var inputUnit: DataUnit = .mb
    @State private var outputUnit: DataUnit = .gb

    enum DataUnit: String, CaseIterable, Identifiable {
        case b = "Bytes"
        case kb = "KB"
        case mb = "MB"
        case gb = "GB"
        case tb = "TB"

        var id: String { self.rawValue }

        var multiplier: Double {
            switch self {
            case .b: return 1
            case .kb: return 1024
            case .mb: return 1024 * 1024
            case .gb: return 1024 * 1024 * 1024
            case .tb: return 1024 * 1024 * 1024 * 1024
            }
        }
    }

    var convertedValue: String {
        guard let value = Double(inputValue) else { return "0" }
        let bytes = value * inputUnit.multiplier
        let result = bytes / outputUnit.multiplier
        return String(format: "%.4f", result).replacingOccurrences(of: ".0000", with: "")
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Input").font(.headline)

                    HStack {
                        TextField("Value", text: $inputValue)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(.roundedBorder)

                        Picker("Unit", selection: $inputUnit) {
                            ForEach(DataUnit.allCases) { unit in
                                Text(unit.rawValue).tag(unit)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                }
                .padding()
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                Image(systemName: "arrow.down")
                    .font(.title2)
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 16) {
                    Text("Output").font(.headline)

                    HStack {
                        Text(convertedValue)
                            .font(.title3.bold())

                        Spacer()

                        Picker("Unit", selection: $outputUnit) {
                            ForEach(DataUnit.allCases) { unit in
                                Text(unit.rawValue).tag(unit)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                }
                .padding()
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding()
        }
        .navigationTitle("Unit Converter")
        .background(Color(uiColor: .systemGroupedBackground))
    }
}
