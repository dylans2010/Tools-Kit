import SwiftUI
#if canImport(AVFoundation)
import AVFoundation
#endif
import MediaPlayer

struct Diag_MuteSwitchActionButtonView: View {
    @State private var isSilentMode = false
    @State private var hasActionButton = false
    @State private var deviceModel = ""
    @State private var isMonitoring = false
    @State private var timer: Timer?
    @State private var toggleHistory: [(Date, Bool)] = []
    @State private var details: [(String, String)] = []

    var body: some View {
        Form {
            Section("Mute Switch / Action Button") {
                VStack(spacing: 12) {
                    Image(systemName: hasActionButton ? "button.horizontal.top.press.fill" : "bell.slash.fill")
                        .font(.system(size: 52))
                        .foregroundStyle(hasActionButton ? .purple : .orange)
                    Text(hasActionButton ? "Action Button" : "Mute Switch")
                        .font(.headline)
                    Text(hasActionButton ? "Customizable Action Button (iPhone 15 Pro+)" : "Ring/Silent toggle switch")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }

            Section("Current State") {
                LabeledContent("Silent Mode") {
                    HStack {
                        Image(systemName: isSilentMode ? "bell.slash.fill" : "bell.fill")
                            .foregroundStyle(isSilentMode ? .orange : .green)
                        Text(isSilentMode ? "Silent" : "Ring")
                    }
                }
                LabeledContent("Device") {
                    Text(deviceModel)
                        .font(.caption)
                }
                LabeledContent("Switch Type") {
                    Text(hasActionButton ? "Action Button" : "Mute Switch")
                        .font(.caption)
                }
            }

            Section("Device Details") {
                ForEach(details, id: \.0) { d in
                    LabeledContent(d.0) { Text(d.1).font(.caption) }
                }
            }

            if hasActionButton {
                Section("Action Button Features") {
                    VStack(alignment: .leading, spacing: 6) {
                        Label("Silent Mode toggle", systemImage: "bell.slash.fill").font(.caption)
                        Label("Focus mode activation", systemImage: "moon.fill").font(.caption)
                        Label("Camera quick launch", systemImage: "camera.fill").font(.caption)
                        Label("Flashlight toggle", systemImage: "flashlight.on.fill").font(.caption)
                        Label("Voice Memo recording", systemImage: "mic.fill").font(.caption)
                        Label("Magnifier launch", systemImage: "plus.magnifyingglass").font(.caption)
                        Label("Shortcut execution", systemImage: "command.circle.fill").font(.caption)
                        Label("Accessibility action", systemImage: "accessibility").font(.caption)
                        Label("Translate launch", systemImage: "character.book.closed.fill").font(.caption)
                    }
                    .padding(.vertical, 4)
                }
            }

            Section("Toggle History") {
                if toggleHistory.isEmpty {
                    Text("Toggle the switch to record changes")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(Array(toggleHistory.suffix(10).enumerated()), id: \.offset) { _, entry in
                        HStack {
                            Image(systemName: entry.1 ? "bell.slash.fill" : "bell.fill")
                                .foregroundStyle(entry.1 ? .orange : .green)
                                .font(.caption)
                            Text(entry.1 ? "Silent" : "Ring")
                                .font(.caption)
                            Spacer()
                            Text(entry.0, style: .time)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            Section {
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
        .navigationTitle("Mute Switch / Action Button")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { checkDevice(); startMonitoring() }
        .onDisappear { stopMonitoring() }
    }

    private func checkDevice() {
        var sysInfo = utsname()
        uname(&sysInfo)
        let modelId = Mirror(reflecting: sysInfo.machine).children.reduce("") { id, el in
            guard let v = el.value as? Int8, v != 0 else { return id }
            return id + String(UnicodeScalar(UInt8(v)))
        }
        deviceModel = modelId

        let actionButtonModels = [
            "iPhone16,1", "iPhone16,2",
            "iPhone17,1", "iPhone17,2", "iPhone17,3", "iPhone17,4",
            "iPhone17,5", "iPhone17,6", "iPhone17,7", "iPhone17,8"
        ]
        hasActionButton = actionButtonModels.contains(modelId)

        var info: [(String, String)] = []
        info.append(("Model Identifier", modelId))
        info.append(("iOS Version", UIDevice.current.systemVersion))
        info.append(("Switch Type", hasActionButton ? "Action Button" : "Ring/Silent Switch"))
        info.append(("Customizable", hasActionButton ? "Yes" : "No"))
        details = info
    }

    private func startMonitoring() {
        isMonitoring = true
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, options: .mixWithOthers)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {}

        var lastSilent = isSilentMode
        timer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { _ in
            let session = AVAudioSession.sharedInstance()
            let vol = session.outputVolume
            let route = session.currentRoute
            let silent = route.outputs.contains { $0.portType == .builtInReceiver } && vol == 0
            let newSilent = session.category == .soloAmbient ? false : silent

            if newSilent != lastSilent {
                isSilentMode = newSilent
                toggleHistory.append((Date(), newSilent))
                lastSilent = newSilent
            }
        }
    }

    private func stopMonitoring() {
        timer?.invalidate()
        timer = nil
        isMonitoring = false
    }
}
