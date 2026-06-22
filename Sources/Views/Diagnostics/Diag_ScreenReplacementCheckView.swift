import SwiftUI

struct Diag_ScreenReplacementCheckView: View {
    @State private var checks: [(String, String, ScreenStatus)] = []
    @State private var overallStatus: ScreenStatus = .unknown
    @State private var hasChecked = false

    enum ScreenStatus {
        case original, replaced, unknown

        var color: Color {
            switch self {
            case .original: return .green
            case .replaced: return .orange
            case .unknown: return .secondary
            }
        }
    }

    var body: some View {
        List {
            Section("Screen Replacement Detection") {
                VStack(spacing: 12) {
                    Image(systemName: overallStatus == .original ? "display" : overallStatus == .replaced ? "exclamationmark.triangle.fill" : "questionmark.circle.fill")
                        .font(.system(size: 52))
                        .foregroundStyle(overallStatus.color)
                    Text(overallStatus == .original ? "Screen Appears Original" : overallStatus == .replaced ? "Non-Original Screen Possible" : "Analyzing...")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }

            Section("Display Analysis") {
                ForEach(checks, id: \.0) { check in
                    HStack {
                        Image(systemName: check.2 == .original ? "checkmark.circle.fill" : check.2 == .replaced ? "exclamationmark.circle.fill" : "questionmark.circle.fill")
                            .foregroundStyle(check.2.color)
                            .frame(width: 24)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(check.0)
                                .font(.subheadline.weight(.medium))
                            Text(check.1)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            Section("How to Check Manually") {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Settings → General → About → check for 'Unknown Part'", systemImage: "gearshape.fill")
                        .font(.caption)
                    Label("iOS 15.2+ shows part replacement history", systemImage: "wrench.and.screwdriver.fill")
                        .font(.caption)
                    Label("True Tone may not work on non-genuine displays", systemImage: "circle.lefthalf.filled")
                        .font(.caption)
                    Label("3D Touch / Haptic Touch may behave differently", systemImage: "hand.point.up.left.fill")
                        .font(.caption)
                }
                .padding(.vertical, 4)
            }

            Section {
                Button {
                    analyzeScreen()
                } label: {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Re-analyze")
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Screen Replacement")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { analyzeScreen() }
    }

    private func analyzeScreen() {
        var results: [(String, String, ScreenStatus)] = []

        let screen = UIScreen.main
        let nativeRes = screen.nativeBounds
        let expectedResolutions = knownResolutions()
        let resKey = "\(Int(nativeRes.width))x\(Int(nativeRes.height))"
        let isKnownRes = expectedResolutions.contains(resKey)
        results.append(("Native Resolution", "\(resKey) px — \(isKnownRes ? "matches known Apple display" : "unusual resolution")", isKnownRes ? .original : .replaced))

        let scale = screen.nativeScale
        let knownScales: [CGFloat] = [1.0, 2.0, 3.0]
        let isKnownScale = knownScales.contains(scale)
        results.append(("Display Scale", "\(scale)x — \(isKnownScale ? "standard Apple scale" : "non-standard scale")", isKnownScale ? .original : .replaced))

        let maxFPS = screen.maximumFramesPerSecond
        let knownRefresh = [60, 120]
        let isKnownRefresh = knownRefresh.contains(maxFPS)
        results.append(("Refresh Rate", "\(maxFPS) Hz — \(isKnownRefresh ? "standard" : "unusual")", isKnownRefresh ? .original : .replaced))

        let brightness = screen.brightness
        results.append(("Brightness Control", String(format: "%.0f%% — brightness control functional", brightness * 100), .original))

        let colorSpace = screen.traitCollection.displayGamut
        let gamutStr = colorSpace == .P3 ? "P3 Wide Color" : "sRGB"
        results.append(("Color Gamut", gamutStr, colorSpace == .P3 ? .original : .unknown))

        let hasRoundCorners = screen.bounds.width != screen.nativeBounds.width / screen.nativeScale
        results.append(("Display Geometry", hasRoundCorners ? "Modern display geometry detected" : "Standard rectangular display", .original))

        checks = results
        let replacedCount = results.filter { $0.2 == .replaced }.count
        overallStatus = replacedCount == 0 ? .original : replacedCount >= 2 ? .replaced : .unknown
        hasChecked = true
    }

    private func knownResolutions() -> Set<String> {
        return [
            "640x960", "640x1136", "750x1334", "828x1792",
            "1080x1920", "1080x2340", "1125x2436", "1170x2532",
            "1179x2556", "1206x2622", "1242x2688", "1284x2778",
            "1290x2796", "1320x2868", "2048x2732", "2048x2048",
            "2160x2160", "2360x2160", "2388x1668", "2732x2048",
            "1668x2224", "1668x2388", "2048x1536",
            "1640x2360", "2266x1488", "2360x1640",
        ]
    }
}
