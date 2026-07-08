import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct Diag_ScreenMirrorDetectView: View {
    @State private var isMirrored = false
    @State private var screenCount: Int = 0
    @State private var mainScreenInfo: ScreenInfo?
    @State private var mirroredScreenInfo: ScreenInfo?
    @State private var isMonitoring = false
    @State private var timer: Timer?
    @State private var capturedState = false

    struct ScreenInfo: Identifiable {
        let id = UUID()
        let bounds: CGRect
        let scale: CGFloat
        let nativeBounds: CGRect
        let brightness: CGFloat
        let description: String
    }

    var body: some View {
        Form {
            Section("Mirror Status") {
                HStack {
                    Image(systemName: isMirrored ? "tv.and.mediabox.fill" : "tv.slash")
                        .font(.system(size: 36))
                        .foregroundStyle(isMirrored ? .green : .secondary)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(isMirrored ? "Screen Mirroring Active" : "Not Mirroring")
                            .font(.headline)
                        Text(isMirrored ? "Content is being displayed externally" : "No external display detected")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 8)
            }

            Section("Display Info") {
                LabeledContent("Connected Screens") { Text("\(screenCount)") }
                LabeledContent("Screen Capture") {
                    Text(capturedState ? "Active" : "Inactive")
                        .foregroundStyle(capturedState ? .orange : .green)
                }
            }

            if let main = mainScreenInfo {
                Section("Main Screen") {
                    LabeledContent("Resolution") {
                        Text("\(Int(main.nativeBounds.width))×\(Int(main.nativeBounds.height))")
                            .monospacedDigit()
                    }
                    LabeledContent("Points") {
                        Text("\(Int(main.bounds.width))×\(Int(main.bounds.height))")
                            .monospacedDigit()
                    }
                    LabeledContent("Scale") {
                        Text("\(Int(main.scale))x")
                    }
                    LabeledContent("Brightness") {
                        Text(String(format: "%.0f%%", main.brightness * 100))
                            .monospacedDigit()
                    }
                }
            }

            if let mirror = mirroredScreenInfo {
                Section("External Display") {
                    LabeledContent("Resolution") {
                        Text("\(Int(mirror.nativeBounds.width))×\(Int(mirror.nativeBounds.height))")
                            .monospacedDigit()
                    }
                    LabeledContent("Scale") {
                        Text("\(Int(mirror.scale))x")
                    }
                }
            }

            Section("Security") {
                LabeledContent("Screen Recording") {
                    Text(UIScreen.main.isCaptured ? "Detected" : "Not Detected")
                        .foregroundStyle(UIScreen.main.isCaptured ? .red : .green)
                }
                HStack {
                    Image(systemName: UIScreen.main.isCaptured ? "exclamationmark.triangle.fill" : "checkmark.shield.fill")
                        .foregroundStyle(UIScreen.main.isCaptured ? .red : .green)
                    Text(UIScreen.main.isCaptured ? "Screen content is being captured or recorded" : "No screen capture detected")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Section {
                Button {
                    refreshStatus()
                } label: {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Refresh Status")
                    }
                }

                Button {
                    if isMonitoring { stopMonitoring() } else { startMonitoring() }
                } label: {
                    HStack {
                        Image(systemName: isMonitoring ? "stop.circle.fill" : "play.circle.fill")
                        Text(isMonitoring ? "Stop Monitoring" : "Start Monitoring")
                    }
                }
            }
        }
        .navigationTitle("Screen Mirror Detection")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { refreshStatus() }
        .onDisappear { stopMonitoring() }
        .onReceive(NotificationCenter.default.publisher(for: UIScreen.didConnectNotification)) { _ in
            refreshStatus()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIScreen.didDisconnectNotification)) { _ in
            refreshStatus()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIScreen.capturedDidChangeNotification)) { _ in
            capturedState = UIScreen.main.isCaptured
        }
    }

    private func startMonitoring() {
        isMonitoring = true
        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            refreshStatus()
        }
    }

    private func stopMonitoring() {
        timer?.invalidate()
        timer = nil
        isMonitoring = false
    }

    private func refreshStatus() {
        let screens = UIScreen.screens
        screenCount = screens.count
        isMirrored = screens.count > 1 || UIScreen.main.mirrored != nil
        capturedState = UIScreen.main.isCaptured

        let main = UIScreen.main
        mainScreenInfo = ScreenInfo(
            bounds: main.bounds,
            scale: main.scale,
            nativeBounds: main.nativeBounds,
            brightness: main.brightness,
            description: "Main Display"
        )

        if let mirror = main.mirrored ?? screens.dropFirst().first {
            mirroredScreenInfo = ScreenInfo(
                bounds: mirror.bounds,
                scale: mirror.scale,
                nativeBounds: mirror.nativeBounds,
                brightness: 1.0,
                description: "External Display"
            )
        } else {
            mirroredScreenInfo = nil
        }
    }
}
