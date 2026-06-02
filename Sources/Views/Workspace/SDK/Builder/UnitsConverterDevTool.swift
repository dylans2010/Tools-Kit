import SwiftUI

struct UnitsConverterDevTool: DevTool {
    let id = "units-converter"
    let name = "Units Converter"
    let category: DevToolCategory = .data
    let icon = "scalemass"
    let description = "Convert between various physical units using Foundation Measurement"

    func render() -> some View {
        SimpleDevToolView(title: name, placeholder: "100, km, miles (length, mass, temp)") { input in
            let parts = input.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces).lowercased() }
            guard parts.count == 3, let value = Double(parts[0]) else {
                return "Format: value, fromUnit, toUnit\nExamples:\n100, km, miles\n32, f, c\n1, kg, lb"
            }

            let from = parts[1]
            let to = parts[2]

            // Length
            if let fU = lengthUnit(from), let tU = lengthUnit(to) {
                let m = Measurement(value: value, unit: fU)
                return "\(value) \(from) = \(m.converted(to: tU).value) \(to)"
            }
            // Mass
            if let fU = massUnit(from), let tU = massUnit(to) {
                let m = Measurement(value: value, unit: fU)
                return "\(value) \(from) = \(m.converted(to: tU).value) \(to)"
            }
            // Temperature
            if let fU = tempUnit(from), let tU = tempUnit(to) {
                let m = Measurement(value: value, unit: fU)
                return "\(value) \(from) = \(m.converted(to: tU).value) \(to)"
            }

            return "Unsupported units or mismatching categories."
        }
    }

    private func lengthUnit(_ s: String) -> UnitLength? {
        switch s {
        case "km": return .kilometers
        case "m": return .meters
        case "cm": return .centimeters
        case "mm": return .millimeters
        case "miles", "mi": return .miles
        case "yards", "yd": return .yards
        case "feet", "ft": return .feet
        case "inches", "in": return .inches
        default: return nil
        }
    }

    private func massUnit(_ s: String) -> UnitMass? {
        switch s {
        case "kg": return .kilograms
        case "g": return .grams
        case "mg": return .milligrams
        case "lb", "pounds": return .pounds
        case "oz", "ounces": return .ounces
        default: return nil
        }
    }

    private func tempUnit(_ s: String) -> UnitTemperature? {
        switch s {
        case "c", "celsius": return .celsius
        case "f", "fahrenheit": return .fahrenheit
        case "k", "kelvin": return .kelvin
        default: return nil
        }
    }
}
