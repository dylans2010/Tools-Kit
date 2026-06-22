import SwiftUI
import AudioToolbox

/// ViewModel to handle sound data and playback logic, preventing UI freezes
/// by pre-calculating sound IDs and moving logic out of the View's body.
@MainActor
class AudioDebugViewModel: ObservableObject {
    @Published var isPlayingAll = false
    @Published var currentSoundIndex = 0
    @Published var searchText = ""

    private var playbackTimer: Timer?

    let categories: [AudioSoundCategory]
    let allSounds: [SystemSoundID]

    init() {
        // Define all available system sound ranges and specific IDs
        let rawCategories: [AudioSoundCategoryData] = [
            .init(name: "System Alerts", range: 1000...1016),
            .init(name: "UI Feedback", range: 1020...1036),
            .init(name: "Haptics & Taps", range: 1050...1059),
            .init(name: "Keyboard & Type", range: 1070...1075),
            .init(name: "Siri & Dictation", range: 1100...1118),
            .init(name: "Payments & Wallet", range: 1150...1154),
            .init(name: "Mail & Messages", range: 1200...1211),
            .init(name: "Calendar & Reminders", range: 1254...1259),
            .init(name: "Photos & Camera", range: 1300...1315),
            .init(name: "Lock & Keyboard", range: 1320...1336),
            .init(name: "Modern UI", range: 1350...1351),
            .init(name: "System Sounds (1352-1400)", range: 1352...1400),
            .init(name: "System Sounds (1401-1500)", range: 1401...1500),
            .init(name: "System Sounds (1501-1600)", range: 1501...1600),
            .init(name: "System Sounds (1601-1700)", range: 1601...1700),
            .init(name: "System Sounds (1701-1800)", range: 1701...1800),
            .init(name: "System Sounds (1801-1900)", range: 1801...1900),
            .init(name: "System Sounds (1901-2000)", range: 1901...2000),
            .init(name: "Vibration & Special", ids: [4095, 1352]) // 4095 is Vibrate
        ]

        // Pre-calculate all arrays to avoid expensive operations during view rendering
        self.categories = rawCategories.map { data in
            AudioSoundCategory(name: data.name, allIDs: data.resolve())
        }
        self.allSounds = self.categories.flatMap { $0.allIDs }
    }

    var filteredCategories: [AudioSoundCategory] {
        if searchText.isEmpty {
            return categories
        } else {
            return categories.compactMap { category in
                let filteredIDs = category.allIDs.filter { String($0).contains(searchText) }
                return filteredIDs.isEmpty ? nil : AudioSoundCategory(name: category.name, allIDs: filteredIDs)
            }
        }
    }

    func playAll() {
        isPlayingAll = true
        currentSoundIndex = 0
        playNextSound()
    }

    func stopPlayAll() {
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

        playbackTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { [weak self] _ in
            Task { @MainActor in
                guard let self = self else { return }
                if self.isPlayingAll {
                    self.currentSoundIndex += 1
                    self.playNextSound()
                }
            }
        }
    }
}

/// Internal helper for raw sound category data
struct AudioSoundCategoryData {
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

    func resolve() -> [SystemSoundID] {
        if let range = range {
            return Array(range)
        } else if let ids = ids {
            return ids
        }
        return []
    }
}

/// Final processed sound category used by the view
struct AudioSoundCategory: Identifiable {
    var id: String { name }
    let name: String
    let allIDs: [SystemSoundID]
}

struct AudioDebugView: View {
    @StateObject private var viewModel = AudioDebugViewModel()

    var body: some View {
        List {
            Section {
                VStack(spacing: 12) {
                    Button(action: viewModel.isPlayingAll ? viewModel.stopPlayAll : viewModel.playAll) {
                        HStack {
                            Image(systemName: viewModel.isPlayingAll ? "stop.fill" : "play.fill")
                            Text(viewModel.isPlayingAll ? "Stop Sequence" : "Play All Sequence")
                        }
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(viewModel.isPlayingAll ? Color.red.opacity(0.1) : Color.blue.opacity(0.1))
                        .cornerRadius(10)
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(viewModel.isPlayingAll ? .red : .blue)

                    if viewModel.isPlayingAll {
                        ProgressView(value: Double(viewModel.currentSoundIndex), total: Double(viewModel.allSounds.count))
                            .tint(.blue)
                        Text("Playing: \(viewModel.allSounds[viewModel.currentSoundIndex]) (\(viewModel.currentSoundIndex + 1)/\(viewModel.allSounds.count))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 8)
            } header: {
                Text("Controls")
            }

            ForEach(viewModel.filteredCategories, id: \.id) { category in
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
        .searchable(text: $viewModel.searchText, prompt: "Search Sound ID")
        .navigationTitle("Audio Debugger")
        .navigationBarTitleDisplayMode(.large)
        .onDisappear {
            viewModel.stopPlayAll()
        }
    }
}
