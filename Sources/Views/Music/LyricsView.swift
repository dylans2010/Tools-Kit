import SwiftUI

struct LyricsView: View {
    @StateObject private var engine = LyricsSyncEngine.shared
    @StateObject private var player = MusicPlayerManager.shared
    @State private var showLRCImporter = false
    @State private var showLRCExporter = false
    @State private var showOffsetEditor = false
    @State private var showEditor = false
    @State private var offsetText = ""

    var body: some View {
        ZStack {
            if engine.isLoading {
                loadingView
            } else if engine.lines.isEmpty {
                emptyView
            } else {
                lyricsScroller
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(alignment: .topTrailing) {
            lyricsMenu
                .padding(.trailing, 16)
                .padding(.top, 4)
        }
        .sheet(isPresented: $showLRCImporter) {
            if let song = player.currentSong {
                LyricsImportView(song: song) { lines in
                    engine.setLines(lines)
                }
            }
        }
        .sheet(isPresented: $showLRCExporter) {
            if let song = player.currentSong {
                LyricsExportView(song: song, lines: engine.lines)
            }
        }
        .sheet(isPresented: $showOffsetEditor) { offsetEditorSheet }
        .sheet(isPresented: $showEditor) {
            if let song = player.currentSong {
                LyricsEditorView(song: song)
            }
        }
    }

    // MARK: - Lyrics Scroller

    private var lyricsScroller: some View {
        ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 0) {
                    Color.clear.frame(height: 60)
                    ForEach(Array(engine.lines.enumerated()), id: \.element.id) { index, line in
                        lyricLineView(line: line, index: index)
                            .id(index)
                    }
                    Color.clear.frame(height: 120)
                }
            }
            .onChange(of: engine.currentIndex) { _, newIdx in
                guard newIdx >= 0 else { return }
                withAnimation(.easeInOut(duration: 0.4)) {
                    proxy.scrollTo(newIdx, anchor: .center)
                }
            }
        }
    }

    @ViewBuilder
    private func lyricLineView(line: LyricLine, index: Int) -> some View {
        let isCurrent = index == engine.currentIndex
        let isPast    = index < engine.currentIndex

        Text(line.text)
            .font(.system(size: isCurrent ? 24 : 18,
                          weight: isCurrent ? .bold : .semibold,
                          design: .default))
            .foregroundColor(
                isCurrent ? .white :
                isPast    ? .white.opacity(0.3) :
                            .white.opacity(0.5)
            )
            .multilineTextAlignment(.center)
            .padding(.horizontal, 32)
            .padding(.vertical, isCurrent ? 14 : 10)
            .scaleEffect(isCurrent ? 1.0 : 0.95)
            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: engine.currentIndex)
            .contentShape(Rectangle())
            .onTapGesture {
                player.seek(to: line.timestamp)
            }
    }

    // MARK: - Loading / Empty

    private var loadingView: some View {
        VStack(spacing: 14) {
            ProgressView()
                .tint(.white.opacity(0.6))
            Text("Finding lyrics…")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyView: some View {
        VStack(spacing: 16) {
            Image(systemName: "music.note.list")
                .font(.system(size: 48))
                .foregroundColor(.white.opacity(0.35))
            Text("No Lyrics")
                .font(.title2.bold())
                .foregroundColor(.white.opacity(0.6))
            Text("Import a .lrc file or lyrics will be\nautomatically fetched when available.")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.4))
                .multilineTextAlignment(.center)
            HStack(spacing: 12) {
                Button {
                    showLRCImporter = true
                } label: {
                    Label("Import", systemImage: "square.and.arrow.down")
                        .font(.subheadline.weight(.semibold))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.white.opacity(0.15))
                        .foregroundColor(.white)
                        .cornerRadius(20)
                }
                Button {
                    showEditor = true
                } label: {
                    Label("Create", systemImage: "pencil")
                        .font(.subheadline.weight(.semibold))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.white.opacity(0.15))
                        .foregroundColor(.white)
                        .cornerRadius(20)
                }
            }
            .padding(.top, 8)
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Menu

    private var lyricsMenu: some View {
        Menu {
            Button {
                showLRCImporter = true
            } label: {
                Label("Import .lrc File", systemImage: "square.and.arrow.down")
            }

            Button {
                showEditor = true
            } label: {
                Label("Edit Lyrics", systemImage: "pencil")
            }

            if !engine.lines.isEmpty {
                Button {
                    showLRCExporter = true
                } label: {
                    Label("Export .lrc File", systemImage: "square.and.arrow.up")
                }
                Button {
                    showOffsetEditor = true
                } label: {
                    Label("Adjust Sync Offset", systemImage: "slider.horizontal.3")
                }
                Button {
                    Task {
                        if let song = player.currentSong {
                            await engine.loadLyrics(for: song)
                        }
                    }
                } label: {
                    Label("Reload Lyrics", systemImage: "arrow.clockwise")
                }
            }
        } label: {
            Image(systemName: "ellipsis.circle")
                .font(.system(size: 18))
                .foregroundColor(.white.opacity(0.7))
                .padding(8)
                .background(Color.white.opacity(0.1), in: Circle())
        }
    }

    // MARK: - Offset Editor Sheet

    private var offsetEditorSheet: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Text("Offset (seconds)")
                        Spacer()
                        TextField("0.0", text: $offsetText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                    }
                } header: {
                    Text("Sync Adjustment")
                }
                Section {
                    Text("Positive values delay lyrics; negative values advance them.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Lyrics Sync")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { showOffsetEditor = false }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Apply") {
                        if let offset = TimeInterval(offsetText),
                           let song = player.currentSong {
                            engine.saveOffset(offset, for: song)
                        }
                        showOffsetEditor = false
                    }
                }
            }
            .onAppear {
                offsetText = String(format: "%.2f", engine.offsetSeconds)
            }
        }
        .presentationDetents([.medium])
    }
}
