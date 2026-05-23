import SwiftUI

struct Diag_ScreenResolutionView: View {
    @StateObject private var service = DiagnosticsService.shared

    var body: some View {
        List {
            Section("Native Resolution") {
                LabeledContent("Width", value: "\(Int(service.screenNativeBounds.width)) px")
                LabeledContent("Height", value: "\(Int(service.screenNativeBounds.height)) px")
                LabeledContent("Native Scale", value: "\(service.screenNativeScale, specifier: "%.1f")x")
            }

            Section("Logical (Points)") {
                LabeledContent("Width", value: "\(Int(service.screenBounds.width)) pt")
                LabeledContent("Height", value: "\(Int(service.screenBounds.height)) pt")
                LabeledContent("Scale", value: "\(service.screenScale, specifier: "%.1f")x")
            }

            Section("Display Metrics") {
                LabeledContent("DPI", value: "\(Int(service.screenNativeScale * 163)) ppi")
                LabeledContent("Aspect Ratio", value: String(format: "%.2f:1", service.screenBounds.height / service.screenBounds.width))
            }
        }
        .navigationTitle("Screen Resolution")
    }
}
