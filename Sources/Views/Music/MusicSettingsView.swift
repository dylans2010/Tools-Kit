import SwiftUI

struct MusicSettingsView: View {
    @StateObject private var modeManager = MusicModeManager.shared
    @StateObject private var player = MusicPlayerManager.shared
    @Environment(\.dismiss) private var dismiss

    @AppStorage("music.autoFetchLyrics") private var autoFetchLyrics = true
    @AppStorage("music.crossfade") private var crossfadeEnabled = false
    @AppStorage("music.gapless") private var gaplessEnabled = true

    @State private var showSleepTimer = false
    @State private var sleepMinutes: Double = 30
    @State private var showClearLibraryAlert = false
    @State private var showSpotifySheet = false

    var body: some View {
        NavigationStack {
            Form {
                // MARK: Mode
                Section {
                    Toggle("Music Mode", isOn: $modeManager.isMusicModeEnabled)
                } header: {
                    Text("App Mode")
                } footer: {
                    Text("Replaces the Tools dashboard with a full music player. Playback is not interrupted when switching modes.")
                }

                // MARK: Playback
                Section {
                    Toggle("Gapless Playback", isOn: $gaplessEnabled)
                    Toggle("Crossfade Tracks", isOn: $crossfadeEnabled)
                        .disabled(true) // placeholder
                    HStack {
                        Label("Shuffle", systemImage: "shuffle")
                        Spacer()
                        Toggle("", isOn: Binding(
                            get: { player.shuffleEnabled },
                            set: { _ in player.toggleShuffle() }
                        ))
                    }
                    HStack {
                        Label("Repeat", systemImage: "repeat")
                        Spacer()
                        Picker("", selection: Binding(
                            get: { player.repeatMode },
                            set: { player.setRepeatMode($0) }
                        )) {
                            Text("Off").tag(RepeatMode.off)
                            Text("One").tag(RepeatMode.one)
                            Text("All").tag(RepeatMode.all)
                        }
                        .pickerStyle(.menu)
                    }
                } header: {
                    Text("Playback")
                }

                // MARK: Sleep Timer
                Section {
                    if let end = player.sleepTimerEndDate {
                        HStack {
                            Label("Active", systemImage: "timer")
                                .foregroundColor(.accentColor)
                            Spacer()
                            Text(end, style: .timer)
                                .foregroundColor(.secondary)
                                .monospacedDigit()
                        }
                        Button("Cancel Sleep Timer", role: .destructive) {
                            player.setSleepTimer(minutes: 0)
                        }
                    } else {
                        Button {
                            showSleepTimer = true
                        } label: {
                            Label("Set Sleep Timer", systemImage: "timer")
                        }
                    }
                }  header: {
                    Text("Sleep Timer")
                }

                // MARK: Lyrics
                Section {
                    Toggle("Auto-Fetch Lyrics", isOn: $autoFetchLyrics)
                    NavigationLink {
                        LyricsSettingsDetail()
                    } label: {
                        Label("Lyrics Options", systemImage: "text.quote")
                    }
                } header: {
                    Text("Lyrics")
                } footer: {
                    Text("Lyrics are fetched from LRCLIB (open-source database, no API key required). You can also import .lrc files per track.")
                }

                // MARK: Spotify
                Section {
                    Button {
                        showSpotifySheet = true
                    } label: {
                        Label("Open Spotify Link", systemImage: "music.note.list")
                    }
                } header: {
                    Text("Spotify")
                } footer: {
                    Text("Paste a Spotify track, playlist, album, or artist URL to open it in the Spotify app.")
                }

                // MARK: Library
                Section {
                    Button(role: .destructive) {
                        showClearLibraryAlert = true
                    } label: {
                        Label("Clear Music Library", systemImage: "trash")
                    }
                } header: {
                    Text("Library")
                }
            }
            .navigationTitle("Music Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .alert("Clear Library?", isPresented: $showClearLibraryAlert) {
                Button("Clear All", role: .destructive) {
                    MusicLibraryManager.shared.clearLibrary()
                    player.pause()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will remove all songs from your library. Audio files stored in the app will be deleted. This cannot be undone.")
            }
            .sheet(isPresented: $showSleepTimer) { sleepTimerSheet }
            .sheet(isPresented: $showSpotifySheet) { SpotifyLinkSheet() }
        }
    }

    // MARK: - Sleep Timer Sheet

    private var sleepTimerSheet: some View {
        NavigationStack {
            Form {
                Section {
                    Stepper("Stop in \(Int(sleepMinutes)) min",
                            value: $sleepMinutes, in: 5...180, step: 5)
                } header: {
                    Text("Stop playback after")
                }
                Section {
                    Button("Start Timer") {
                        player.setSleepTimer(minutes: Int(sleepMinutes))
                        showSleepTimer = false
                    }
                }
            }
            .navigationTitle("Sleep Timer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") { showSleepTimer = false }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Lyrics Settings Detail

private struct LyricsSettingsDetail: View {
    @AppStorage("music.autoFetchLyrics") private var autoFetch = true
    @StateObject private var engine = LyricsSyncEngine.shared

    var body: some View {
        Form {
            Section {
                Toggle("Auto-Fetch from LRCLIB", isOn: $autoFetch)
                HStack {
                    Text("Global Offset (s)")
                    Spacer()
                    Text(String(format: "%.1f", engine.offsetSeconds))
                        .foregroundColor(.secondary)
                }
            } header: {
                Text("Sync")
            } footer: {
                Text("A positive offset delays lyrics display; a negative offset advances it. Adjust per-track in the Now Playing lyrics view.")
            }
            Section {
                Link("lrclib.net", destination: URL(string: "https://lrclib.net")!)
            } header: {
                Text("About LRCLIB")
            }
        }
        .navigationTitle("Lyrics Options")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Spotify Link Sheet

struct SpotifyLinkSheet: View {
    @StateObject private var service = SpotifyLinkService()
    @Environment(\.dismiss) private var dismiss
    @State private var urlText = ""
    @State private var item: SpotifyLinkService.SpotifyItem?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("https://open.spotify.com/track/…", text: $urlText)
                        .keyboardType(.URL)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                    Button("Parse") {
                        item = service.parse(urlString: urlText)
                    }
                    .disabled(urlText.isEmpty)
                } header: {
                    Text("Spotify URL")
                }

                if let errorMsg = service.errorMessage {
                    Section {
                        Label(errorMsg, systemImage: "xmark.circle")
                            .foregroundColor(.red)
                    }
                }

                if let item = item {
                    Section {
                        HStack {
                            Image(systemName: itemIcon(for: item.type))
                                .foregroundColor(.green)
                            VStack(alignment: .leading) {
                                Text(item.displayTitle)
                                    .font(.subheadline.weight(.semibold))
                                Text(item.id)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                        Button {
                            service.openInSpotify(item)
                        } label: {
                            Label(service.isSpotifyInstalled ? "Open in Spotify" : "Open spotify.com",
                                  systemImage: "music.note")
                        }
                    } header: {
                        Text("Found")
                    }
                }
            }
            .navigationTitle("Spotify")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func itemIcon(for type: SpotifyLinkService.SpotifyItemType) -> String {
        switch type {
        case .track:    return "music.note"
        case .playlist: return "music.note.list"
        case .album:    return "square.stack"
        case .artist:   return "person"
        }
    }
}
