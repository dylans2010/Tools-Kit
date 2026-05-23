import SwiftUI

struct Diag_DisplayZoomView: View {
    @State private var screenScale: CGFloat = 0
    @State private var nativeBounds: CGRect = .zero
    @State private var bounds: CGRect = .zero
    @State private var isZoomed = false

    var body: some View {
        Form {
            Section("Display Zoom") {
                VStack(spacing: 12) {
                    Image(systemName: isZoomed ? "plus.magnifyingglass" : "magnifyingglass")
                        .font(.system(size: 48))
                        .foregroundStyle(isZoomed ? .orange : .blue)
                    Text(isZoomed ? "Zoomed Mode" : "Standard Mode")
                        .font(.headline)
                    Text(isZoomed ? "Display is using zoomed layout" : "Display is at standard resolution")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }

            Section("Screen Metrics") {
                LabeledContent("Logical Size") {
                    Text("\(Int(bounds.width))×\(Int(bounds.height)) pts")
                }
                LabeledContent("Native Size") {
                    Text("\(Int(nativeBounds.width))×\(Int(nativeBounds.height)) px")
                }
                LabeledContent("Scale Factor") {
                    Text("\(Int(screenScale))x")
                }
                LabeledContent("Points Per Inch") {
                    Text(estimatedPPI)
                }
            }

            Section("Display Traits") {
                LabeledContent("Interface Idiom") {
                    Text(UIDevice.current.userInterfaceIdiom == .phone ? "iPhone" : "iPad")
                }
                LabeledContent("Color Gamut") {
                    let gamut = UIScreen.main.traitCollection.displayGamut
                    Text(gamut == .P3 ? "Display P3" : "sRGB")
                }
                LabeledContent("Force Touch") {
                    let cap = UIScreen.main.traitCollection.forceTouchCapability
                    Text(cap == .available ? "Available" : "Not Available")
                        .foregroundStyle(cap == .available ? .green : .secondary)
                }
            }
        }
        .navigationTitle("Display Zoom")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { loadInfo() }
    }

    private func loadInfo() {
        let screen = UIScreen.main
        screenScale = screen.scale
        nativeBounds = screen.nativeBounds
        bounds = screen.bounds
        let nativeWidth = nativeBounds.width / screenScale
        isZoomed = abs(nativeWidth - bounds.width) > 1
    }

    private var estimatedPPI: String {
        let ppi = Int(screenScale * 163)
        return "\(ppi)"
    }
}
