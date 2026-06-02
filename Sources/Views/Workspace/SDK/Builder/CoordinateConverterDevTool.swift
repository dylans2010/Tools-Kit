import SwiftUI

struct CoordinateConverterDevTool: DevTool {
    let id = "coordinate-converter"
    let name = "Coordinate Converter"
    let category: DevToolCategory = .data
    let icon = "mappin.and.ellipse"
    let description = "Convert between GPS coordinate formats"

    func render() -> some View {
        SimpleDevToolView(title: name, placeholder: "40.7128, -74.0060") { input in
            "DMS: 40° 42' 46.08\" N, 74° 0' 21.6\" W (Mock)"
        }
    }
}
