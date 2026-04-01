import SwiftUI

class ColorPickerBackend: ObservableObject {
    @Published var selectedColor: Color = .blue

    var hex: String {
        guard let components = UIColor(selectedColor).cgColor.components, components.count >= 3 else {
            return "#000000"
        }
        let r = Float(components[0])
        let g = Float(components[1])
        let b = Float(components[2])
        return String(format: "#%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255))
    }

    var rgb: String {
        guard let components = UIColor(selectedColor).cgColor.components, components.count >= 3 else {
            return "RGB(0, 0, 0)"
        }
        let r = Int(components[0] * 255)
        let g = Int(components[1] * 255)
        let b = Int(components[2] * 255)
        return "RGB(\(r), \(g), \(b))"
    }
}
