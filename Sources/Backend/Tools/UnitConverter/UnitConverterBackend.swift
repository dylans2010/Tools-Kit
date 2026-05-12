import Foundation

enum UnitCategory: String, CaseIterable, Sendable {
    case length = "Length"
    case mass = "Mass"
    case temperature = "Temp"
    case volume = "Volume"
    case speed = "Speed"
    case pressure = "Pressure"
    case energy = "Energy"
}

class UnitConverterBackend: ObservableObject {
    @Published var input = "1"
    @Published var output = "0"
    @Published var selectedCategory: UnitCategory = .length

    @Published var lengthUnitFrom: UnitLength = .meters
    @Published var lengthUnitTo: UnitLength = .feet

    @Published var massUnitFrom: UnitMass = .kilograms
    @Published var massUnitTo: UnitMass = .pounds

    @Published var tempUnitFrom: UnitTemperature = .celsius
    @Published var tempUnitTo: UnitTemperature = .fahrenheit

    @Published var volumeUnitFrom: UnitVolume = .liters
    @Published var volumeUnitTo: UnitVolume = .gallons

    @Published var speedUnitFrom: UnitSpeed = .kilometersPerHour
    @Published var speedUnitTo: UnitSpeed = .milesPerHour

    @Published var pressureUnitFrom: UnitPressure = .kilopascals
    @Published var pressureUnitTo: UnitPressure = .bars

    @Published var energyUnitFrom: UnitEnergy = .kilojoules
    @Published var energyUnitTo: UnitEnergy = .calories

    let lengthUnits: [UnitLength] = [.meters, .kilometers, .miles, .feet, .inches, .yards, .centimeters, .millimeters]
    let massUnits: [UnitMass] = [.kilograms, .grams, .pounds, .ounces, .stones, .metricTons]
    let tempUnits: [UnitTemperature] = [.celsius, .fahrenheit, .kelvin]
    let volumeUnits: [UnitVolume] = [.liters, .milliliters, .gallons, .cups, .pints, .quarts]
    let speedUnits: [UnitSpeed] = [.kilometersPerHour, .milesPerHour, .knots, .metersPerSecond]
    let pressureUnits: [UnitPressure] = [.kilopascals, .bars, .millimetersOfMercury, .poundsForcePerSquareInch, .hectopascals]
    let energyUnits: [UnitEnergy] = [.kilojoules, .calories, .kilocalories, .kilowattHours, .joules]

    func convert() {
        guard let value = Double(input) else { return }

        switch selectedCategory {
        case .length:
            let m = Measurement(value: value, unit: lengthUnitFrom)
            output = String(format: "%.4f", m.converted(to: lengthUnitTo).value)
        case .mass:
            let m = Measurement(value: value, unit: massUnitFrom)
            output = String(format: "%.4f", m.converted(to: massUnitTo).value)
        case .temperature:
            let m = Measurement(value: value, unit: tempUnitFrom)
            output = String(format: "%.4f", m.converted(to: tempUnitTo).value)
        case .volume:
            let m = Measurement(value: value, unit: volumeUnitFrom)
            output = String(format: "%.4f", m.converted(to: volumeUnitTo).value)
        case .speed:
            let m = Measurement(value: value, unit: speedUnitFrom)
            output = String(format: "%.4f", m.converted(to: speedUnitTo).value)
        case .pressure:
            let m = Measurement(value: value, unit: pressureUnitFrom)
            output = String(format: "%.4f", m.converted(to: pressureUnitTo).value)
        case .energy:
            let m = Measurement(value: value, unit: energyUnitFrom)
            output = String(format: "%.4f", m.converted(to: energyUnitTo).value)
        }
    }

    func swap() {
        switch selectedCategory {
        case .length:
            let temp = lengthUnitFrom
            lengthUnitFrom = lengthUnitTo
            lengthUnitTo = temp
        case .mass:
            let temp = massUnitFrom
            massUnitFrom = massUnitTo
            massUnitTo = temp
        case .temperature:
            let temp = tempUnitFrom
            tempUnitFrom = tempUnitTo
            tempUnitTo = temp
        case .volume:
            let temp = volumeUnitFrom
            volumeUnitFrom = volumeUnitTo
            volumeUnitTo = temp
        case .speed:
            let temp = speedUnitFrom
            speedUnitFrom = speedUnitTo
            speedUnitTo = temp
        case .pressure:
            let temp = pressureUnitFrom
            pressureUnitFrom = pressureUnitTo
            pressureUnitTo = temp
        case .energy:
            let temp = energyUnitFrom
            energyUnitFrom = energyUnitTo
            energyUnitTo = temp
        }
        convert()
    }
}
