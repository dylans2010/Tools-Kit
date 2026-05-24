import SwiftUI

struct Diag_ProMotionTestView: View {
    @State private var hasProMotion = false
    @State private var maxFPS = 0
    @State private var details: [(String, String)] = []
    @State private var currentFPS: Double = 0
    @State private var displayLink: CADisplayLink?
    @State private var lastTimestamp: CFTimeInterval = 0
    @State private var frameCount = 0
    @State private var isMonitoring = false

    var body: some View {
        Form {
            Section("ProMotion Display") {
                VStack(spacing: 12) {
                    Image(systemName: hasProMotion ? "gauge.with.dots.needle.100percent" : "gauge.with.dots.needle.67percent")
                        .font(.system(size: 52))
                        .foregroundStyle(hasProMotion ? .green : .secondary)
                    Text(hasProMotion ? "ProMotion 120Hz" : "Standard 60Hz")
                        .font(.headline)
                    Text(hasProMotion ? "LTPO adaptive refresh rate from 1Hz to 120Hz" : "Fixed 60Hz refresh rate display")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }

            Section("Display Details") {
                ForEach(details, id: \.0) { d in
                    LabeledContent(d.0) { Text(d.1).font(.caption) }
                }
            }

            Section("Live FPS") {
                VStack(spacing: 8) {
                    Text(String(format: "%.0f FPS", currentFPS))
                        .font(.system(size: 36, weight: .bold, design: .monospaced))
                        .foregroundStyle(currentFPS >= 110 ? .green : currentFPS >= 55 ? .blue : .orange)
                    ProgressView(value: currentFPS / Double(maxFPS > 0 ? maxFPS : 60))
                        .tint(currentFPS >= 110 ? .green : .blue)
                }
                .padding(.vertical, 8)

                Button {
                    if isMonitoring { stopMonitoring() } else { startMonitoring() }
                } label: {
                    HStack {
                        Image(systemName: isMonitoring ? "stop.circle.fill" : "play.circle.fill")
                        Text(isMonitoring ? "Stop FPS Monitor" : "Start FPS Monitor")
                    }
                }
            }

            Section("ProMotion Features") {
                VStack(alignment: .leading, spacing: 6) {
                    Label("120Hz maximum refresh rate", systemImage: "arrow.clockwise").font(.caption)
                    Label("Adaptive 10-120Hz (or 1-120Hz LTPO)", systemImage: "slider.horizontal.3").font(.caption)
                    Label("Smoother scrolling and animations", systemImage: "hand.draw.fill").font(.caption)
                    Label("Lower latency Apple Pencil (iPad)", systemImage: "pencil.tip").font(.caption)
                    Label("Power savings at low refresh rates", systemImage: "battery.100").font(.caption)
                }
                .padding(.vertical, 4)
            }

            Section("Compatible Devices") {
                VStack(alignment: .leading, spacing: 6) {
                    Label("iPhone 13 Pro / Pro Max (10-120Hz)", systemImage: "iphone.gen2").font(.caption)
                    Label("iPhone 14 Pro / Pro Max (1-120Hz LTPO)", systemImage: "iphone.gen3").font(.caption)
                    Label("iPhone 15 Pro / Pro Max (1-120Hz LTPO)", systemImage: "iphone.gen3").font(.caption)
                    Label("iPhone 16 Pro / Pro Max (1-120Hz LTPO)", systemImage: "iphone.gen3").font(.caption)
                    Label("iPad Pro M1+ (24-120Hz)", systemImage: "ipad").font(.caption)
                }
                .padding(.vertical, 4)
            }

            Section {
                Button { checkProMotion() } label: {
                    HStack { Image(systemName: "arrow.clockwise"); Text("Re-check") }
                }
            }
        }
        .navigationTitle("ProMotion Test")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { checkProMotion() }
        .onDisappear { stopMonitoring() }
    }

    private func checkProMotion() {
        var info: [(String, String)] = []
        maxFPS = UIScreen.main.maximumFramesPerSecond
        hasProMotion = maxFPS >= 120
        info.append(("Max Refresh Rate", "\(maxFPS) Hz"))
        info.append(("ProMotion", hasProMotion ? "Yes" : "No"))
        info.append(("Display Type", hasProMotion ? "LTPO OLED" : "Standard"))

        let screenBounds = UIScreen.main.bounds
        info.append(("Screen Size", "\(Int(screenBounds.width)) x \(Int(screenBounds.height))"))
        info.append(("Native Scale", String(format: "%.1f", UIScreen.main.nativeScale)))

        var sysInfo = utsname()
        uname(&sysInfo)
        let modelId = Mirror(reflecting: sysInfo.machine).children.reduce("") { id, el in
            guard let v = el.value as? Int8, v != 0 else { return id }
            return id + String(UnicodeScalar(UInt8(v)))
        }
        info.append(("Device Model", modelId))

        details = info
    }

    private func startMonitoring() {
        isMonitoring = true
        let link = CADisplayLink(target: DisplayLinkTarget { [self] link in
            frameCount += 1
            let elapsed = link.timestamp - lastTimestamp
            if elapsed >= 1.0 {
                currentFPS = Double(frameCount) / elapsed
                frameCount = 0
                lastTimestamp = link.timestamp
            }
            if lastTimestamp == 0 { lastTimestamp = link.timestamp }
        }, selector: #selector(DisplayLinkTarget.step(_:)))
        link.add(to: .main, forMode: .common)
        displayLink = link
    }

    private func stopMonitoring() {
        displayLink?.invalidate()
        displayLink = nil
        isMonitoring = false
    }
}

private class DisplayLinkTarget {
    let callback: (CADisplayLink) -> Void
    init(_ callback: @escaping (CADisplayLink) -> Void) { self.callback = callback }
    @objc func step(_ link: CADisplayLink) { callback(link) }
}
