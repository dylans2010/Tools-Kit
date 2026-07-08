import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct Diag_DisplayInfoView: View {
    var body: some View {
        Form {
            Section("Display Metrics") {
                LabeledContent("Resolution") {
                    Text("\(Int(UIScreen.main.nativeBounds.width))×\(Int(UIScreen.main.nativeBounds.height))")
                        .monospacedDigit()
                }
                LabeledContent("Points") {
                    Text("\(Int(UIScreen.main.bounds.width))×\(Int(UIScreen.main.bounds.height))")
                        .monospacedDigit()
                }
                LabeledContent("Scale Factor") {
                    Text("\(Int(UIScreen.main.scale))x (@\(Int(UIScreen.main.scale))x)")
                }
                LabeledContent("Native Scale") {
                    Text(String(format: "%.2f", UIScreen.main.nativeScale))
                        .monospacedDigit()
                }
                LabeledContent("PPI (estimated)") {
                    Text("\(estimatedPPI)")
                        .monospacedDigit()
                }
            }

            Section("Refresh Rate") {
                LabeledContent("Max Refresh") {
                    Text("\(UIScreen.main.maximumFramesPerSecond) Hz")
                }
                LabeledContent("ProMotion") {
                    Text(UIScreen.main.maximumFramesPerSecond >= 120 ? "Supported (120Hz)" : "Standard (60Hz)")
                        .foregroundStyle(UIScreen.main.maximumFramesPerSecond >= 120 ? .green : .secondary)
                }
            }

            Section("Brightness") {
                LabeledContent("Current") {
                    Text(String(format: "%.0f%%", UIScreen.main.brightness * 100))
                        .monospacedDigit()
                }
                LabeledContent("Auto-Brightness") {
                    Text("Managed by iOS")
                        .foregroundStyle(.secondary)
                }
            }

            Section("Color") {
                LabeledContent("Color Space") {
                    Text(colorSpace)
                }
                LabeledContent("Wide Color (P3)") {
                    Text(UIScreen.main.traitCollection.displayGamut == .P3 ? "Supported" : "sRGB Only")
                        .foregroundStyle(UIScreen.main.traitCollection.displayGamut == .P3 ? .green : .secondary)
                }
                LabeledContent("True Tone") {
                    Text("Available on supported devices")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Section("Safe Areas") {
                if let window = UIApplication.shared.connectedScenes
                    .compactMap({ $0 as? UIWindowScene })
                    .first?.windows.first {
                    let insets = window.safeAreaInsets
                    LabeledContent("Top") { Text("\(Int(insets.top)) pt").monospacedDigit() }
                    LabeledContent("Bottom") { Text("\(Int(insets.bottom)) pt").monospacedDigit() }
                    LabeledContent("Left") { Text("\(Int(insets.left)) pt").monospacedDigit() }
                    LabeledContent("Right") { Text("\(Int(insets.right)) pt").monospacedDigit() }
                    LabeledContent("Has Notch/Island") {
                        Text(insets.top > 20 ? "Yes" : "No")
                            .foregroundStyle(insets.top > 20 ? .blue : .secondary)
                    }
                }
            }

            Section("Interface") {
                LabeledContent("Style") {
                    Text(UITraitCollection.current.userInterfaceStyle == .dark ? "Dark Mode" : "Light Mode")
                }
                LabeledContent("Size Class (H)") {
                    Text(horizontalSizeClass)
                }
                LabeledContent("Layout Direction") {
                    Text(UIApplication.shared.userInterfaceLayoutDirection == .leftToRight ? "LTR" : "RTL")
                }
                LabeledContent("Display Zoom") {
                    let isZoomed = UIScreen.main.nativeScale != UIScreen.main.scale
                    Text(isZoomed ? "Zoomed" : "Standard")
                        .foregroundStyle(isZoomed ? .orange : .green)
                }
            }
        }
        .navigationTitle("Display Info")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var estimatedPPI: Int {
        let scale = Int(UIScreen.main.nativeScale)
        // Common iOS device PPI values
        if scale >= 3 && UIScreen.main.nativeBounds.height >= 2796 { return 460 }
        if scale >= 3 { return 458 }
        if scale >= 2 { return 326 }
        return 163
    }

    private var colorSpace: String {
        if UIScreen.main.traitCollection.displayGamut == .P3 { return "Display P3" }
        return "sRGB"
    }

    private var horizontalSizeClass: String {
        let size = UITraitCollection.current.horizontalSizeClass
        switch size {
        case .compact: return "Compact"
        case .regular: return "Regular"
        default: return "Unspecified"
        }
    }
}
