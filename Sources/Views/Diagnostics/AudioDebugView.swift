import SwiftUI
import AudioToolbox

struct AudioDebugView: View {
    @State private var isPlayingAll = false
    @State private var currentSoundIndex = 0
    @State private var playbackTimer: Timer?
    @State private var searchText = ""

    let soundCategories: [SoundCategory] = [
        .init(name: "System Alerts", range: 1000...1016),
        .init(name: "UI Feedback", range: 1020...1036),
        .init(name: "Haptics & Taps", range: 1050...1059),
        .init(name: "Siri & Dictation", range: 1100...1118),
        .init(name: "Mail & Messages", range: 1200...1211),
        .init(name: "Calendar & Reminders", range: 1254...1259),
        .init(name: "Photos & Camera", range: 1300...1315),
        .init(name: "Lock & Keyboard", range: 1320...1336),
        .init(name: "Modern UI", range: 1350...1351),
        .init(name: "Legacy Alerts", ids: [4095, 1000, 1001, 1002, 1003, 1004, 1005, 1007, 1008, 1009, 1010, 1016])
    ]

    var allSounds: [SystemSoundID] {
        soundCategories.flatMap { $0.allIDs }
    }

    var filteredCategories: [SoundCategory] {
        if searchText.isEmpty {
            return soundCategories
        } else {
            return soundCategories.compactMap { category in
                let filteredIDs = category.allIDs.filter { String($0).contains(searchText) }
                return filteredIDs.isEmpty ? nil : SoundCategory(name: category.name, ids: filteredIDs)
            }
        }
    }

    var body: some View {
        List {
            Section {
                VStack(spacing: 12) {
                    Button(action: isPlayingAll ? stopPlayAll : playAll) {
                        HStack {
                            Image(systemName: isPlayingAll ? "stop.fill" : "play.fill")
                            Text(isPlayingAll ? "Stop Sequence" : "Play All Sequence")
                        }
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(isPlayingAll ? Color.red.opacity(0.1) : Color.blue.opacity(0.1))
                        .cornerRadius(10)
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(isPlayingAll ? .red : .blue)

                    if isPlayingAll {
                        ProgressView(value: Double(currentSoundIndex), total: Double(allSounds.count))
                            .tint(.blue)
                        Text("Playing: \(allSounds[currentSoundIndex]) (\(currentSoundIndex + 1)/\(allSounds.count))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 8)
            } header: {
                Text("Controls")
            }

            ForEach(filteredCategories, id: \.name) { category in
                Section(header: Text(category.name)) {
                    ForEach(category.allIDs, id: \.self) { id in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("ID: \(id)")
                                    .font(.system(.body, design: .monospaced))
                                    .fontWeight(.medium)
                            }

                            Spacer()

                            Button {
                                AudioServicesPlaySystemSound(id)
                            } label: {
                                Image(systemName: "play.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.blue)
                            }
                            .buttonStyle(.borderless)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .searchable(text: $searchText, prompt: "Search Sound ID")
        .navigationTitle("Audio Debugger")
        .navigationBarTitleDisplayMode(.large)
        .onDisappear {
            stopPlayAll()
        }
    }

    private func playAll() {
        isPlayingAll = true
        currentSoundIndex = 0
        playNextSound()
    }

    private func stopPlayAll() {
        isPlayingAll = false
        playbackTimer?.invalidate()
        playbackTimer = nil
    }

    private func playNextSound() {
        guard isPlayingAll, currentSoundIndex < allSounds.count else {
            stopPlayAll()
            return
        }

        let id = allSounds[currentSoundIndex]
        AudioServicesPlaySystemSound(id)

        playbackTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { _ in
            DispatchQueue.main.async {
                currentSoundIndex += 1
                playNextSound()
            }
        }
    }
}

struct SoundCategory {
    let name: String
    let range: ClosedRange<SystemSoundID>?
    let ids: [SystemSoundID]?

    init(name: String, range: ClosedRange<SystemSoundID>) {
        self.name = name
        self.range = range
        self.ids = nil
    }

    init(name: String, ids: [SystemSoundID]) {
        self.name = name
        self.range = nil
        self.ids = ids
    }

    var allIDs: [SystemSoundID] {
        if let range = range {
            return Array(range)
        } else if let ids = ids {
            return ids
        }
        return []
    }
}
