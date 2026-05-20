import SwiftUI

struct DictionaryView: View {
    @Binding var isPresented: Bool
    var onInsert: ((String) -> Void)? = nil
    @StateObject private var vm = DictionaryViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                searchBar

                if vm.isLoading {
                    ProgressView().padding(.top, 40)
                    Spacer()
                } else if let error = vm.errorMessage {
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle").font(.largeTitle).foregroundColor(.secondary)
                        Text(error).foregroundColor(.secondary)
                    }
                    .padding(.top, 40)
                    Spacer()
                } else if let result = vm.result {
                    resultView(result)
                } else if !vm.recentSearches.isEmpty {
                    recentSearchesView
                } else {
                    emptyStateView
                }
            }
            .navigationTitle("Dictionary")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") { isPresented = false }
                }
            }
        }
    }

    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass").foregroundColor(.secondary)
            TextField("Search Words", text: $vm.searchText)
                .textFieldStyle(.plain)
                .onSubmit {
                    Task { await vm.search(word: vm.searchText) }
                }
            if !vm.searchText.isEmpty {
                Button { vm.searchText = "" } label: { Image(systemName: "xmark.circle.fill").foregroundColor(.secondary) }
            }
        }
        .padding(10)
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(10)
        .padding()
    }

    private var recentSearchesView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Searches").font(.headline).padding(.horizontal)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(vm.recentSearches, id: \.self) { word in
                        Button {
                            Task { await vm.search(word: word) }
                        } label: {
                            Text(word)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(15)
                        }
                    }
                }
                .padding(.horizontal)
            }
            Spacer()
        }
    }

    private var emptyStateView: some View {
        ContentUnavailableView {
            Label("Dictionary", systemImage: "book.closed")
        } description: {
            Text("Search for any word to see definitions, synonyms, and audio pronunciations.")
        } actions: {
            VStack(spacing: 12) {
                Text("Try searching for:").font(.caption).foregroundStyle(.secondary)
                HStack {
                    suggestionChip("Luminous")
                    suggestionChip("Eloquent")
                    suggestionChip("Resilient")
                }
            }
        }
    }

    private func suggestionChip(_ word: String) -> some View {
        Button(word) {
            vm.searchText = word
            Task { await vm.search(word: word) }
        }
        .buttonStyle(.bordered)
        .buttonBorderShape(.capsule)
    }

    private func resultView(_ result: DictionaryResult) -> some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Label("Word of the Day", systemImage: "star.fill")
                            .font(.caption.bold())
                            .foregroundStyle(.orange)
                        Spacer()
                        Text(Date().formatted(date: .abbreviated, time: .omitted))
                            .font(.system(size: 8))
                            .foregroundStyle(.secondary)
                    }
                    Text("Ephemeral")
                        .font(.headline)
                    Text("Lasting for a very short time.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(12)
                .background(Color.orange.opacity(0.05), in: RoundedRectangle(cornerRadius: 12))
            } header: {
                Label("Daily Insight", systemImage: "sparkles")
            }
            .listRowBackground(Color.clear)

            Section {
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(result.word)
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                        if let phonetic = result.phonetic {
                            Text(phonetic)
                                .font(.title3)
                                .foregroundColor(.secondary)
                        }
                    }
                    Spacer()
                    Button {
                        vm.playAudio()
                    } label: {
                        Image(systemName: "speaker.wave.2.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                            .frame(width: 50, height: 50)
                            .background(Circle().fill(Color.blue))
                            .shadow(color: .blue.opacity(0.3), radius: 5, x: 0, y: 3)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.vertical, 8)
            }
            .listRowBackground(Color.clear)

            ForEach(result.meanings) { meaning in
                Section(header: Text(meaning.partOfSpeech.uppercased()).font(.caption.bold()).foregroundColor(partOfSpeechColor(meaning.partOfSpeech))) {
                    ForEach(Array(meaning.definitions.enumerated()), id: \.offset) { index, def in
                        VStack(alignment: .leading, spacing: 10) {
                            HStack(alignment: .top, spacing: 12) {
                                Text("\(index + 1)")
                                    .font(.subheadline.bold())
                                    .foregroundColor(.white)
                                    .frame(width: 24, height: 24)
                                    .background(Circle().fill(partOfSpeechColor(meaning.partOfSpeech)))

                                Text(def.definition)
                                    .font(.body)
                                    .fixedSize(horizontal: false, vertical: true)
                            }

                            if let example = def.example {
                                Text("\"\(example)\"")
                                    .font(.subheadline.italic())
                                    .foregroundColor(.secondary)
                                    .padding(.leading, 36)
                            }

                            if !def.synonyms.isEmpty {
                                wordChipGroup(title: "Synonyms", words: def.synonyms, color: .blue)
                                    .padding(.leading, 36)
                            }

                            if !def.antonyms.isEmpty {
                                wordChipGroup(title: "Antonyms", words: def.antonyms, color: .orange)
                                    .padding(.leading, 36)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }

            Section("Actions") {
                Button {
                    if let firstDef = result.meanings.first?.definitions.first?.definition,
                       let pos = result.meanings.first?.partOfSpeech {
                        onInsert?("**\(result.word)** *(\(pos))* : \(firstDef)")
                        isPresented = false
                    }
                } label: {
                    Label("Insert to Page", systemImage: "plus.circle.fill")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color.blue))
                }
                .buttonStyle(.plain)
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            }

            Section("Etymology") {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Origins", systemImage: "clock.arrow.circlepath")
                        .font(.caption.bold())
                    Text("Mid 16th century: from French, or from Latin, based on Greek words. Traced back to late Middle English roots.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }

            if !result.sourceUrls.isEmpty {
                Section("Sources") {
                    ForEach(result.sourceUrls, id: \.self) { url in
                        Link(destination: URL(string: url)!) {
                            HStack {
                                Text(url)
                                    .font(.caption)
                                    .lineLimit(1)
                                Spacer()
                                Image(systemName: "arrow.up.right.square")
                                    .font(.caption)
                            }
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    private func wordChipGroup(title: String, words: [String], color: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.caption.bold()).foregroundColor(.secondary)
            FlowLayout(words, spacing: 8) { word in
                Button {
                    Task { await vm.search(word: word) }
                } label: {
                    Text(word)
                        .font(.system(size: 11, weight: .medium))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(color.opacity(0.1))
                        .foregroundColor(color)
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func partOfSpeechColor(_ pos: String) -> Color {
        switch pos.lowercased() {
        case "noun": return .blue
        case "verb": return .green
        case "adjective": return .orange
        case "adverb": return .purple
        default: return .secondary
        }
    }
}

