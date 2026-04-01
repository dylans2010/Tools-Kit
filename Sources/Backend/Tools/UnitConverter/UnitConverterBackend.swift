import Foundation

class UnitConverterBackend: ObservableObject {
    @Published var input = "0"
    @Published var output = "0"
    @Published var inputUnit: UnitLength = .meters
    @Published var outputUnit: UnitLength = .feet

    let units: [UnitLength] = [.meters, .kilometers, .miles, .feet, .inches, .yards, .centimeters, .millimeters]

    func convert() {
        guard let inputValue = Double(input) else { return }
        let measurement = Measurement(value: inputValue, unit: inputUnit)
        let result = measurement.converted(to: outputUnit)
        output = String(format: "%.4f", result.value)
    }
}
